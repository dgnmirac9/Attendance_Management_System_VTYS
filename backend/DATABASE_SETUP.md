# Database Setup Guide

## Option 1: Docker (Recommended)

Docker kullanarak PostgreSQL'i hızlıca başlatabilirsiniz:

### 1. Docker Compose ile Başlatma

`docker-compose.yml` dosyası oluşturun:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: clens_postgres
    environment:
      POSTGRES_USER: clens_user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: clens_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U clens_user -d clens_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: clens_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### 2. Docker Compose'u Başlatın

```bash
docker-compose up -d
```

### 3. Database'in Çalıştığını Kontrol Edin

```bash
docker-compose ps
```

### 4. Database'e Bağlanın (Test)

```bash
docker exec -it clens_postgres psql -U clens_user -d clens_db
```

## Option 2: Local PostgreSQL Installation

### Windows

1. **PostgreSQL'i İndirin ve Kurun:**
   - https://www.postgresql.org/download/windows/
   - PostgreSQL 15 veya üstü önerilir

2. **pgAdmin veya psql ile Database Oluşturun:**

```sql
-- PostgreSQL'e bağlanın (postgres kullanıcısı ile)
CREATE USER clens_user WITH PASSWORD 'password';
CREATE DATABASE clens_db OWNER clens_user;
GRANT ALL PRIVILEGES ON DATABASE clens_db TO clens_user;
```

3. **PATH'e Ekleyin (Opsiyonel):**
   - `C:\Program Files\PostgreSQL\15\bin` klasörünü sistem PATH'ine ekleyin

### Linux/Mac

```bash
# PostgreSQL'i kurun
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# Mac (Homebrew):
brew install postgresql@15

# PostgreSQL'i başlatın
sudo systemctl start postgresql  # Linux
brew services start postgresql@15  # Mac

# Database ve kullanıcı oluşturun
sudo -u postgres psql

CREATE USER clens_user WITH PASSWORD 'password';
CREATE DATABASE clens_db OWNER clens_user;
GRANT ALL PRIVILEGES ON DATABASE clens_db TO clens_user;
\q
```

## Environment Configuration

### 1. .env Dosyası Oluşturun

```bash
cp .env.example .env
```

### 2. .env Dosyasını Düzenleyin

Database bağlantı bilgilerinizi güncelleyin:

```env
DATABASE_URL=postgresql://clens_user:password@localhost:5432/clens_db
```

**Docker kullanıyorsanız:** Yukarıdaki ayarlar doğru.

**Local PostgreSQL kullanıyorsanız:** Kendi kullanıcı adı ve şifrenizi girin.

## Database Migration

### 1. Alembic ile Migration'ları Çalıştırın

```bash
cd backend

# Migration'ları uygula
alembic upgrade head
```

### 2. Migration Durumunu Kontrol Edin

```bash
alembic current
```

### 3. Migration Geçmişini Görüntüleyin

```bash
alembic history
```

## Database'i Test Etme

### 1. FastAPI Uygulamasını Başlatın

```bash
cd backend
uvicorn app.main:app --reload
```

### 2. Debug Endpoint'lerini Kullanın

Tarayıcınızda şu adresleri açın:

- **Swagger UI:** http://localhost:8000/docs
- **Tüm Tabloları Listele:** http://localhost:8000/api/v1/debug/tables
- **Database İstatistikleri:** http://localhost:8000/api/v1/debug/stats

### 3. Belirli Bir Tabloyu Görüntüleyin

```bash
# Users tablosunu görüntüle
curl http://localhost:8000/api/v1/debug/table/users

# Students tablosunu görüntüle
curl http://localhost:8000/api/v1/debug/table/students
```

## Troubleshooting

### Problem: "password authentication failed"

**Çözüm:**
1. .env dosyasındaki DATABASE_URL'i kontrol edin
2. PostgreSQL kullanıcı şifresini doğrulayın
3. PostgreSQL'in çalıştığından emin olun

```bash
# Docker ile
docker-compose ps

# Local PostgreSQL ile (Linux)
sudo systemctl status postgresql

# Mac
brew services list
```

### Problem: "connection refused"

**Çözüm:**
1. PostgreSQL'in çalıştığından emin olun
2. Port 5432'nin açık olduğunu kontrol edin
3. Firewall ayarlarını kontrol edin

```bash
# Port kontrolü (Windows)
netstat -an | findstr 5432

# Port kontrolü (Linux/Mac)
netstat -an | grep 5432
```

### Problem: "database does not exist"

**Çözüm:**
Database'i oluşturun:

```bash
# Docker ile
docker exec -it clens_postgres psql -U clens_user -c "CREATE DATABASE clens_db;"

# Local PostgreSQL ile
psql -U postgres -c "CREATE DATABASE clens_db OWNER clens_user;"
```

### Problem: Migration hatası

**Çözüm:**
1. Database'i sıfırlayın ve tekrar migration yapın:

```bash
# Tüm tabloları sil (DİKKAT: Tüm veriler silinir!)
alembic downgrade base

# Migration'ları tekrar uygula
alembic upgrade head
```

## Database Yönetimi

### Tüm Tabloları Görüntüleme

```sql
-- PostgreSQL'e bağlanın
psql -U clens_user -d clens_db

-- Tüm tabloları listele
\dt

-- Tablo yapısını görüntüle
\d users
\d students
\d courses

-- Çıkış
\q
```

### Database'i Yedekleme

```bash
# Docker ile
docker exec clens_postgres pg_dump -U clens_user clens_db > backup.sql

# Local PostgreSQL ile
pg_dump -U clens_user clens_db > backup.sql
```

### Database'i Geri Yükleme

```bash
# Docker ile
docker exec -i clens_postgres psql -U clens_user clens_db < backup.sql

# Local PostgreSQL ile
psql -U clens_user clens_db < backup.sql
```

## Quick Start (Docker)

Hızlı başlangıç için tüm adımlar:

```bash
# 1. Docker Compose dosyasını oluştur (yukarıdaki docker-compose.yml)
# 2. .env dosyasını oluştur
cp .env.example .env

# 3. Docker container'ları başlat
docker-compose up -d

# 4. Database migration'ları çalıştır
cd backend
alembic upgrade head

# 5. Uygulamayı başlat
uvicorn app.main:app --reload

# 6. Tarayıcıda test et
# http://localhost:8000/docs
# http://localhost:8000/api/v1/debug/tables
```

## Database Schema

Migration sonrası oluşturulacak tablolar:

- `users` - Kullanıcı hesapları (student ve instructor)
- `students` - Öğrenci bilgileri ve yüz verileri
- `instructors` - Öğretmen bilgileri
- `courses` - Ders bilgileri
- `course_enrollments` - Öğrenci-ders ilişkileri
- `attendances` - Yoklama oturumları
- `attendance_records` - Bireysel yoklama kayıtları
- `assignments` - Ödevler
- `assignment_submissions` - Ödev teslimler
- `announcements` - Duyurular
- `student_shared_notes` - Öğrenci notları
- `surveys` - Anketler
- `survey_responses` - Anket cevapları
- `tokens` - JWT token yönetimi

## Support

Sorun yaşıyorsanız:
1. Database loglarını kontrol edin
2. .env dosyasının doğru olduğundan emin olun
3. PostgreSQL'in çalıştığını doğrulayın
4. Debug endpoint'lerini kullanarak database durumunu kontrol edin
