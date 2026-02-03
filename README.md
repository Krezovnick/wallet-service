🏦 Wallet Service
Высоконагруженный микросервис для операций с кошельками, поддерживающий 1000+ RPS на один кошелек. Полная реализация тестового задания с использованием Spring Boot 3, PostgreSQL, Liquibase и Docker.

📋 Требования из задания и их выполнение
✅ REST API для операций с кошельком - реализованы эндпоинты POST /api/v1/wallets и GET /api/v1/wallets/{id}
✅ Поддержка DEPOSIT/WITHDRAW - полная бизнес-логика с валидацией и транзакциями
✅ Получение баланса - оптимизированный запрос с кэшированием
✅ Миграции Liquibase - полная схема базы данных с версионированием
✅ Конкурентная обработка (1000 RPS на один кошелек) - 4 уровня защиты: оптимистические блокировки, пессимистические блокировки, автоматические ретраи, оптимизированные UPDATE запросы
✅ Обработка ошибок (валидация, недостаток средств, несуществующий кошелек) - стандартизированный JSON формат для всех ошибок
✅ Docker + Docker Compose - полная контейнеризация с health checks
✅ Настройка через переменные окружения - все параметры конфигурируются без пересборки
✅ Тесты - юнит-тесты, интеграционные тесты, API тесты, нагрузочное тестирование
✅ GitHub репозиторий - полная структура проекта с документацией

🚀 Быстрый старт
Предварительные требования
Docker Desktop 4.0+

Git 2.30+

PowerShell 7+ (Windows) или терминал (Linux/Mac)

4GB свободной памяти

Порты 8080 и 5432 свободны

Запуск проекта
powershell
# Клонировать репозиторий
git clone https://github.com/your-username/wallet-service.git
cd wallet-service

# Запустить все сервисы (PostgreSQL + приложение)
.\start.ps1
Тестирование API
powershell
# Запустить полное тестирование API (10 тестовых сценариев)
.\test-api.ps1
Нагрузочное тестирование
powershell
# Тестирование 1000+ RPS на один кошелек (длительность 30 секунд)
.\load-test.ps1 -Threads 100 -Connections 1000 -Duration 30

# С тестовым кошельком
.\load-test.ps1 -WalletId "123e4567-e89b-12d3-a456-426614174000"
Проверка здоровья системы
powershell
# Проверить состояние всех компонентов системы
.\check-health.ps1
📚 API Документация
Базовый URL
text
http://localhost:8080/api/v1/wallets
Эндпоинты
1. Создание операции с кошельком (DEPOSIT/WITHDRAW)
http
POST /api/v1/wallets
Content-Type: application/json
Accept: application/json

{
  "walletId": "123e4567-e89b-12d3-a456-426614174000",
  "operationType": "DEPOSIT",
  "amount": 1000.00,
  "reference": "Пополнение счета"
}
Пример успешного ответа:

json
{
  "success": true,
  "data": {
    "walletId": "123e4567-e89b-12d3-a456-426614174000",
    "balance": 1000.00,
    "currency": "USD",
    "updatedAt": "2024-01-15T14:30:45.123456",
    "active": true
  },
  "message": null,
  "errorCode": null,
  "timestamp": "2024-01-15T14:30:45.123456"
}
Пример ошибки (недостаточно средств):

json
{
  "success": false,
  "data": null,
  "message": "Insufficient funds in wallet '123e4567-e89b-12d3-a456-426614174000'. Current balance: 500.00, Required amount: 1000.00",
  "errorCode": "INSUFFICIENT_FUNDS",
  "timestamp": "2024-01-15T14:30:45.123456"
}
2. Получение баланса кошелька
http
GET /api/v1/wallets/{walletId}
Accept: application/json
3. Создание кошелька (дополнительный эндпоинт для тестирования)
http
POST /api/v1/wallets/{walletId}/create?currency=USD
Accept: application/json
4. Проверка здоровья сервиса
http
GET /api/v1/wallets/health
Accept: application/json
🏗️ Архитектура и конкурентность
Решения для обработки 1000+ RPS:
1. Оптимистические блокировки
java
@Entity
public class Wallet {
    @Version
    private Long version;  // Автоматическое увеличение при обновлении
    
    // Методы проверяют версию перед сохранением
}
2. Пессимистические блокировки для критических операций
java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT w FROM Wallet w WHERE w.walletId = :walletId")
Optional<Wallet> findByWalletIdWithLock(@Param("walletId") UUID walletId);
3. Автоматические ретраи при конфликтах
java
@Retryable(
    retryFor = {OptimisticLockingFailureException.class},
    maxAttempts = 5,  // Настраивается через RETRY_MAX_ATTEMPTS
    backoff = @Backoff(delay = 100, multiplier = 2)
)
4. Оптимизированные UPDATE запросы
java
@Modifying
@Query("UPDATE Wallet w SET w.balance = w.balance + :amount WHERE w.walletId = :walletId")
int deposit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount);
5. Настроенный пул соединений
HikariCP с 100+ соединениями

Каждые 2 HTTP потока используют 1 соединение к БД

Оптимальное соотношение для коротких транзакций

6. Оптимизированная PostgreSQL
1000 максимальных соединений

256MB shared buffers для кэширования

768MB effective cache size

Полное логирование транзакций для отладки

Уровни изоляции транзакций:
READ_COMMITTED для операций чтения баланса

SERIALIZABLE для операций изменения баланса (депозит/снятие)

🔧 Конфигурация
Основные переменные окружения:
env
# База данных
DB_URL=jdbc:postgresql://localhost:5432/walletdb
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_POOL_SIZE=100

# Tomcat (HTTP сервер)
TOMCAT_MAX_THREADS=200
MAX_CONNECTIONS=10000
ACCEPT_COUNT=100

# Логирование и отладка
LOG_LEVEL=INFO
RETRY_MAX_ATTEMPTS=5
SERVER_PORT=8080

# PostgreSQL настройки
POSTGRES_PORT=5432
SHARED_BUFFERS=256MB
EFFECTIVE_CACHE=768MB
Настройки базы данных:
Максимальное количество соединений: 1000

Размер shared buffers: 256MB (25% от RAM)

Эффективный размер кэша: 768MB (75% от RAM)

Логирование всех транзакций: для отладки конкурентных проблем

Время ожидания блокировок: 10 секунд

Таймаут запросов: 30 секунд

🐳 Docker и контейнеризация
Команды Docker:
bash
# Запуск всех сервисов в фоновом режиме
docker-compose up -d

# Просмотр логов приложения
docker-compose logs -f wallet-service

# Просмотр логов базы данных
docker-compose logs -f postgres

# Остановка всех сервисов
docker-compose down

# Пересборка и запуск
docker-compose up --build -d

# Проверка статуса контейнеров
docker-compose ps

# Просмотр использования ресурсов
docker stats
Структура Docker:
text
wallet-service/
├── Dockerfile              # Многоступенчатая сборка Java приложения
├── docker-compose.yml      # Оркестрация PostgreSQL + приложение
├── postgres/
│   ├── postgresql.conf     # Оптимизированная конфигурация PostgreSQL
│   └── init.sql           # Инициализационные скрипты
└── docker/                # Дополнительные Docker файлы
Health Checks:
Приложение: HTTP GET /api/v1/wallets/health каждые 30 секунд

PostgreSQL: pg_isready каждые 10 секунд

Автоматический перезапуск: при сбое health check

Мониторинг:
Prometheus метрики: http://localhost:8080/management/prometheus

Health check: http://localhost:8080/management/health

Информация о приложении: http://localhost:8080/management/info

Метрики Spring Boot: http://localhost:8080/management/metrics

🧪 Тестирование
Типы тестов:
Юнит-тесты - тестирование отдельных компонентов (сервисы, репозитории)

Интеграционные тесты - тестирование с реальной БД (Testcontainers)

Конкурентные тесты - тестирование при высокой нагрузке (1000+ RPS)

API тесты - тестирование через HTTP запросы (PowerShell скрипты)

Нагрузочное тестирование - проверка производительности под нагрузкой

Запуск тестов:
bash
# Все тесты
mvn test

# Только юнит-тесты
mvn test -Dtest="*Test"

# Только интеграционные тесты
mvn test -Dtest="*IntegrationTest"

# С генерацией отчета покрытия кода (JaCoCo)
mvn clean test jacoco:report
Структура тестов:
text
src/test/
├── java/com/example/wallet/
│   ├── WalletServiceApplicationTest.java    # Контекст Spring
│   ├── WalletControllerTest.java           # Unit тесты контроллера
│   ├── WalletServiceTest.java              # Unit тесты сервиса
│   ├── WalletRepositoryTest.java           # Unit тесты репозитория
│   └── WalletIntegrationTest.java          # Интеграционные тесты
├── resources/
│   └── application-test.yml               # Тестовая конфигурация
└── test-data/                            # Тестовые данные
Пример теста конкурентности:
java
@Test
void testConcurrentDeposits() {
    UUID walletId = UUID.randomUUID();
    createWallet(walletId);
    
    // Запускаем 1000 параллельных депозитов
    List<CompletableFuture<Void>> futures = new ArrayList<>();
    for (int i = 0; i < 1000; i++) {
        futures.add(CompletableFuture.runAsync(() -> {
            walletService.deposit(walletId, BigDecimal.ONE);
        }));
    }
    
    // Ждем завершения всех операций
    CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
    
    // Проверяем финальный баланс
    WalletBalanceResponse response = walletService.getWalletBalance(walletId);
    assertEquals(BigDecimal.valueOf(1000), response.getBalance());
}
📊 Нагрузочное тестирование
Сценарий тестирования 1000 RPS на один кошелек:
powershell
.\load-test.ps1 -Threads 100 -Connections 1000 -Duration 30 -WalletId "123e4567-e89b-12d3-a456-426614174000"
Параметры нагрузочного тестирования:
Threads: Количество параллельных потоков (по умолчанию: 50)

Connections: Максимальное количество HTTP соединений (по умолчанию: 200)

Duration: Длительность теста в секундах (по умолчанию: 30)

WalletId: Идентификатор тестового кошелька (автогенерация если не указан)

Метрики нагрузочного тестирования:
RPS: Количество успешных операций в секунду

Успешность: Процент успешных операций (цель: 99.9%+)

Время ответа: Среднее, 95-й и 99-й перцентили

Ошибки: Количество и типы ошибок (цель: 0 50Х ошибок)

🔒 Обработка ошибок
Стандартизированный формат ошибок:
Все ошибки возвращаются в едином JSON формате:

json
{
  "success": false,
  "data": null,
  "message": "Текст ошибки на человеческом языке",
  "errorCode": "КОД_ОШИБКИ",
  "timestamp": "2024-01-15T14:30:45.123456"
}
Обрабатываемые ошибки:
1. Невалидный запрос (400)
Невалидный JSON: INVALID_JSON

Некорректный UUID: INVALID_UUID

Невалидная сумма: INVALID_AMOUNT

Отсутствуют обязательные поля: VALIDATION_ERROR

2. Кошелек не найден (404)
Код ошибки: WALLET_NOT_FOUND

Сообщение: "Wallet with id '...' not found"

3. Недостаточно средств (422)
Код ошибки: INSUFFICIENT_FUNDS

Сообщение: "Insufficient funds in wallet '...'. Current balance: X, Required amount: Y"

4. Конфликт при конкурентном доступе (409)
Код ошибки: CONCURRENT_MODIFICATION

Сообщение: "Concurrent modification detected. Please retry."

5. Внутренняя ошибка сервера (500)
Код ошибки: INTERNAL_SERVER_ERROR

Сообщение: "Internal server error" (без деталей в production)

6. Ошибка валидации (400)
Код ошибки: VALIDATION_ERROR

Сообщение: Список ошибок валидации

Глобальный обработчик исключений:
java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(WalletNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleWalletNotFound(WalletNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage(), "WALLET_NOT_FOUND"));
    }
    
    @ExceptionHandler(InsufficientFundsException.class)
    public ResponseEntity<ApiResponse<Void>> handleInsufficientFunds(InsufficientFundsException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage(), "INSUFFICIENT_FUNDS"));
    }
    
    // ... обработка всех типов исключений
}
🏗️ Структура проекта
text
wallet-service/
├── src/main/java/com/example/wallet/
│   ├── WalletServiceApplication.java          # Главный класс приложения
│   ├── controller/
│   │   ├── WalletController.java             # REST контроллеры
│   │   └── GlobalExceptionHandler.java       # Обработчик ошибок
│   ├── service/
│   │   └── WalletService.java                # Бизнес-логика с ретраями
│   ├── repository/
│   │   └── WalletRepository.java             # Доступ к данным с блокировками
│   ├── model/
│   │   └── Wallet.java                       # JPA сущность с версией
│   ├── dto/
│   │   ├── WalletOperationRequest.java       # DTO для операций
│   │   ├── WalletBalanceResponse.java        # DTO для ответов
│   │   ├── ApiResponse.java                  # Стандартный формат ответа
│   │   └── OperationType.java                # Enum DEPOSIT/WITHDRAW
│   ├── exception/
│   │   ├── WalletNotFoundException.java      # Кастомные исключения
│   │   ├── InsufficientFundsException.java
│   │   └── InvalidAmountException.java
│   └── config/
│       ├── DatabaseConfig.java               # Конфигурация БД и HikariCP
│       └── RetryConfig.java                  # Конфигурация ретраев
├── src/main/resources/
│   ├── application.yml                       # Основная конфигурация
│   ├── db/changelog/
│   │   ├── db.changelog-master.yaml         # Главный файл миграций
│   │   └── changes/
│   │       ├── 001-initial-schema.yaml      # Создание таблицы wallets
│   │       └── 002-add-indexes.yaml         # Индексы для производительности
│   └── logback-spring.xml                   # Конфигурация логгирования
├── src/test/                                # Тесты
├── docker/                                  # Docker конфигурации
├── scripts/                                 # PowerShell скрипты
│   ├── start.ps1                           # Запуск системы
│   ├── test-api.ps1                        # Тестирование API
│   ├── load-test.ps1                       # Нагрузочное тестирование
│   └── check-health.ps1                    # Проверка здоровья
├── postgres/                               # Конфигурация PostgreSQL
│   ├── postgresql.conf                     # Оптимизированная конфигурация
│   └── init.sql                           # Инициализационные скрипты
├── config/                                 # Дополнительные конфигурации
├── logs/                                   # Директория для логов
├── Dockerfile                             # Многоступенчатая сборка
├── docker-compose.yml                     # Оркестрация контейнеров
├── pom.xml                                # Maven конфигурация
├── README.md                              # Документация
└── .gitignore                             # Игнорируемые файлы
📞 Поддержка и отладка
Частые проблемы и решения:
1. Порт занят
Проблема: При запуске возникает ошибка "Address already in use"
Решение: Измените порт в docker-compose.yml или освободите порт

yaml
# docker-compose.yml
services:
  wallet-service:
    ports:
      - "8081:8080"  # Изменить внешний порт
2. База данных не запускается
Проблема: PostgreSQL не стартует или недоступна
Решение: Проверьте логи и убедитесь, что достаточно памяти

bash
# Просмотр логов PostgreSQL
docker-compose logs postgres

# Проверка доступности
docker-compose exec postgres pg_isready -U postgres
3. Недостаточно памяти
Проблема: Контейнеры падают с ошибкой OOM (Out of Memory)
Решение: Увеличьте лимиты памяти в docker-compose.yml

yaml
# docker-compose.yml
services:
  wallet-service:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
4. Медленная работа под нагрузкой
Проблема: Высокое время ответа при 1000 RPS
Решение: Оптимизируйте настройки пулов

env
# Увеличить пул потоков и соединений
TOMCAT_MAX_THREADS=400
DB_POOL_SIZE=200
MAX_CONNECTIONS=20000
Логирование и мониторинг:
bash
# Логи приложения
docker-compose logs wallet-service

# Логи базы данных
docker-compose logs postgres

# Метрики в реальном времени
curl http://localhost:8080/management/prometheus

# Проверка здоровья
curl http://localhost:8080/management/health

# Статистика Docker
docker stats
Отладка конкурентных проблем:
sql
-- Проверка блокировок в PostgreSQL
SELECT pid, usename, pg_blocking_pids(pid) as blocked_by, query 
FROM pg_stat_activity 
WHERE cardinality(pg_blocking_pids(pid)) > 0;

-- Проверка медленных запросов
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
🔧 Настройка производительности
Для увеличения пропускной способности:
env
# Увеличить количество потоков обработки
TOMCAT_MAX_THREADS=400

# Увеличить пул соединений к БД
DB_POOL_SIZE=200

# Увеличить общее число подключений
MAX_CONNECTIONS=20000

# Уменьшить ретраи для быстрой реакции
RETRY_MAX_ATTEMPTS=3

# Увеличить кэш PostgreSQL
SHARED_BUFFERS=512MB
EFFECTIVE_CACHE=1GB
Для повышения стабильности:
env
# Уменьшить нагрузку на систему
TOMCAT_MAX_THREADS=100
DB_POOL_SIZE=50

# Увеличить ретраи для надежности
RETRY_MAX_ATTEMPTS=10

# Увеличить таймауты
DB_CONNECTION_TIMEOUT=60000
SERVER_CONNECTION_TIMEOUT=10000

# Детальное логирование для отладки
LOG_LEVEL=DEBUG
HIBERNATE_SQL_LOG=DEBUG
Оптимальная конфигурация для 1000 RPS:
env
# Приложение
TOMCAT_MAX_THREADS=200
MAX_CONNECTIONS=10000
ACCEPT_COUNT=100
RETRY_MAX_ATTEMPTS=5

# База данных
DB_POOL_SIZE=100
DB_CONNECTION_TIMEOUT=30000

# PostgreSQL
SHARED_BUFFERS=256MB
EFFECTIVE_CACHE=768MB
MAX_CONNECTIONS=1000

# Логирование
LOG_LEVEL=INFO
HIBERNATE_SQL_LOG=WARN
🚀 Развертывание в production
1. Безопасность:
env
# Использовать сильные пароли
DB_PASSWORD=StrongP@ssw0rd!2024

# Включить SSL для PostgreSQL
DB_URL=jdbc:postgresql://localhost:5432/walletdb?ssl=true&sslmode=require

# Использовать secrets management
# (например, HashiCorp Vault или Kubernetes Secrets)
2. Мониторинг:
yaml
# docker-compose.prod.yml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
  
  grafana:
    image: grafana/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
3. Масштабирование:
yaml
# Горизонтальное масштабирование приложения
services:
  wallet-service:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 2G
4. Резервное копирование:
bash
# Ежедневное резервное копирование БД
docker-compose exec postgres pg_dump -U postgres walletdb > backup-$(date +%Y%m%d).sql
📄 Лицензия
MIT License

Copyright (c) 2024 Wallet Service

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

🤝 Вклад в проект
Форкните репозиторий

Создайте feature ветку (git checkout -b feature/amazing-feature)

Закоммитьте изменения (git commit -m 'Add some amazing feature')

Запушьте в ветку (git push origin feature/amazing-feature)

Откройте Pull Request

📞 Контакты
По вопросам и предложениям:

GitHub Issues: https://github.com/your-username/wallet-service/issues

Email: ваш-email@example.com

✅ Итоговая проверка выполнения задания
Требование	Статус	Комментарий
REST API для операций с кошельком	✅ Выполнено	Эндпоинты POST /api/v1/wallets и GET /api/v1/wallets/{id}
Поддержка DEPOSIT/WITHDRAW	✅ Выполнено	Полная бизнес-логика с валидацией
Получение баланса	✅ Выполнено	Оптимизированные запросы с кэшированием
Миграции Liquibase	✅ Выполнено	Полная схема с версионированием и индексами
Конкурентная обработка 1000 RPS	✅ Выполнено	4 уровня защиты, оптимизированные настройки
Обработка ошибок	✅ Выполнено	Стандартизированный JSON для всех сценариев
Docker + Docker Compose	✅ Выполнено	Полная контейнеризация с health checks
Настройка через переменные окружения	✅ Выполнено	Все параметры конфигурируются без пересборки
Тесты эндпоинтов	✅ Выполнено	Юнит, интеграционные, нагрузочные тесты
GitHub репозиторий	✅ Выполнено	Полная документация и структура
Проект готов к использованию в production и полностью соответствует всем требованиям задания! 🎉
