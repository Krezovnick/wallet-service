# ============================================
# НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ WALLET SERVICE
# ============================================

param(
    [int]$Threads = 50,
    [int]$Connections = 200,
    [int]$Duration = 30,
    [string]$WalletId
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ (1000+ RPS)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

if (-not $WalletId) {
    $WalletId = [guid]::NewGuid()
    Write-Host "Создан тестовый кошелек: $WalletId" -ForegroundColor Cyan
    
    # Создаем кошелек
    try {
        Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/v1/wallets/$WalletId/create" -TimeoutSec 10
        Write-Host "OK Кошелек создан" -ForegroundColor Green
    } catch {
        Write-Host "ERROR Ошибка создания кошелька: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nПараметры тестирования:" -ForegroundColor Yellow
Write-Host "   Потоков: $Threads" -ForegroundColor White
Write-Host "   Соединений: $Connections" -ForegroundColor White
Write-Host "   Длительность: ${Duration}с" -ForegroundColor White
Write-Host "   Кошелек: $WalletId" -ForegroundColor White

Write-Host "`nЗапуск нагрузочного тестирования..." -ForegroundColor Cyan
Write-Host "   Это займет примерно ${Duration} секунд..." -ForegroundColor Gray

# Функция для выполнения депозита
function Invoke-Deposit {
    param([string]$WalletId, [decimal]$Amount)
    
    $body = @{
        walletId = $WalletId
        operationType = "DEPOSIT"
        amount = $Amount
        reference = "Load test deposit"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/v1/wallets" `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

# Запускаем нагрузку
$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)
$successCount = 0
$errorCount = 0
$totalOperations = 0

# Создаем пул задач
$jobs = @()
for ($i = 0; $i -lt $Threads; $i++) {
    $job = Start-Job -ScriptBlock {
        param($WalletId, $EndTime)
        
        $localSuccess = 0
        $localErrors = 0
        $rng = New-Object System.Random
        
        while ((Get-Date) -lt $EndTime) {
            $amount = [math]::Round($rng.NextDouble() * 100, 2)
            $success = Invoke-Deposit -WalletId $WalletId -Amount $amount
            
            if ($success) {
                $localSuccess++
            } else {
                $localErrors++
            }
            
            Start-Sleep -Milliseconds 10
        }
        
        return @{ Success = $localSuccess; Errors = $localErrors }
    } -ArgumentList $WalletId, $endTime
    
    $jobs += $job
}

# Мониторинг прогресса
Write-Host "`nВыполняется нагрузочное тестирование..." -ForegroundColor Yellow

while ((Get-Date) -lt $endTime) {
    $elapsed = (Get-Date) - $startTime
    $percent = [math]::Min(100, [math]::Round(($elapsed.TotalSeconds / $Duration) * 100))
    
    Write-Progress -Activity "Нагрузочное тестирование" -Status "Выполняется... ($([math]::Round($elapsed.TotalSeconds))с / ${Duration}с)" -PercentComplete $percent
    
    Start-Sleep -Seconds 1
}

Write-Progress -Activity "Нагрузочное тестирование" -Completed

# Сбор результатов
Write-Host "`nСбор результатов..." -ForegroundColor Cyan

foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -Wait -AutoRemoveJob
    $successCount += $result.Success
    $errorCount += $result.Errors
}

$totalOperations = $successCount + $errorCount
$rps = [math]::Round($totalOperations / $Duration, 2)
$successRate = [math]::Round(($successCount / $totalOperations) * 100, 2)

# Получаем финальный баланс
try {
    $balanceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/wallets/$WalletId" -TimeoutSec 10
    $finalBalance = $balanceResponse.data.balance
} catch {
    $finalBalance = "N/A"
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "РЕЗУЛЬТАТЫ НАГРУЗОЧНОГО ТЕСТИРОВАНИЯ" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`nСТАТИСТИКА:" -ForegroundColor Yellow
Write-Host "   Всего операций: $totalOperations" -ForegroundColor White
Write-Host "   Успешных: $successCount" -ForegroundColor Green
Write-Host "   Ошибок: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) {"Red"} else {"Gray"})
Write-Host "   RPS: $rps" -ForegroundColor White
Write-Host "   Успешность: ${successRate}%" -ForegroundColor $(if ($successRate -ge 99) {"Green"} else {"Yellow"})
Write-Host "   Финальный баланс: $finalBalance" -ForegroundColor White

Write-Host "`nЦЕЛЕВЫЕ ПОКАЗАТЕЛИ:" -ForegroundColor Cyan
Write-Host "   OK 1000+ RPS на один кошелек" -ForegroundColor $(if ($rps -ge 1000) {"Green"} else {"Yellow"})
Write-Host "   OK 0 50X ошибок" -ForegroundColor $(if ($errorCount -eq 0) {"Green"} else {"Red"})
Write-Host "   OK Все запросы обработаны" -ForegroundColor $(if ($successRate -ge 99.9) {"Green"} else {"Yellow"})

Write-Host "`nРЕКОМЕНДАЦИИ:" -ForegroundColor Cyan
if ($rps -lt 1000) {
    Write-Host "   WARNING Увеличьте количество потоков" -ForegroundColor Yellow
    Write-Host "   Попробуйте: .\load-test.ps1 -Threads 100 -Connections 500" -ForegroundColor Gray
}

if ($errorCount -gt 0) {
    Write-Host "   WARNING Есть ошибки при обработке" -ForegroundColor Yellow
    Write-Host "   Проверьте логи: docker-compose logs wallet-service" -ForegroundColor Gray
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
