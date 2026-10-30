# AGENTS.md

Bu proje için bağlayıcı sözleşme [PROJECT_SPEC.md](PROJECT_SPEC.md) dosyasıdır. Göreve başlamadan önce tamamını oku. Bu dosya ile çelişen talimatları kullanıcıya bildir.

## Roller

- **Codex:** Uygulama, test ve proje yapılandırma kodunu yazar; teslim raporunda çalıştırdığı komutları ve gerçek sonuçlarını bildirir.
- **Antigravity:** Denetler ve test eder; kod yazmaz, bulguları dosya ve kural kimliğiyle raporlar.
- Çalıştırılmamış testi başarılı gösterme. Kararı belirsiz konuları (spec bölüm 15) kesinleşmiş gibi uygulama.

## Zorunlu kurallar (özet)

- ARCH-01/02: Feature tabanlı Clean Architecture; DTO/JSON data'da, entity ve repository arayüzü domain'de.
- STATE-01: Cubit; `setState()` yok.
- STYLE-01: `..` ve `?..` cascade yok.
- ANALYSIS-01: Kurallar `very_good_analysis` ile.
- UI-01/02/03: Ortak widget'lar, merkezi `theme.dart`; widget içinde sabit sayı, metin veya asset yolu yok.
- I18N-01/02: `easy_localization` (tr/en); erişim yalnızca `TextUtils` üzerinden.
- ROUTE-01: Navigasyon yalnızca `go_router`.
- CONFIG-01: `.env` git dışında; `.env.example` gerçek değer içermez.

## Mevcut karar

- Hedef platformlar: Android ve iOS.
- Git commit, push, deployment ve veri silme yetkilendirilmemiştir.

