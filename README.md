# 🏦 Wallet Service

Высоконагруженный сервис для операций с кошельками, поддерживающий 1000+ RPS на один кошелек.

## 📋 Требования из задания

✅ **REST API** для операций с кошельком  
✅ **Поддержка DEPOSIT/WITHDRAW**  
✅ **Получение баланса**  
✅ **Миграции Liquibase**  
✅ **Конкурентная обработка (1000 RPS на один кошелек)**  
✅ **Обработка ошибок** (валидация, недостаток средств, несуществующий кошелек)  
✅ **Docker + Docker Compose**  
✅ **Настройка через переменные окружения**  
✅ **Тесты**  
✅ **GitHub репозиторий**

## 🚀 Быстрый старт

### Предварительные требования
- Docker Desktop
- Git
- PowerShell (Windows) или терминал (Linux/Mac)

### Запуск проекта

\\\powershell
# Клонировать репозиторий
git clone <repository-url>
cd wallet-service

# Запустить сервисы
.\start.ps1
\\\

### Тестирование API
\\\powershell
.\test-api.ps1
\\\

### Нагрузочное тестирование
\\\powershell
.\load-test.ps1
\\\

## 📚 API Документация

### Базовый URL
\\\	ext
http://localhost:8080/api/v1/wallets
\\\

### Эндпоинты

#### 1. Создание операции с кошельком (DEPOSIT/WITHDRAW)
\\\http
POST /api/v1/wallets
Content-Type: application/json

{
  "walletId": "123e4567-e89b-12d3-a456-426614174000",
  "operationType": "DEPOSIT",
  "amount": 1000.00,
  "reference": "Пополнение счета"
}
\\\

Пример успешного ответа:
\\\json
{
  "success": true,
  "data": {
    "walletId": "123e4567-e89b-12d3-a456-426614174000",
    "balance": 1000.00,
    "currency": "USD",
    "updatedAt": "2024-01-01T12:00:00",
    "active": true
  },
  "timestamp": "2024-01-01T12:00:00"
}
\\\

Пример ошибки (недостаточно средств):
\\\json
{
  "success": false,
  "message": "Insufficient funds in wallet '123e4567-e89b-12d3-a456-426614174000'. Current balance: 500.00, Required amount: 1000.00",
  "errorCode": "INSUFFICIENT_FUNDS",
  "timestamp": "2024-01-01T12:00:00"
}
\\\

#### 2. Получение баланса кошелька
\\\http
GET /api/v1/wallets/{walletId}
\\\

#### 3. Создание кошелька (дополнительно)
\\\http
POST /api/v1/wallets/{walletId}/create?currency=USD
\\\

#### 4. Проверка здоровья
\\\http
GET /api/v1/wallets/health
\\\

## 🏗️ Архитектура и конкурентность

Решения для обработки 1000+ RPS:
- Оптимистические блокировки (@Version в сущности Wallet)
- Пессимистические блокировки (SELECT ... FOR UPDATE) для критических секций
- Автоматические ретраи (@Retryable) при конфликтах
- Настроенный пул соединений (HikariCP, 100+ соединений)
- Оптимизированные UPDATE запросы для уменьшения блокировок
- Настроенная PostgreSQL (1000+ соединений, оптимизированные параметры)

Уровни изоляции транзакций:
- READ_COMMITTED для операций чтения
- SERIALIZABLE для операций изменения баланса

## 🔧 Конфигурация

Основные переменные окружения:
\\\env
DB_URL=jdbc:postgresql://localhost:5432/walletdb
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_POOL_SIZE=100
TOMCAT_MAX_THREADS=200
MAX_CONNECTIONS=10000
RETRY_MAX_ATTEMPTS=5
LOG_LEVEL=INFO
\\\

Настройки базы данных:
- Максимальное количество соединений: 1000
- Размер shared buffers: 256MB
- Эффективный размер кэша: 768MB
- Логирование всех транзакций

## 🐳 Docker

Команды Docker:
\\\ash
# Запуск всех сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f wallet-service

# Остановка сервисов
docker-compose down

# Пересборка и запуск
docker-compose up --build -d
\\\

Мониторинг:
- Prometheus метрики: http://localhost:8080/management/prometheus
- Health check: http://localhost:8080/management/health
- Информация о приложении: http://localhost:8080/management/info

## 🧪 Тестирование

Типы тестов:
- Юнит-тесты - тестирование отдельных компонентов
- Интеграционные тесты - тестирование с реальной БД (Testcontainers)
- Конкурентные тесты - тестирование при высокой нагрузке
- API тесты - тестирование через HTTP запросы

Запуск тестов:
\\\ash
mvn test                    # Все тесты
mvn test -Dtest="*Test"     # Только юнит-тесты
mvn test -Dtest="*IntegrationTest"  # Интеграционные тесты
\\\

## 📊 Нагрузочное тестирование

Сценарий тестирования 1000 RPS на один кошелек:
\\\powershell
.\load-test.ps1 -Threads 100 -Connections 1000 -Duration 30 -WalletId <UUID>
\\\

## 🔒 Обработка ошибок

Сервис обрабатывает следующие ошибки:
- 400 - Невалидный запрос, некорректный JSON
- 404 - Кошелек не найден
- 409 - Конфликт при конкурентном доступе
- 422 - Недостаточно средств
- 500 - Внутренняя ошибка сервера

Все ошибки возвращаются в стандартизированном формате.

## 🏗️ Структура проекта

\\\	ext
wallet-service/
├── src/main/java/com/example/wallet/
│   ├── controller/      # REST контроллеры
│   ├── service/         # Бизнес-логика
│   ├── repository/      # Доступ к данным
│   ├── model/          # Сущности БД
│   ├── dto/            # Объекты передачи данных
│   ├── exception/      # Кастомные исключения
│   └── config/         # Конфигурации
├── src/main/resources/
│   ├── db/changelog/   # Миграции Liquibase
│   └── application.yml # Конфигурация
├── src/test/           # Тесты
├── docker/             # Docker конфигурации
├── scripts/            # PowerShell скрипты
├── Dockerfile
├── docker-compose.yml
└── pom.xml
\\\

## 📞 Поддержка

Частые проблемы:
- Порт занят - измените порт в docker-compose.yml
- База данных не запускается - проверьте логи: docker-compose logs postgres
- Недостаточно памяти - увеличьте лимиты в docker-compose.yml

Логи:
\\\ash
docker-compose logs wallet-service  # Логи приложения
docker-compose logs postgres        # Логи базы данных
\\\

## 📄 Лицензия
MIT
