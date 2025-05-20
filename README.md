# Airline-Chat-App

# video gateway: https://drive.google.com/file/d/1u0aFm8LNDyoRbgmb1T2oeKV8muMvrnKJ/view?usp=sharing
# video flutter app: https://drive.google.com/file/d/1ELC8EzvlAu_zx27Pt7CXkmvooyf-WRKD/view?usp=sharing

## Proje Genel Bakış
Bu proje, bir havayolu bilet sistemi geliştirmek ve akıllı bir chat uygulaması oluşturmak amacıyla tasarlanmıştır. Proje, kullanıcıların uçuş sorgulama, bilet satın alma ve check-in gibi işlemleri yapabileceği bir sistem sunmayı hedefler. Akıllı chat özelliği, OpenAI entegrasyonu ile doğal dil işleme (NLP) kullanılarak mesajların intent’ini ayrıştırma ve parametreleri çıkarma yeteneği kazandırmayı amaçlar. Proje aşağıdaki bileşenlerden oluşur:

- **Midterm API**: Havayolu sistemi için backend hizmetlerini sağlayan bir .NET Core uygulaması.
- **Gateway**: Midterm API ile iletişim kuran ve istekleri yönlendiren bir ara katman.
- **Flutter Uygulaması**: Kullanıcı arayüzü ve frontend tarafını yöneten mobil/web uyumlu bir uygulama.
- **Firebase**: Kullanıcı kimlik doğrulama ve mesajlaşma verileri için bir backend-as-a-service platformu.
- **OpenAI**: Akıllı chat fonksiyonelliği için doğal dil işleme desteği.

## Kullanılan Teknolojiler
- **Backend (Midterm API)**:
  - .NET Core (versiyon: 6.0 veya üstü)
  - Entity Framework Core (MSSQL ile veritabanı bağlantısı)
  - JWT Authentication (Kimlik doğrulama için)
  - Swagger (API dokümantasyonu için)
- **Gateway**:
  - .NET Core (Midterm API ile entegre bir ara katman)
- **Frontend (Flutter Uygulaması)**:
  - Flutter (Mobil ve web için cross-platform geliştirme)
  - Firebase Authentication (Google ile giriş)
  - Firebase Firestore (Mesajlaşma verileri için)
  - HTTP Package (API istekleri için)
 
  - ![Ekran görüntüsü 2025-05-20 175543](https://github.com/user-attachments/assets/297aa00d-5626-4b27-9552-25b98bca2b30)

- **OpenAI**:
  - OpenAI API (gpt-3.5-turbo modeli ile mesaj ayrıştırma)
  - API Anahtarı ile entegre (Tier 1 planı kullanıldı)
- **Diğer Araçlar**:
  - Visual Studio Code (Kod editörü)
  - Terminal (Sunucu ve Flutter çalıştırma)
  - Postman veya cURL (API testleri için)

## Proje Yapısı
- **Midterm API**:
  - `Program.cs`: Sunucu yapılandırması ve CORS ayarları.
  - `Controllers`: API endpoint’leri (örneğin, `/api/v1/auth/login`, `/api/gateway/query-flight`).
  - `Data`: Veritabanı bağlamı (AirlineDbContext).
  - `Services`: İş mantığı (FlightService, TicketService, vb.).
- **Gateway**:
  - Midterm API ile Flutter arasında bir köprü, port 5000 ve 5205 üzerinden çalışıyor.
- **Flutter Uygulaması**:
  - `lib/screens/chat_screen.dart`: Ana chat ekranı, OpenAI ve Midterm API entegrasyonu.
  - `lib/models/message.dart`: Mesaj modeli.
  - `lib/services/auth_service.dart`: Firebase kimlik doğrulama.
- **OpenAI Entegrasyonu**:
  - `chat_screen.dart` içinde OpenAI API ile mesaj ayrıştırma fonksiyonu (`parseMessageWithOpenAI`).

## Kurulum ve Çalıştırma
### Midterm API ve Gateway
1. **Gereksinimler**:
   - .NET SDK (6.0 veya üstü)
   - MSSQL Server (veritabanı için)
2. **Kurulum**:
   - Proje dizinine gidin: `cd MidtermAPI`
   - `dotnet restore` ile bağımlılıkları yükleyin.
   - `dotnet run` ile sunucuyu başlatın (varsayılan port: 5205).
3. **Gateway**:
   - Ayrı bir dizinde çalıştırın (port: 5000), Midterm API ile entegre olacak şekilde yapılandırın.

### Flutter Uygulaması
1. **Gereksinimler**:
   - Flutter SDK (en son sürüm)
   - Firebase projesi (Authentication ve Firestore için yapılandırılmış)
   - OpenAI API Anahtarı (Tier 1 planı ile)
2. **Kurulum**:
   - Proje dizinine gidin: `cd flutter_app`
   - `flutter pub get` ile bağımlılıkları yükleyin.
   - Firebase yapılandırma dosyasını (`google-services.json` veya `GoogleService-Info.plist`) ekleyin.
   - OpenAI API anahtarını `chat_screen.dart` içinde tanımlayın.
3. **Çalıştırma**:
   - Mobil için: `flutter run -d emulator`
   - Web için: `flutter run -d chrome --web-port=53571` (sabit port için)

## Karşılaşılan Sorunlar ve Çözüm Denemeleri
### 1. OpenAI 429 Hata (Too Many Requests)
- **Sorun**: Ücretsiz planda OpenAI API limiti aşıldı, "Resets in 12 days" mesajı alındı.
- **Deneme**:
  - 23 dakikalık bekleme süresi uygulandı, ancak sorun devam etti.
  - Lokal mesaj ayrıştırıcı (`simpleMessageParser`) ile OpenAI bağımlılığı geçici olarak kaldırıldı.
- **Çözüm**: Tier 1 planına geçiş yapıldı, OpenAI entegrasyonu yeniden aktif hale getirildi.

### 2. Midterm API Bağlantı Sorunları
- **Sorun**: `ClientException: Failed to fetch, uri=http://localhost:5205/api/v1/auth/login` ve `http://localhost:5000/api/gateway/query-flight` için bağlantı hatası.
- **Olası Nedenler**:
  - Sunucu kapalıydı, `dotnet run` ile başlatıldı.
  - Yanlış port (5205 yerine 5000 veya tersi) kullanıldı, portlar kontrol edildi.
  - CORS hatası (web’de çalıştırma sırasında).
- **Deneme**:
  - Sunucunun çalıştığı doğrulandı (terminalde "Now listening on" mesajı).
  - Manuel testler yapıldı (Postman ile `/api/v1/auth/login` ve `/api/gateway/query-flight` endpoint’leri test edildi).
  - `Program.cs`’e CORS eklendi, ancak Flutter web portu sürekli değiştiği için dinamik çözüm arandı.
- **Çözüm**:
  - `Program.cs`’de `SetIsOriginAllowed` ile tüm `localhost` portları kabul edildi.
  - Sabit port kullanımı önerildi (`--web-port=53571`).
  - Yerel IP (`192.168.1.x`) ile test denendi.

### 3. Flutter Web Port Değişimi
- **Sorun**: Flutter web her çalıştırmada farklı bir portta açıldı (örneğin, 53571, 49823), bu da CORS ayarlarını sürekli güncellemeyi gerektirdi.
- **Deneme**:
  - Sabit port (`--web-port=53571`) ile çalıştırma denendi.
  - `SetIsOriginAllowed` ile dinamik port kabulü eklendi.
- **Çözüm**: Sabit port kullanımı veya dinamik `localhost` kabulü ile sorun hafifletildi.

## Ancak Flutter'dan AirlineticketingSystem API bağlantısı başarısız oldu.
