# PrivateLesson — Ürün, Mimari ve Ajan Çalışma Sözleşmesi

- Belge sürümü: 1.0
- Tarih: 29 Ekim 2026
- Proje: `privatelesson`
- Kullanıcının yerel proje yolu: `~/Masaüstü/flutter_projects/privatelesson`
- Geliştirme ortamı: Linux / Pop!_OS; VS Code ve Antigravity panelleri
- Belgenin amacı: Codex geliştirmesine ve Antigravity denetimine ortak referans sağlamak.
- Durum: Gereksinim belgesidir; özelliklerin uygulandığını, test edildiğini veya ajan bağlantısının kurulduğunu göstermez.

## 1. Kararların statüsü ve kullanımı

Bu belgedeki “zorunlu” kurallar kullanıcı tarafından belirtilen veya açıkça kabul edilen kararlardır. “Öneri” ve “karar bekliyor” ifadeleri ürün kapsamına kendiliğinden eklenmez. Uygulama örnekleri dosya ve sınıf adlandırmasına rehberdir; mevcut proje incelenmeden toplu yeniden yazım yapılmaz.

Geliştirmeden önce mevcut `AGENTS.md` ve alt klasör talimatları okunur. Bu belgeyle çelişen talimatlar kullanıcıya bildirilir. Bu dosya proje kökünde tutulabilir; ajanların okuduğundan emin olmak için oturum başında açıkça referans verilir. `AGENTS.md` içinden bu belgeye yönlendirme yapılması önerilir. Belge tek başına işletim sistemi veya araç izinlerini değiştirmez.

## 2. Ürünün amacı

PrivateLesson, özel ders veren öğretmenlerle öğrenciler arasında sanal bir köprü kuran Flutter tabanlı bir aracı platformdur. Öğretmenler ders ilanı yayınlar, öğrenciler ilanları arar ve filtreleyerek uygun öğretmenlere ulaşır. Dersin kendisi platform üzerinde gerçekleştirilmez.

### 2.1 İlk sürüm kapsamı

- Öğrenci ve öğretmen hesabıyla kayıt ve giriş.
- Google hesabıyla giriş/kayıt; paket tercihi `google_sign_in`.
- Başlangıçta Firebase Authentication kullanımı.
- Öğretmen tarafından ders ilanı eklenmesi.
- Öğrenci tarafından ilan arama, filtreleme ve detay görüntüleme.
- Öğretmen adı, ders açıklaması, yetkinlik belgesi bilgisi ve eğitim biçiminin sunulması.
- Yüz yüze, online ve önceden kaydedilmiş video eğitim biçimleri.
- Öğretmenin seçimine göre WhatsApp numarası, e-posta veya her ikisi üzerinden dış iletişim.
- Türkçe ve İngilizce arayüz.

### 2.2 İlk sürümde bulunmayacaklar

- Uygulama içi chat / mesajlaşma.
- Platform içinde canlı ders veya video konferans.
- Platform içinde bant video oynatma/eğitim sunma sistemi.

Ödeme, rezervasyon, takvim, puanlama, yorumlar, favoriler, bildirimler ve yönetici paneli kararlaştırılmış kapsam değildir. Kullanıcı istemeden geliştirilmez.

## 3. Roller ve kullanıcı akışları

### 3.1 Öğrenci

1. Kayıt olur veya hesabına giriş yapar.
2. Ders ilanlarını listeler.
3. Arama ve filtreleme ile uygun ilanları bulur.
4. İlan detayında öğretmen, ders, eğitim biçimi ve belge bilgilerini görür.
5. Öğretmenin paylaştığı iletişim yöntemini kullanarak platform dışına geçer.

### 3.2 Öğretmen

1. Öğretmen hesabıyla kayıt olur veya giriş yapar.
2. Ders ilanı için gerekli bilgileri girer.
3. Eğitim biçimini belirtir.
4. Yetkinlik belgesi olup olmadığını ve varsa ilgili bilgiyi belirtir.
5. WhatsApp numarası, e-posta veya her ikisini paylaşmayı seçer.
6. İlanı ekler.

İlan düzenleme, silme, yayından kaldırma ve taslak yönetimi önerilen tamamlayıcı işlevlerdir; kapsamları henüz onaylanmamıştır.

### 3.3 Google ile kimlik doğrulama

- Google girişini başlatan arayüz Cubit üzerinden ilgili use case'i çağırır.
- Google ve Firebase SDK işlemleri data katmanında kapsüllenir.
- Domain katmanına SDK kullanıcı, token veya credential sınıfları taşınmaz.
- İlk Google girişinden sonra rol ve eksik profil bilgilerini tamamlama akışı önerilen başlangıç davranışıdır.
- Sonraki girişlerde kayıtlı profil ve rol kullanılmalıdır; her girişte rol yeniden seçtirilmemelidir.
- İptal, bağlantı hatası, kimlik doğrulama hatası ve profil yükleme hatası ayrı ele alınır.
- Oturumun açılmasıyla profilin tamamlanması ayrı durumlardır.
- Google e-postası öğretmenin ilan iletişim adresi olarak otomatik yayınlanmaz.
- Hedef platformlar ve Firebase/Google konsol ayarları uygulama öncesinde doğrulanır; eksik ayarlar varmış gibi kabul edilmez.

## 4. İlan bilgileri ve arama

### 4.1 Kesinleşmiş bilgi grupları

| Bilgi | Beklenen anlam |
|---|---|
| Öğretmen | İlanın sahibi ve görünen öğretmen adı |
| Ders konusu | Eğitimin ne hakkında olduğu |
| Açıklama | Ders ve eğitim hakkında bilgiler |
| Yetkinlik belgesi | Var/yok bilgisi; varsa belgenin ne olduğu |
| Eğitim biçimi | Yüz yüze, online veya önceden kaydedilmiş video |
| İletişim | Öğretmenin seçtiği WhatsApp ve/veya e-posta |

Belge sunulması, platform tarafından doğrulanmış belge anlamına gelmez. Doğrulama süreci tanımlanmadan “doğrulanmış öğretmen/belge” etiketi gösterilmez.

### 4.2 Önerilen arama ve filtre sözleşmesi

- Ders konusu ve öğretmen adına göre metin araması.
- Eğitim biçimine göre filtre.
- Belge bilgisi bulunmasına göre filtre.
- Yüz yüze ders için şehir/ilçe filtresi: konum alanları onaylanırsa.
- Liste yükleniyor, sonuç yok, hata ve yeniden dene durumları.
- Etkin filtrelerin görünmesi ve temizlenebilmesi.

Kesin filtreler, sıralama, sayfalama ve aramanın backend tarafında nasıl çalışacağı karar beklemektedir. Fiyat, ders seviyesi, süre ve konum alanları kullanıcı kararı olmadan zorunlu veri alanı yapılmaz.

## 5. Platform dışı iletişim

### 5.1 Kesinleşmiş tercihler

Öğretmen WhatsApp için telefon numarası veya e-posta bırakabilir; isterse ikisini birden kullanabilir. Yalnızca seçilen ve doldurulan yöntemlerin butonları gösterilir.

### 5.2 Önerilen yayınlama ve doğrulama kuralları

- Yayınlanacak ilanda en az bir iletişim yöntemi bulunmalıdır.
- Telefon ülke koduyla alınmalı ve tutarlı biçimde saklanmalıdır.
- E-posta biçimi doğrulanmalıdır.
- Öğretmene iletişim bilgilerinin ilanda paylaşılacağı açıkça gösterilmelidir.
- Harici uygulama açılamadığında anlaşılır hata ve kopyalama seçeneği sunulmalıdır.
- Uygulama içi rotalar `go_router`; harici WhatsApp/e-posta açılışı ayrı dış bağlantı servisi üzerinden yönetilmelidir.
- Kimlik doğrulama e-postası ile ilan iletişim e-postası farklı amaçlı alanlar olarak ele alınmalıdır.

İletişim bilgilerinin yalnızca giriş yapan öğrencilere mi yoksa herkese mi gösterileceği henüz kararlaştırılmamıştır.

## 6. Clean Architecture

### 6.1 Zorunlu temel düzen

```text
lib/
  core/
  features/
    feature_name/
      data/
        datasources/
        dtos/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        cubit/
        pages/
        widgets/
```

### 6.2 Domain

- Entity'ler, repository arayüzleri ve use case'ler burada bulunur.
- Entity'ler iş kavramlarını temsil eder; JSON dönüşümü içermez.
- Entity'lerde `json_serializable` veya JSON amaçlı `*.g.dart` bulunmaz.
- Firebase, Google SDK, Flutter widget, HTTP istemcisi ve datasource bağımlılığı bulunmaz.
- Repository arayüzü sağlayıcıya özgü cevap yerine domain türleri döndürür.
- İş kuralları widget içinde dağınık biçimde uygulanmaz.

### 6.3 Data

- Datasource'lar dış servis, veritabanı veya diğer veri kaynaklarıyla iletişim kurar.
- DTO'lar JSON/servis veri formatını temsil eder; `json_serializable` ve üretilen `*.g.dart` burada kullanılır.
- Repository implementation sınıfları domain repository arayüzlerini uygular.
- DTO → entity dönüşümü data sınırında yapılır. Entity → DTO dönüşümü gerektiğinde yine burada bulunur.
- Sağlayıcı istisnaları kontrollü uygulama/domain hata türlerine dönüştürülür.
- Firebase ve Google sağlayıcı ayrıntıları presentation katmanına sızmaz.

### 6.4 Presentation

- Cubit, state, page ve feature'a ait widget'lar bulunur.
- Sayfalar use case veya repository'ye doğrudan erişmek yerine Cubit ile etkileşir.
- Cubit, use case aracılığıyla işlem başlatır.
- Sayfalar kısa, okunabilir ve küçük sorumluluklara ayrılmış olmalıdır.
- Form, yüklenme, hata ve sonuç durumları Cubit/state ile yönetilir.
- `setState()` yasaktır.

### 6.5 Core

Ortak tema, boyutlar, asset sabitleri, lokalizasyon erişimi, routing, hata altyapısı, dependency injection ve gerçekten ortak widget'lar burada bulunabilir. Yalnızca tek feature'a ait bileşenler core'a taşınmaz.

### 6.6 Veri ve çağrı akışı

```text
Page/Widget → Cubit → UseCase → Domain Repository arayüzü
                                      ↑ uygular
                                RepositoryImpl → DataSource → Dış servis

Dış servis verisi → DTO → Entity → Cubit State → Page/Widget
```

## 7. Backend değiştirilebilirliği

Hedef, veri sağlayıcısı değiştiğinde domain ve presentation'ın değişmeden kalmasıdır. Başlangıç kimlik doğrulama sağlayıcısı Firebase'dir. İlanlar ve profiller için depolama sağlayıcısı henüz seçilmemiştir; Firebase Authentication kararı otomatik olarak Firestore kararı değildir.

- Kimlik doğrulama ve ilan veri erişimi için ayrı sözleşmeler oluşturulur.
- Somut sağlayıcı seçimi merkezi dependency injection/composition noktasında yapılır.
- Backend seçimi kontrolü sayfalara veya Cubit'lere dağıtılmaz.
- Alternatif backend için değiştirilebilir sözleşme hazırlanır.
- Endpoint ve API sözleşmesi bilinmeden çalışan bir alternatif backend varmış gibi davranılmaz.
- Sağlayıcı aynı datasource sözleşmesine uyarlanabiliyorsa değişiklik datasource ve bağlantı yapılandırmasıyla sınırlanabilir.
- Veri formatı farklıysa DTO, mapper veya repository implementation uyarlaması gerekebilir. “Her koşulda yalnızca tek datasource dosyası değişir” garantisi verilmez.

## 8. Zorunlu kod standartları

| Kimlik | Kural |
|---|---|
| ARCH-01 | Feature tabanlı Clean Architecture kullanılacak. |
| ARCH-02 | DTO ve JSON dönüşümleri data; entity ve repository arayüzleri domain katmanında olacak. |
| STATE-01 | Cubit kullanılacak; `setState()` yazılmayacak. |
| STYLE-01 | `..` cascade operatörü kullanılmayacak; null-aware cascade `?..` da aynı yasağa dahildir. |
| ANALYSIS-01 | Analiz kuralları `very_good_analysis` üzerinden tanımlanacak. |
| UI-01 | Ortak bileşenler `AppButton` gibi yeniden kullanılabilir widget'lara çıkarılacak. |
| UI-02 | Tema `theme.dart` üzerinden merkezi yönetilecek. |
| UI-03 | Tasarım sayıları, sabit metinler ve görsel yolları widget içine gömülmeyecek. |
| I18N-01 | `easy_localization` ile Türkçe ve İngilizce desteklenecek. |
| I18N-02 | Lokalizasyon erişimi `TextUtils` üzerinden yapılacak. |
| ROUTE-01 | Uygulama içi navigasyon yalnızca `go_router` üzerinden yapılacak. |
| CONFIG-01 | `.env` oluşturulacak ve `.gitignore` içine alınacak. |

`very_good_analysis`, statik analizi kaldırmak değil, kullanılacak analiz kural setini belirlemek anlamındadır. Proje kuralları için gereken ek kontroller ayrıca tasarlanabilir; standart analiz paketinin tüm özel yasakları kendiliğinden denetlediği varsayılmaz.

### 8.1 Sabitler ve tema

- Boyutlar: `AppDimensions.md`, `AppDimensions.lg` gibi anlamlı adlar.
- Görsel yolları: `AppAssets`.
- Teknik sabitler: amacına göre küçük sabit sınıfları.
- Renk, tipografi, buton ve giriş alanı stilleri: merkezi tema.
- Çevrilebilir kullanıcı metinleri: lokalizasyon; genel sabit sınıfına Türkçe metin koymak çözüm değildir.
- Kullanıcı tarafından girilen ilan açıklamaları sabit veya arayüz çevirisi değildir.
- Sabitlerin tanımlandığı yerde literal değer olması doğaldır; amaç kullanım yerlerinde tekrar ve belirsiz değerlerden kaçınmaktır.
- Üretilen dosyalar elle değiştirilmez. Kod üreticisinin proje kuralıyla çelişmesi durumunda sessiz istisna tanımlanmaz; uyumsuzluk raporlanır.

### 8.2 Lokalizasyon

Önerilen dosyalar: `assets/translations/tr.json`, `assets/translations/en.json`, `lib/core/localization/text_utils.dart`.

- Her yeni arayüz metni iki dilde eklenir.
- Sayfalarda doğrudan metin, çeviri anahtarı veya dağınık `.tr()` çağrıları kullanılmaz.
- `TextUtils`, anahtarları ve çeviri erişimini tutarlı bir arayüzde toplar.
- Çevrilmiş sonuçlar statik başlangıç değerlerine dondurulmaz; dil değişikliği ekrana yansır.
- Hata, doğrulama, yüklenme, boş liste, erişilebilirlik ve buton metinleri de kapsam içindedir.
- Değişkenli metinlerde parametreli çeviri kullanılır.
- Kullanıcı ilanlarının otomatik çevirisi kapsamda değildir.

### 8.3 Routing

- Merkezi `AppRouter` ve rota ad/yol tanımları kullanılır.
- Elle `Navigator.push`, `Navigator.pop` veya `MaterialPageRoute` ile alternatif navigasyon kurulmaz.
- Oturum ve profil durumuna bağlı yönlendirmeler merkezi değerlendirilir.
- Role göre ekran erişimi gerekir; yalnızca buton gizlemek veri erişim yetkilendirmesinin yerine geçmez.

## 9. Önerilen proje ağacı

```text
PROJECT_SPEC.md
AGENTS.md                       # Ayrı, kısa ajan giriş belgesi önerisi
.env                            # Yerel, takip edilmez
.env.example                    # Gerçek değer içermez
.gitignore
analysis_options.yaml
pubspec.yaml
assets/
  translations/
    tr.json
    en.json
lib/
  main.dart
  app.dart
  core/
    constants/
      app_dimensions.dart
      app_assets.dart
      app_constants.dart
    theme/theme.dart
    localization/text_utils.dart
    routing/
      app_router.dart
      app_routes.dart
    widgets/
      app_button.dart
      app_text_field.dart
    error/
    di/
  features/
    auth/
      data/
        datasources/
          auth_data_source.dart
          firebase_auth_data_source.dart
        dtos/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        cubit/
        pages/
        widgets/
    lesson_listings/
      data/
        datasources/
        dtos/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        cubit/
        pages/
        widgets/
test/
integration_test/
```

Bu ağaç hedef yerleşim önerisidir; mevcut dosyaların taşınması veya silinmesi için tek başına talimat değildir. Profilin ayrı feature olması ihtiyaç incelendikten sonra kararlaştırılır.

## 10. Konfigürasyon ve Git

- Mevcut `.gitignore` varsa korunur ve eksikleri tamamlanır.
- `.env` ve yerel ortam varyantları takip dışına alınır; `.env.example` gerçek değer olmadan takip edilebilir.
- `.env` değişkenlerini yükleme yöntemi henüz seçilmemiştir.
- Flutter paketine dahil edilen ortam değerleri gizli tutulmuş sayılmaz. Servis hesabı anahtarı, özel anahtar ve sunucu sırrı istemciye konmaz.
- Firebase istemci ayarlarıyla sunucu kimlik bilgileri birbirine karıştırılmaz.
- Bir dosyayı `.gitignore` içine almak daha önce takip edilmiş içeriği geçmişten silmez; mevcut Git durumu kontrol edilir.
- Kullanıcı değişiklikleri üzerine yazılmaz; görev kapsamı dışındaki dosyalar değiştirilmez.
- Otomatik commit, push, deployment ve veri silme bu belgeyle yetkilendirilmez.

## 11. Ajan rolleri

### 11.1 Antigravity — Denetleyici ve tester

- Görevi gereksinim ve kabul kriterlerine ayırır.
- Codex'in değişikliklerini inceler, ihlalleri dosya ve gerekçeyle bildirir.
- Test senaryolarını tarif eder; mevcut testleri ve onaylı doğrulama komutlarını çalıştırır.
- Uygulama kodu, test kodu, yapılandırma veya düzeltme kodu yazmaz/değiştirmez.
- Eksik testi kendisi yazmaz; Codex'ten ister.
- Hataları kendisi düzeltmez; Codex'e iletir.
- Başarılı sonucu kanıtlarıyla kabul eder veya eksikleri raporlar.
- İnceleme raporu oluşturabilir. Ayrı rapor klasörüne yazma izni teknik kurulumda tanımlanmalıdır.

### 11.2 Codex — Kodlayıcı

- Uygulama, test ve gerekli proje yapılandırma kodlarını yazar.
- Bu belgeye ve kullanıcının talimatlarına uyar.
- Denetleyicinin kapsam içindeki bulgularını düzeltir.
- Çelişkili veya kapsam dışı talepleri kullanıcıya bildirir.
- Yaptığı değişiklikleri ve çalıştırdığı kontrolleri raporlar.
- Çalıştırılmamış testleri başarılı göstermez.
- Antigravity adına onay vermez; inceleme bulgularını izinsiz kapatmaz.

### 11.3 Teknik yetki sınırları

Prompt içinde “kod yazma” demek gerçek yazma yetkisini kaldırmaz. Kesin ayrım için kaynak erişimi, komut yetkileri ve araç sınırları ayrı yapılandırılmalıdır. Aynı Linux kullanıcısıyla sınırsız terminal erişimi olan iki ajan yalnızca rol metniyle güvenilir biçimde ayrılmış sayılmaz.

Testler derleme çıktısı ve önbellek oluşturabilir. Kaynak dosyaları koruyan, test çıktıları için ayrı yazılabilir alan sağlayan bir çalışma ortamı tasarlanmalıdır. Denetleyicinin kaynak dosyalarına yazma girişimi reddedilmeli; test ve rapor üretimi çalışmalıdır.

Mevcut bilgi: Codex CLI ChatGPT hesabıyla açılmıştır; Antigravity paneli mevcuttur. İki ajan arasında otomatik görev aktarımı ve teknik yazma yasağının kurulduğu henüz doğrulanmamıştır. Aynı editörde sekmelerin bulunması bağlantı kurulduğu anlamına gelmez.

## 12. Görev ve inceleme protokolü

### 12.1 Görev kaydı

Her görev şu bilgileri içermelidir:

- Görev kimliği ve amaç.
- İlgili gereksinim/kural kimlikleri.
- İzin verilen değişiklik kapsamı.
- Kabul kriterleri ve gerekli testler.
- Açık sorular/bağımlılıklar.

### 12.2 Codex teslimi

- Değişen dosyalar ve davranış özeti.
- Kullanılan mimari yaklaşım.
- Çalıştırılan komutlar ve gerçek sonuçları.
- Çalıştırılamayan kontroller ve nedeni.
- Bilinen eksikler.

### 12.3 Antigravity incelemesi

Her bulgu: bulgu kimliği, önem, dosya/konum, ihlal edilen kural, gözlenen davranış, beklenen davranış, yeniden üretim adımları ve gerekli düzeltme ölçütünü içerir. Kod düzeltmesi eklenmez.

Karar durumları: `ACCEPTED`, `CHANGES_REQUESTED`, `BLOCKED`.

Akış: görev → Codex geliştirmesi → Antigravity inceleme/test → gerekirse Codex düzeltmesi → tekrar inceleme.

Öneri: Üç başarısız düzeltme turundan sonra kullanıcıya engel raporu sunulsun. Tur sınırı otomasyon kurulurken onaylanmalıdır.

## 13. Test ve kabul kriterleri

Aşağıdaki kontroller planlanan kabul ölçütleridir; şu anda başarıyla tamamlanmış değildir.

| Kimlik | Kabul ölçütü |
|---|---|
| AUTH-01 | Öğrenci ve öğretmen kayıt/giriş akışları ayrı rolü doğru korur. |
| AUTH-02 | Google girişinde başarı, iptal ve hata durumları ele alınır. |
| AUTH-03 | Profil tamamlanmadan yanlış role ait ekrana yönlendirme yapılmaz. |
| LIST-01 | Öğretmen gerekli alanlarla ilan ekleyebilir. |
| LIST-02 | Öğrenci arama/filtreleme ve detay görüntülemeyi kullanabilir. |
| LIST-03 | Liste için yüklenme, hata, boş ve başarılı durumlar bulunur. |
| CONTACT-01 | WhatsApp, e-posta ve ikisinin birlikte seçildiği durumlar doğru gösterilir. |
| CONTACT-02 | Kimlik doğrulama e-postası izinsiz iletişim adresi olmaz. |
| I18N-03 | Türkçe/İngilizce anahtarları eşleşir; dil değişimi ekrana yansır. |
| ARCH-03 | Domain sağlayıcı SDK'larından bağımsızdır. |
| ARCH-04 | Cubit ve sayfalar somut veri kaynağına erişmez. |
| STYLE-02 | Kaynak kodunda cascade ve setState ihlali yoktur. |
| ROUTE-02 | Uygulama içi geçişler go_router kullanır. |
| CONFIG-02 | Yerel .env takip edilmez; örnek dosyada gerçek sır yoktur. |
| AGENT-01 | Antigravity kaynak değiştiremez; Codex kapsam içinde değiştirebilir. |
| AGENT-02 | Otomatik bağlantı kurulursa görev, sonuç ve düzeltme kimlikleri izlenebilir. |

Önerilen test seviyeleri: DTO/entity dönüşümleri, repository hata eşlemesi, use case iş kuralları, Cubit durum geçişleri, kritik widget/form davranışları ve temel kullanıcı akışları.

Örnek doğrulama komutları, ortam hazırlandıktan sonra kullanılabilir:

```bash
flutter analyze
flutter test
# Dosyaları değiştirmeden biçim kontrolü:
dart format --output=none --set-exit-if-changed lib test
```

Eksik dizinler ve proje araç sürümleri incelenerek komut kapsamı uyarlanır. Antigravity otomatik düzeltme, kod üretimi veya dosyaya yazan biçimlendirme çalıştırmaz; bunları Codex yapar. Entegrasyon testi ve Google girişinin cihaz testi için hedef platform ve yapılandırma hazır olmalıdır.

## 14. Önerilen uygulama sırası

1. Mevcut projeyi, Git durumunu ve araç sürümlerini salt okunur incele.
2. Açık ürün kararlarını ve hedef platformları netleştir.
3. Belgeyi proje talimatlarına bağla; ajan iletişim ve izin mekanizmasını doğrula.
4. Mimari iskelet, analiz, tema, sabitler, ortak widget'lar, lokalizasyon ve routing temelini kur.
5. Auth sözleşmeleri, Firebase/Google veri katmanı ve rol/profil akışını geliştir.
6. Seçilen depolama sağlayıcısıyla ilan oluşturma/listeleme/arama/detay akışlarını geliştir.
7. WhatsApp/e-posta dış iletişimini ekle.
8. Her aşamada Codex teslimi, Antigravity incelemesi ve gerekli testleri tamamla.

Her aşama küçük ve incelenebilir değişikliklerle ilerler; tüm uygulama tek görevde yeniden yazılmaz.

## 15. Karar bekleyen konular

- Hedefler: Android, iOS, web, Linux masaüstü seçeneklerinden hangileri?
- Google dışında giriş: e-posta/şifre mi, başka yöntem mi?
- Rol seçiminin kesin ekran akışı; bir hesabın birden fazla rolü olabilir mi?
- Profil ve ilan verilerinin saklanacağı backend/veritabanı.
- İlanların zorunlu alanları; fiyat, süre, seviye ve konum kullanımı.
- Kesin arama filtreleri, sıralama ve sayfalama.
- Bir ilanın birden fazla eğitim biçimi içerebilmesi.
- Belge bilgisinin metin, dosya veya bağlantı biçiminde tutulması ve doğrulama süreci.
- İlan düzenleme/silme/yayından kaldırma kapsamı.
- İletişim görünürlüğü ve en az bir yöntem zorunluluğunun son onayı.
- Varsayılan dil, dil tercihini saklama ve dil değiştirici konumu.
- Alternatif backend API sözleşmesi.
- Ajan bağlantısının MCP/başka araç üzerinden kurulma yöntemi ve teknik izolasyon.

Bu kararlar netleşmeden ajanlar eksik bilgileri kesinleşmiş ürün kararı gibi uygulamamalıdır. Bağımsız mimari ve belge çalışmaları sürdürülebilir.

## 16. Antigravity oturumundan alınan araç durumu

Kullanıcının ilettiği Antigravity yanıtına göre bu oturumda Codex'e özel görev gönderme aracı yoktur. Dosya okuma/yazma/düzenleme, komut çalıştırma, web araması, kullanıcıya soru sorma ve kendi altyapısında alt ajan başlatma araçları vardır. `self`, `research` ve `image-generator` alt ajanları Codex değildir.

Sonuçlar:

- Şu anda doğrudan otomatik Codex bağlantısı doğrulanmış değildir.
- Antigravity'nin dosya yazma/düzenleme araçları mevcut olduğundan kesin kod yazma yasağı henüz uygulanmamıştır.
- Komut çalıştırma yeteneği, Codex CLI'ı kontrollü bir araç üzerinden çağırma yaklaşımını araştırmak için kullanılabilir. Bu, mevcutta bağlantı olduğu anlamına gelmez.
- Bağlantı kurulana kadar görev ve inceleme sonuçları kullanıcı tarafından aktarılabilir; bu geçici yöntem otomatik ajan sistemi olarak sunulmaz.
- Bu durum ürün ve mimari gereksinimlerini değiştirmez.
