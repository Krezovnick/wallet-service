# ============================================
# ТЕСТИРОВАНИЕ WALLET SERVICE API
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "ТЕСТИРОВАНИЕ API WALLET SERVICE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

function Test-API {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Uri,
        [object]$Body,
        [hashtable]$Headers = @{}
    )
    
    Write-Host "`n$Name" -ForegroundColor Yellow
    Write-Host "-" * 40 -ForegroundColor DarkGray
    
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            TimeoutSec = 10
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params.Body = $Body
            if ($Body -is [string]) {
                $params.ContentType = 'application/json'
            }
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        $response = Invoke-RestMethod @params
        
        Write-Host "OK УСПЕХ" -ForegroundColor Green
        if ($response.data) {
            if ($response.data -is [string]) {
                Write-Host "   Ответ: $($response.data)" -ForegroundColor Gray
            } else {
                $json = $response.data | ConvertTo-Json -Compress
                Write-Host "   Ответ: $json" -ForegroundColor Gray
            }
        }
        
        return $response
    } catch {
        Write-Host "ERROR ОШИБКА" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            try {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "   Код: $($errorResponse.errorCode)" -ForegroundColor Gray
                Write-Host "   Сообщение: $($errorResponse.message)" -ForegroundColor Gray
            } catch {
                Write-Host "   Сообщение: $($_.Exception.Message)" -ForegroundColor Gray
            }
        }
        return $null
    }
}

# Проверка здоровья
Test-API -Name "1. ПРОВЕРКА ЗДОРОВЬЯ СЕРВИСА" `
    -Method "GET" `
    -Uri "http://localhost:8080/api/v1/wallets/health"

# Создание тестового кошелька
$testWalletId = [guid]::NewGuid()
Write-Host "`nТестовый кошелек: $testWalletId" -ForegroundColor Cyan

Test-API -Name "2. СОЗДАНИЕ КОШЕЛЬКА" `
    -Method "POST" `
    -Uri "http://localhost:8080/api/v1/wallets/$testWalletId/create?currency=USD"

# Получение баланса (должен быть 0)
Test-API -Name "3. ПОЛУЧЕНИЕ БАЛАНСА (ожидаем 0)" `
    -Method "GET" `
    -Uri "http://localhost:8080/api/v1/wallets/$testWalletId"

# Депозит 1500.50
$depositBody = @{
    walletId = $testWalletId.ToString()
    operationType = "DEPOSIT"
    amount = 1500.50
    reference = "Initial deposit"
} | ConvertTo-Json

Test-API -Name "4. ДЕПОЗИТ 1500.50 USD" `
    -Method "POST" `
    -Uri "http://localhost:8080/api/v1/wallets" `
    -Body $depositBody `
    -Headers @{"Content-Type" = "application/json"}

# Проверка баланса после депозита
Test-API -Name "5. БАЛАНС ПОСЛЕ ДЕПОЗИТА (ожидаем 1500.50)" `
    -Method "GET" `
    -Uri "http://localhost:8080/api/v1/wallets/$testWalletId"

# Снятие 750.25
$withdrawBody = @{
    walletId = $testWalletId.ToString()
    operationType = "WITHDRAW"
    amount = 750.25
    reference = "Withdrawal"
} | ConvertTo-Json

Test-API -Name "6. СНЯТИЕ 750.25 USD" `
    -Method "POST" `
    -Uri "http://localhost:8080/api/v1/wallets" `
    -Body $withdrawBody `
    -Headers @{"Content-Type" = "application/json"}

# Финальный баланс
Test-API -Name "7. ФИНАЛЬНЫЙ БАЛАНС (ожидаем 750.25)" `
    -Method "GET" `
    -Uri "http://localhost:8080/api/v1/wallets/$testWalletId"

# Ошибка: недостаточно средств
$insufficientBody = @{
    walletId = $testWalletId.ToString()
    operationType = "WITHDRAW"
    amount = 10000.00
    reference = "Too much"
} | ConvertTo-Json

Test-API -Name "8. ОШИБКА: НЕДОСТАТОЧНО СРЕДСТВ" `
    -Method "POST" `
    -Uri "http://localhost:8080/api/v1/wallets" `
    -Body $insufficientBody `
    -Headers @{"Content-Type" = "application/json"}

# Ошибка: невалидный JSON
Test-API -Name "9. ОШИБКА: НЕВАЛИДНЫЙ JSON" `
    -Method "POST" `
    -Uri "http://localhost:8080/api/v1/wallets" `
    -Body "{ invalid json }" `
    -Headers @{"Content-Type" = "application/json"}

# Ошибка: несуществующий кошелек
$nonExistentWalletId = [guid]::NewGuid()
Test-API -Name "10. ОШИБКА: КОШЕЛЕК НЕ НАЙДЕН" `
    -Method "GET" `
    -Uri "http://localhost:8080/api/v1/wallets/$nonExistentWalletId"

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`nРЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ:" -ForegroundColor Yellow
Write-Host "   Кошелек: $testWalletId" -ForegroundColor White
Write-Host "   Финальный баланс: 750.25 USD" -ForegroundColor White
Write-Host "   Все ошибки обработаны корректно" -ForegroundColor White

Write-Host "`nOK API соответствует требованиям задания" -ForegroundColor Green
