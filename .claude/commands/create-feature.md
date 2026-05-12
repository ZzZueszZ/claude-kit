---
description: Quy trình tạo feature mới trong microservice (business/citizen/government/notification/signature)
---

## Bước 1: Xác nhận yêu cầu
- Hỏi rõ feature cần tạo thuộc **service nào** (business-post, citizen-post, government-post, notification, digital-signature)
- Xác nhận tên module/feature (ví dụ: `folder`, `label`, `sms`)
- Xác nhận các entity, field, API cần thiết

## Bước 2: Tạo ModuleLoader (nếu là feature mới trong `tech.features`)
- Tạo file `{FeatureName}ModuleLoader.java` trong package `tech.features.{featureName}/`
- Sử dụng `@Configuration`, `@ComponentScan`, `@Conditional` với `PropertyCondition`
- Module được enable qua config `app.module.exts` chứa tên module
- Tham khảo mẫu: `tech.features.folder.FolderModuleLoader`

## Bước 3: Tạo Domain layer
- Package: `tech.features.{featureName}/domain/{entityName}/`
- Tạo các file:
  - `{EntityName}.java` — Entity chính (dùng Lombok `@Data/@Builder/@NoArgsConstructor/@AllArgsConstructor`)
  - `{EntityName}Id.java` — Value Object cho ID (nếu cần)
  - `{EntityName}SearchCriteria.java` — Criteria cho tìm kiếm
  - `{EntityName}UseCaseService.java` — Interface UseCase (DDD style)
  - Enum/Constants nếu cần

## Bước 4: Tạo Repository layer
- Package: `tech.features.{featureName}/repository/`
- Tạo JPA repository hoặc MongoDB repository tuỳ loại data
- Tạo `Jpa{FeatureName}ModuleConfiguration.java` nếu dùng JPA

## Bước 5: Tạo Service layer (CQRS pattern)
- Package: `tech.features.{featureName}/service/{entityName}/`
- Tạo các file:
  - `{EntityName}CommandService.java` — Xử lý write operations (create/update/delete)
  - `{EntityName}QueryService.java` — Xử lý read operations (get/search/list)
  - `{EntityName}UseCaseServiceImpl.java` — Implement UseCase interface

## Bước 6: Tạo Controller layer
- Package: `tech.features.{featureName}/controller/api/v1/{entityName}/`
- Tạo các file theo pattern:
  - `{EntityName}V1Controller.java` — API cho single resource (GET/PUT/DELETE by ID)
  - `{EntityName}sV1Controller.java` — API cho collection (GET list, POST create)
- Sử dụng `@RestController`, `@RequestMapping("/api/v1/{entity-name}")`
- Dùng MapStruct mapper để convert giữa DTO và Domain

## Bước 7: Tạo Migration SQL
- Vào project migration tương ứng (cùng thư mục cha)
- Tạo file SQL trong `core/sql/oracle/`
- Naming: `V{YYYYMMDD}_{seq}__{type}_{description}.sql`
  - type: `ddl` (CREATE/ALTER TABLE), `dml` (INSERT/UPDATE data)
  - Ví dụ: `V20260316_01__ddl_create_table_example.sql`
- **KHÔNG tự động chạy migration**

## Bước 8: Kiểm tra
- Đảm bảo code compile thành công: `./gradlew compileJava` (trong thư mục admin-service)
- Kiểm tra checkstyle: `./gradlew checkstyleMain`
- Hỏi user trước khi chạy bất kỳ lệnh nào
