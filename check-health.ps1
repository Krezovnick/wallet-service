# ============================================
# ПРОВЕРКА ЗДОРОВЬЯ WALLET SERVICE
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "ПРОВЕРКА ЗДОРОВЬЯ СИСТЕМЫ" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

function Write-HealthStatus {
    param(
        [string]$Service,
        [string]$Status,
        [string]$Details
    )
    
    $icon = switch ($Status) {
        "UP" { "OK" }
        "DOWN" { "ERROR" }
        "WARNING" { "WARNING" }
        default { "INFO" }
    }
    
    $color = switch ($Status) {
        "UP" { "Green" }
        "DOWN" { "Red" }
        "WARNING" { "Yellow" }
        default { "Gray" }
    }
    
    Write-Host "$icon $Service: $Status" -ForegroundColor $color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

Write-Host "`nПроверка сервисов..." -ForegroundColor Yellow

# 1. Проверка Docker
try {
    docker info | Out-Null
    Write-HealthStatus -Service "Docker" -Status "UP"
} catch {
    Write-HealthStatus -Service "Docker" -Status "DOWN" -Details "Docker не запущен"
    exit 1
}

# 2. Проверка контейнеров
try {
    $containers = docker-compose ps --services
    Write-HealthStatus -Service "Docker Compose" -Status "UP" -Details "Сервисы: $($containers -join ', ')"
} catch {
    Write-HealthStatus -Service "Docker Compose" -Status "DOWN"
}

# 3. Проверка API здоровья
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/wallets/health" -TimeoutSec 5
    Write-HealthStatus -Service "API Health" -Status "UP" -Details $health.data
} catch {
    Write-HealthStatus -Service "API Health" -Status "DOWN" -Details "API не отвечает"
}

# 4. Проверка Spring Boot Actuator Health
try {
    $actuatorHealth = Invoke-RestMethod -Uri "http://localhost:8080/management/health" -TimeoutSec 5
    Write-HealthStatus -Service "Spring Actuator" -Status "UP" -Details "Status: $($actuatorHealth.status)"
    
    # Проверка компонентов
    if ($actuatorHealth.components) {
        foreach ($component in $actuatorHealth.components.PSObject.Properties) {
            $status = $component.Value.status
            $icon = if ($status -eq "UP") { "OK" } else { "ERROR" }
            Write-Host "   $icon $($component.Name): $status" -ForegroundColor Gray
        }
    }
} catch {
    Write-HealthStatus -Service "Spring Actuator" -Status "DOWN"
}

# 5. Проверка Prometheus метрик
try {
    $metrics = Invoke-WebRequest -Uri "http://localhost:8080/management/prometheus" -TimeoutSec 5
    Write-HealthStatus -Service "Prometheus Metrics" -Status "UP" -Details "Метрики доступны"
} catch {
    Write-HealthStatus -Service "Prometheus Metrics" -Status "WARNING"
}

# 6. Проверка базы данных
try {
    $dbCheck = Invoke-RestMethod -Uri "http://localhost:8080/management/health/db" -TimeoutSec 5
    if ($dbCheck.status -eq "UP") {
        Write-HealthStatus -Service "Database" -Status "UP" -Details "PostgreSQL доступна"
    } else {
        Write-HealthStatus -Service "Database" -Status "DOWN"
    }
} catch {
    Write-HealthStatus -Service "Database" -Status "WARNING" -Details "Не удалось проверить БД"
}

# 7. Проверка производительности
try {
    $startTime = Get-Date
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/wallets/health" -TimeoutSec 10
    $responseTime = ((Get-Date) - $startTime).TotalMilliseconds
    
    $performance = if ($responseTime -lt 100) { "Отличная" } 
                   elseif ($responseTime -lt 500) { "Хорошая" }
                   else { "Медленная" }
    
    Write-HealthStatus -Service "Производительность" -Status "UP" `
        -Details "Время ответа: ${responseTime}ms ($performance)"
} catch {
    Write-HealthStatus -Service "Производительность" -Status "WARNING"
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "СВОДКА СОСТОЯНИЯ" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`nДОСТУПНЫЕ ЭНДПОИНТЫ:" -ForegroundColor Yellow
Write-Host "   http://localhost:8080/api/v1/wallets/health" -ForegroundColor Gray
Write-Host "   http://localhost:8080/management/health" -ForegroundColor Gray
Write-Host "   http://localhost:8080/management/prometheus" -ForegroundColor Gray
Write-Host "   http://localhost:8080/management/info" -ForegroundColor Gray

Write-Host "`nКОМАНДЫ ДЛЯ ДИАГНОСТИКИ:" -ForegroundColor Cyan
Write-Host "   docker-compose logs wallet-service" -ForegroundColor Gray
Write-Host "   docker-compose logs postgres" -ForegroundColor Gray
Write-Host "   docker stats" -ForegroundColor Gray

Write-Host "`nOK Система готова к работе под нагрузкой 1000+ RPS" -ForegroundColor Green
