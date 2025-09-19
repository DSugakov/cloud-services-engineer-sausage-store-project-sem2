# Sausage Store (Semester 2)

В репозитории реализовано приложение «Сосисочная» и полный путь CI/CD: Docker, Helm, деплой в Kubernetes, миграции БД и инфраструктура.

## Стек
- Frontend: Angular, TypeScript (сервится Nginx)
- Backend: Java 16, Spring Boot, Spring Data JPA, Flyway
- Backend-report: Go + MongoDB driver
- Databases: PostgreSQL, MongoDB
- Orchestration: Kubernetes + Helm (subcharts: frontend, backend, backend-report, infra)
- CI/CD: GitHub Actions (build images, publish Helm chart to Nexus, deploy to K8s)

## Структура
- `frontend/` — Angular-приложение, Dockerfile (multi-stage)
- `backend/` — Spring Boot, Flyway миграции в `src/main/resources/db/migration` (V001–V004)
- `backend-report/` — сервис отчетов на Go, читает ENV `PORT`, `DB`
- `sausage-store-chart/` — основной Helm-чарт с сабчартами: `frontend`, `backend`, `backend-report`, `infra`
- `.github/workflows/deploy.yaml` — CI/CD пайплайн

## Docker
- Backend: multi-stage Maven build -> JAR, образ `dsugakov/sausage-backend:latest`
- Frontend: multi-stage Node 14 -> Nginx, образ `dsugakov/sausage-frontend:latest`
- Backend-report: Go builder -> alpine runtime, образ `dsugakov/sausage-backend-report:latest`

## Миграции БД (Flyway)
Файлы: `backend/src/main/resources/db/migration/`
- `V001__create_tables.sql` — базовые таблицы `product`, `orders`, `order_product`
- `V002__change_schema.sql` — нормализация/enum статусов
- `V003__insert_data.sql` — начальные данные
- `V004__create_index.sql` — индексы для отчётности

## Helm
Верхний чарт `sausage-store-chart` c сабчартами:
- `infra/` — PostgreSQL (StatefulSet + PVC), MongoDB (StatefulSet)
- `backend/` — Deployment c RollingUpdate, livenessProbe `/actuator/health`, VPA (Off, рекомендации)
- `backend-report/` — Deployment c Recreate, HPA, env `PORT` (ConfigMap), `DB` (Secret)
- `frontend/` — Service + Ingress (TLS)

Центральные значения: `sausage-store-chart/values.yaml` (образы, ресурсы, ingress-хост и т.д.).

## Ключевые настройки
- Backend datasource берётся из ENV:
  - `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`
  - `SPRING_DATA_MONGODB_URI` — прокидывается из ConfigMap; пример:
    `mongodb://reports:reportspassword@mongodb:27017/sausage-store?authSource=sausage-store&authMechanism=SCRAM-SHA-1`
- Backend-report читает:
  - `PORT` из ConfigMap
  - `DB` из Secret (строка подключения к Mongo)
- PostgreSQL — PVC для персистентности
- Стратегии: backend — RollingUpdate, backend-report — Recreate
- Автомасштабирование: VPA (backend, рекомендации), HPA (backend-report)

## CI/CD
Файл: `.github/workflows/deploy.yaml`
1. Сборка и публикация образов в Docker Hub
2. Пакетирование Helm-чарта и публикация в Nexus (helm hosted)
3. Деплой в Kubernetes по kubeconfig
4. Для обхода квоты Secrets используется `HELM_DRIVER=configmap` в job деплоя

## Деплой/проверка
Проверить статус:
```bash
kubectl get pods -n r-devops-magistracy-project-2sem-659769647 -o wide
helm list -n r-devops-magistracy-project-2sem-659769647
```

Проверить backend:
```bash
kubectl port-forward deploy/sem-project-backend 8080:8080 -n r-devops-magistracy-project-2sem-659769647 >/dev/null 2>&1 &
sleep 2
curl -s http://127.0.0.1:8080/actuator/health
curl -s http://127.0.0.1:8080/api/products | head -c 500
```

Фронтенд доступен: `https://front-dsugakov.2sem.students-projects.ru`

## Примечания
- Vault намеренно отключён в runtime (упрощение). При желании можно включить интеграцию через Spring Cloud Vault.
- Для Mongo создан пользователь `reports` в БД `sausage-store`; backend-report использует `authMechanism=SCRAM-SHA-1`.

