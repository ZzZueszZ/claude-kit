---
description: Checklist review code theo conventions của dự án DigiPost
---

## 1. Kiến trúc & Package Structure
- [ ] Code core nằm trong `tech.app.*`, feature mở rộng nằm trong `tech.features.*`
- [ ] Feature module có `{FeatureName}ModuleLoader.java` với `@Conditional`
- [ ] Tuân thủ CQRS: tách `CommandService` (write) và `QueryService` (read)
- [ ] Domain object không phụ thuộc vào infrastructure layer

## 2. Controller Layer
- [ ] Sử dụng `@RestController` với versioned path (`/api/v1/...`)
- [ ] Tách controller: singular (`{Name}V1Controller`) cho single resource, plural (`{Name}sV1Controller`) cho collection
- [ ] Dùng MapStruct mapper để convert DTO ↔ Domain
- [ ] Không có business logic trong controller

## 3. Service Layer
- [ ] UseCase interface định nghĩa trong domain layer
- [ ] Implementation trong service layer
- [ ] Transaction management đúng cách
- [ ] Error handling với ErrorCode constants

## 4. Repository Layer
- [ ] JPA repository cho Oracle DB
- [ ] MongoDB repository cho document store
- [ ] Feign client cho REST inter-service calls
- [ ] gRPC client cho high-performance inter-service calls

## 5. Coding Conventions
- [ ] Lombok: `@Data`, `@Builder`, `@Slf4j`, `@RequiredArgsConstructor`
- [ ] MapStruct: dùng cho DTO mapping, không manual mapping
- [ ] Java 17 features: record, sealed class, pattern matching (nếu phù hợp)
- [ ] Không hardcode giá trị — dùng constants hoặc config

## 6. Database & Migration
- [ ] Migration file đúng format: `V{YYYYMMDD}_{seq}__{type}_{description}.sql`
- [ ] Oracle SQL syntax (VARCHAR2, NUMBER, CLOB, TIMESTAMP)
- [ ] Index cho các cột hay query
- [ ] Constraint naming convention

## 7. Security & Best Practices
- [ ] Không log sensitive data (password, token, personal info)
- [ ] Input validation
- [ ] Không có TODO/FIXME còn sót
- [ ] Checkstyle passed: `./gradlew checkstyleMain`
