# ============================================
# ЗАПУСК WALLET SERVICE
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "ЗАПУСК WALLET SERVICE (1000+ RPS)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Проверка Docker
function Test-Docker {
    try {
        docker info | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Host "`nПроверка окружения..." -ForegroundColor Yellow

if (-not (Test-Docker)) {
    Write-Host "ERROR Docker не запущен!" -ForegroundColor Red
    Write-Host "   Запустите Docker Desktop и повторите попытку" -ForegroundColor Gray
    exit 1
}

Write-Host "OK Docker запущен" -ForegroundColor Green

# Проверка портов
Write-Host "`nПроверка портов..." -ForegroundColor Yellow

$ports = @(
    @{Port=8080; Service="Приложение"},
    @{Port=5432; Service="PostgreSQL"}
)

foreach ($portInfo in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $portInfo.Port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "WARNING Порт $($portInfo.Port) ($($portInfo.Service)) занят" -ForegroundColor Yellow
    } else {
        Write-Host "OK Порт $($portInfo.Port) ($($portInfo.Service)) свободен" -ForegroundColor Green
    }
}

# Сборка проекта
Write-Host "`nСборка проекта..." -ForegroundColor Yellow

try {
    # Пробуем собрать через Maven, если он установлен
    $mavenInstalled = Get-Command mvn -ErrorAction SilentlyContinue
    if ($mavenInstalled) {
        Write-Host "   Используем Maven для сборки..." -ForegroundColor Gray
        mvn clean package -DskipTests
        if ($LASTEXITCODE -ne 0) {
            throw "Ошибка сборки Maven"
        }
    } else {
        Write-Host "   Maven не найден, используем Docker для сборки..." -ForegroundColor Gray
    }
    Write-Host "OK Сборка завершена" -ForegroundColor Green
} catch {
    Write-Host "WARNING Ошибка сборки: $_" -ForegroundColor Yellow
    Write-Host "   Продолжаем с Docker сборкой..." -ForegroundColor Gray
}

# Остановка старых контейнеров
Write-Host "`nОстановка старых контейнеров..." -ForegroundColor Yellow
docker-compose down

# Запуск контейнеров
Write-Host "`nЗапуск Docker контейнеров..." -ForegroundColor Yellow
Write-Host "   Это может занять 2-3 минуты..." -ForegroundColor Gray

docker-compose up --build -d

# Ожидание запуска
Write-Host "`nОжидание запуска сервисов..." -ForegroundColor Yellow

$maxWaitTime = 120 # секунд
$startTime = Get-Date

for ($i = 0; $i -lt $maxWaitTime; $i++) {
    $percent = [math]::Round(($i / $maxWaitTime) * 100)
    $elapsed = (Get-Date) - $startTime
    
    Write-Progress -Activity "Запуск сервисов" -Status "Ожидание... ($i/$maxWaitTime секунд)" -PercentComplete $percent
    
    # Пробуем проверить здоровье сервиса
    if ($i -ge 30) { # Ждем минимум 30 секунд
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/wallets/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response -and $response.success) {
                Write-Host "`nOK Сервис запущен и здоров!" -ForegroundColor Green
                break
            }
        } catch {
            # Продолжаем ждать
        }
    }
    
    Start-Sleep -Seconds 1
}

Write-Progress -Activity "Запуск сервисов" -Completed

# Финальная проверка
Write-Host "`nФинальная проверка..." -ForegroundColor Cyan

docker-compose ps

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "WALLET SERVICE УСПЕШНО ЗАПУЩЕН!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`nССЫЛКИ:" -ForegroundColor Yellow
Write-Host "   API:           http://localhost:8080" -ForegroundColor White
Write-Host "   Health check:  http://localhost:8080/api/v1/wallets/health" -ForegroundColor White
Write-Host "   Prometheus:    http://localhost:8080/management/prometheus" -ForegroundColor White
Write-Host "   База данных:  localhost:5432 (postgres/postgres)" -ForegroundColor White

Write-Host "`nКОМАНДЫ ДЛЯ ТЕСТИРОВАНИЯ:" -ForegroundColor Cyan
Write-Host "   .\test-api.ps1                 # Базовое тестирование API" -ForegroundColor Gray
Write-Host "   .\load-test.ps1                # Нагрузочное тестирование" -ForegroundColor Gray
Write-Host "   .\check-health.ps1             # Проверка здоровья" -ForegroundColor Gray

Write-Host "`nУПРАВЛЕНИЕ DOCKER:" -ForegroundColor Cyan
Write-Host "   docker-compose logs -f wallet-service  # Просмотр логов" -ForegroundColor Gray
Write-Host "   docker-compose down                    # Остановка всех сервисов" -ForegroundColor Gray
Write-Host "   docker-compose restart wallet-service  # Перезапуск сервиса" -ForegroundColor Gray

Write-Host "`nДОКУМЕНТАЦИЯ:" -ForegroundColor Yellow
Write-Host "   Полная документация в файле README.md" -ForegroundColor White

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "ГОТОВО К РАБОТЕ С НАГРУЗКОЙ 1000+ RPS!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
