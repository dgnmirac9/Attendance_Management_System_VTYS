# C-Lens Yüz Tanıma Yoklama Sistemi - Teknik Rapor

## 1. Mimari Yapı

### Backend Mimarisi (Python FastAPI)
```
backend/
├── app/
│   ├── api/v1/          # REST API endpoints
│   ├── services/        # Business logic layer
│   ├── models/          # SQLAlchemy ORM models
│   ├── schemas/         # Pydantic validation schemas
│   ├── core/            # Security, encryption utilities
│   └── database.py      # Database connection management
├── tests/               # Unit & integration tests
└── alembic/            # Database migrations
```

**Katmanlı Mimari:**
- **API Layer:** FastAPI router'lar ile HTTP endpoint'leri
- **Service Layer:** İş mantığı ve veri işleme
- **Data Layer:** SQLAlchemy ORM ile veritabanı erişimi
- **Security Layer:** JWT authentication, encryption

**📸 EKRAN GÖRÜNTÜSÜ AL:** Proje klasör yapısının VS Code explorer görünümü
 
### Frontend Mimarisi (Flutter)
```
lib/
├── screens/            # UI ekranları
├── services/           # API client, business logic
├── models/             # Data models
└── widgets/            # Reusable components
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** Flutter proje klasör yapısı

---

## 2. KVKK Uyumlu Yüz Verisi İşleme

### Veri Güvenliği Yaklaşımı

**Temel Prensipler:**
1. **Fotoğraf Saklanmaz:** Yüz fotoğrafları veritabanında veya dosya sisteminde saklanmaz
2. **Embedding Kullanımı:** Sadece 512-boyutlu matematiksel vektör (embedding) saklanır
3. **Şifreleme:** Embedding'ler Fernet (AES-128) ile şifrelenir
4. **Geri Dönüşümsüz:** Embedding'den fotoğraf elde edilemez

**Veri Akışı:**
```
Fotoğraf (Base64) → DeepFace → Embedding (512 float) → Fernet Encryption → Database
```

**Saklanan Veri Örneği:**
```python
# Şifrelenmemiş embedding (saklanmaz)
[0.123, -0.456, 0.789, ...] # 512 boyut

# Şifrelenmiş embedding (veritabanında saklanır)
"gAAAAABh3x2y_encrypted_data_here..."
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** Veri akışı diyagramı (Fotoğraf → Embedding → Şifreleme → Database)

**Güvenlik Özellikleri:**
- Encryption key environment variable'da saklanır
- Her embedding benzersiz şifrelenir
- Veritabanı erişimi JWT token ile korunur
- HTTPS ile iletim güvenliği (production)

---

## 3. Yüz Karşılaştırma Mantığı

### Teknik Yaklaşım

**Model:** Facenet512 (Google FaceNet)
- 512-boyutlu embedding vektörü
- Pre-trained deep learning model
- %99+ doğruluk oranı

**Karşılaştırma Algoritması:**
```python
def calculate_cosine_similarity(embedding1, embedding2):
    # Cosine similarity hesaplama
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    similarity = dot_product / (norm1 * norm2)
    
    # [-1, 1] aralığını [0, 1]'e normalize et
    similarity = (similarity + 1) / 2
    return similarity
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** `app/services/face_service.py` dosyasındaki `calculate_cosine_similarity` fonksiyonu

**Threshold Mantığı:**
- **Threshold:** 0.80 (80% benzerlik)
- **0.80-1.00:** Eşleşme (aynı kişi)
- **0.60-0.79:** Orta benzerlik
- **0.00-0.59:** Eşleşmeme (farklı kişi)

**API Akışı:**
```
1. Öğrenci yüz fotoğrafı gönderir (Base64)
2. DeepFace embedding çıkarır
3. Veritabanından şifreli embedding alınır
4. Şifre çözülür
5. Cosine similarity hesaplanır
6. Threshold ile karşılaştırılır
7. Sonuç döndürülür (match/no-match + similarity score)
```

**Duplicate Prevention:**
- Kayıt sırasında tüm mevcut yüzlerle karşılaştırma
- Aynı yüz birden fazla öğrenciye kaydedilemez
- O(n) complexity - n: kayıtlı öğrenci sayısı

---

## 4. Backend API Yapısı

### Temel Endpoint'ler

**Authentication:**
```
POST /api/v1/auth/register  - Kullanıcı kaydı
POST /api/v1/auth/login     - Giriş (JWT token)
POST /api/v1/auth/logout    - Çıkış (token iptal)
```

**Face Recognition:**
```
POST /api/v1/face/register  - Yüz kaydı
POST /api/v1/face/verify    - Yüz doğrulama
GET  /api/v1/face/status    - Kayıt durumu
```

**Attendance (Planlanan):**
```
POST /api/v1/attendances           - Yoklama başlat
POST /api/v1/attendances/check-in  - Yüz ile yoklama
GET  /api/v1/attendances/{id}      - Yoklama detayları
```

### Request-Response Örneği

**Login Request:**
```json
POST /api/v1/auth/login
{
  "email": "student@university.edu",
  "password": "SecurePass123"
}
```

**Login Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "student@university.edu",
    "role": "student"
  }
}
```

**Face Register Request:**
```json
POST /api/v1/face/register
Authorization: Bearer <token>
{
  "image_base64": "data:image/jpeg;base64,/9j/4AAQ...",
  "check_duplicate": true
}
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** Swagger UI'da authentication endpoint'lerinin görünümü

**📸 EKRAN GÖRÜNTÜSÜ AL:** Postman'de face/register endpoint'inin test edilmesi

### Kimlik Doğrulama Akışı
```
1. Login → JWT Token
2. Token → Authorization Header
3. Her request'te token doğrulanır
4. Token'dan user_id ve role çıkarılır
5. Endpoint'e erişim kontrol edilir
```

---

## 5. Git ve Branch Yapısı

### Repository Organizasyonu
```
main (production)
├── develop (development)
│   ├── feature/auth-system
│   ├── feature/face-recognition
│   ├── feature/attendance-system
│   └── feature/course-management
```

**Branch Stratejisi:**
- `main`: Production-ready kod
- `develop`: Development branch
- `feature/*`: Özellik geliştirme branch'leri
- `hotfix/*`: Acil düzeltmeler

**Commit Convention (Semantic Commits):**
```
feat: Add face recognition service
fix: Fix duplicate face check bug
docs: Update API documentation
test: Add face service unit tests
refactor: Improve encryption service
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** Git branch yapısının görünümü (GitKraken, SourceTree veya VS Code Git Graph)

**📸 EKRAN GÖRÜNTÜSÜ AL:** Commit history'de semantic commit örnekleri

---

## 6. Rol Yönetimi (RBAC)

### Rol Tabanlı Erişim Kontrolü

**Roller:**
- **Student:** Yüz kaydı, yoklama, ödev teslimi
- **Instructor:** Ders oluşturma, yoklama başlatma, not verme

**Implementasyon:**
```python
# JWT token'da rol bilgisi
{
  "sub": "1",
  "email": "student@university.edu",
  "role": "student"  # ← Rol bilgisi
}

# Endpoint'te rol kontrolü
@router.post("/face/register")
def register_face(current_user: User = Depends(get_current_user)):
    if current_user.role != "student":
        raise HTTPException(403, "Only students can register faces")
    # ...
```

**📸 EKRAN GÖRÜNTÜSÜ AL:** `app/api/v1/face.py` dosyasındaki rol kontrolü kodu (register_face fonksiyonu)

**Veritabanı Seviyesinde Ayrım:**
```sql
users (base table)
├── students (student-specific data + face_data)
└── instructors (instructor-specific data)
```

**Erişim Matrisi:**
| Endpoint | Student | Instructor |
|----------|---------|------------|
| Face Register | ✅ | ❌ |
| Face Verify | ✅ | ❌ |
| Create Course | ❌ | ✅ |
| Start Attendance | ❌ | ✅ |
| Check-in | ✅ | ❌ |

---

## 7. Teknoloji Stack

**Backend:**
- FastAPI 0.104 (Python web framework)
- SQLAlchemy 2.0 (ORM)
- PostgreSQL/SQLite (Database)
- DeepFace + Facenet512 (Face recognition)
- JWT + Bcrypt (Security)
- Fernet (Encryption)

**Frontend:**
- Flutter 3.x
- Dio (HTTP client)
- ML Kit (Face detection)
- Provider (State management)

**DevOps:**
- Docker & Docker Compose
- Alembic (Database migrations)
- Pytest (Testing)

---

## SUNUM İÇİN KISA PROJE ÖZETİ

**C-Lens**, eğitim kurumları için geliştirilmiş yüz tanıma tabanlı yoklama sistemidir. Sistem, öğrencilerin yüz verilerini KVKK uyumlu şekilde işleyerek güvenli ve hızlı yoklama almayı sağlar. Backend tarafında FastAPI ve DeepFace kullanılarak geliştirilen RESTful API, yüz fotoğraflarını saklamadan sadece matematiksel embedding'leri şifreli olarak depolar. Frontend'de Flutter ile geliştirilmiş mobil uygulama, öğrenci ve akademisyen rollerine göre farklılaşan arayüzler sunar. Sistem, JWT tabanlı kimlik doğrulama, rol bazlı erişim kontrolü ve %80 benzerlik threshold'u ile yüksek güvenlik ve doğruluk sağlar. Proje, modern yazılım geliştirme pratikleri (semantic commits, feature-based architecture, comprehensive testing) ile geliştirilmektedir.

---

**Rapor Tarihi:** 28 Kasım 2025  
**Proje Durumu:** %45 Tamamlandı (Core backend servisleri aktif)  
**Versiyon:** 1.0.0-beta
