---
description: Quy trình build và chạy service tại local
---

## Bước 1: Xác nhận service cần chạy
- Xác nhận service nào cần build/run
- Đường dẫn admin-service:
  - `projects/digipost/business-post/admin-service/`
  - `projects/digipost/citizen-post/admin-service/`
  - `projects/digipost/government-post/admin-service/`
  - `projects/digipost/notification/notification-service/`
  - `projects/digipost/digital-signature/signature-service/`

## Bước 2: Kiểm tra prerequisites
- Java 17 đã cài đặt
- Gradle wrapper có sẵn trong project (`./gradlew`)
- Kiểm tra `gradle.properties` cho các config cần thiết:
  - `DEBUG_MICROSERVICE`, `DEBUG_KAFKA`, `DEBUG_ISC`, etc.
  - Mặc định tất cả = `false` (dùng published artifacts)
  - Set = `true` nếu muốn debug local module

## Bước 3: Build
// turbo
```bash
./gradlew clean build -x test
```

## Bước 4: Chạy test
```bash
./gradlew test
```

## Bước 5: Kiểm tra Checkstyle
// turbo
```bash
./gradlew checkstyleMain
```

## Lưu ý
- Nếu cần debug common module (kafka, isc, common-core), set flag `DEBUG_*=true` trong `gradle.properties` và đảm bảo module source có sẵn tại đường dẫn tương ứng trong `settings.gradle`
- Config kết nối DB, Kafka, etc. nằm trong `src/main/resources/application.yml` hoặc environment variables
