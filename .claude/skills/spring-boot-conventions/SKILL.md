---
name: Spring Boot Conventions
description: Chuẩn hóa cấu trúc project Spring Boot - package structure, configuration, dependency injection, logging
---

# Spring Boot Conventions

Các convention **BẮT BUỘC** khi xây dựng ứng dụng Spring Boot.

---

## 1. Project Structure (Layered Architecture)

### Cấu trúc chuẩn
```
com.company.projectname/
├── config/                  # Configuration classes
│   ├── SecurityConfig.java
│   ├── WebConfig.java
│   └── SwaggerConfig.java
├── controller/              # REST Controllers
│   └── UserController.java
├── service/                 # Business logic
│   ├── UserService.java
│   └── impl/               # (Optional) Service implementations
│       └── UserServiceImpl.java
├── repository/              # Data access
│   └── UserRepository.java
├── model/                   # Domain models
│   ├── entity/              # JPA Entities
│   │   └── User.java
│   ├── dto/                 # Data Transfer Objects
│   │   ├── request/
│   │   │   └── CreateUserRequest.java
│   │   └── response/
│   │       └── UserResponse.java
│   └── enums/               # Enum types
│       └── UserRole.java
├── mapper/                  # Object mappers (Entity ↔ DTO)
│   └── UserMapper.java
├── exception/               # Custom exceptions
│   ├── GlobalExceptionHandler.java
│   ├── ResourceNotFoundException.java
│   └── BusinessException.java
├── security/                # Security components
│   ├── JwtTokenProvider.java
│   └── JwtAuthenticationFilter.java
├── util/                    # Utility classes
│   └── DateUtils.java
└── Application.java         # Main class
```

### Quy tắc bắt buộc
- **LUÔN** dùng layered architecture: Controller → Service → Repository
- Package name: `com.company.project.module`
- **KHÔNG** đặt tất cả class trong 1 package
- **KHÔNG** tạo package rỗng "phòng khi cần"
- Main class đặt ở **root package**

---

## 2. Configuration Management

### application.yml (ƯU TIÊN hơn .properties)
```yaml
# application.yml — base config
spring:
  application:
    name: auth-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

server:
  port: ${SERVER_PORT:8080}

# Custom properties — dùng prefix riêng
app:
  jwt:
    secret: ${JWT_SECRET}
    expiration: ${JWT_EXPIRATION:86400000}
  cors:
    allowed-origins: ${CORS_ORIGINS:http://localhost:3000}
```

### Quy tắc bắt buộc
- **LUÔN** dùng `${ENV_VAR:default}` cho sensitive values
- **KHÔNG** hardcode credentials trong config
- **TÁCH** config theo profile: `application-dev.yml`, `application-prod.yml`
- Dùng `@ConfigurationProperties` cho custom properties

### ✅ Đúng — @ConfigurationProperties
```java
@Configuration
@ConfigurationProperties(prefix = "app.jwt")
@Validated
public class JwtProperties {
    @NotBlank
    private String secret;

    @Positive
    private long expiration = 86400000L;

    // Getters, Setters
}
```

### ❌ Sai — @Value scattered
```java
// ❌ @Value rải rác trong nhiều class
@Service
public class AuthService {
    @Value("${app.jwt.secret}") private String secret;     // ❌
    @Value("${app.jwt.expiration}") private long exp;      // ❌
}

@Service
public class TokenService {
    @Value("${app.jwt.secret}") private String jwtSecret;  // ❌ Duplicate
}
```

---

## 3. Dependency Injection

### Quy tắc bắt buộc
- **LUÔN** dùng **Constructor Injection** (không dùng `@Autowired` trên field)
- Dùng `@RequiredArgsConstructor` (Lombok) để tự generate constructor
- Đánh dấu dependencies là `final`
- **KHÔNG** dùng field injection

### ✅ Đúng
```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;      // final
    private final PasswordEncoder passwordEncoder;    // final
    private final UserMapper userMapper;              // final
}
```

### ❌ Sai
```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;    // ❌ Field injection

    @Autowired
    private PasswordEncoder passwordEncoder;  // ❌ Field injection
}
```

---

## 4. Bean & Component Annotations

### Chọn đúng annotation

| Annotation | Khi nào dùng |
|-----------|-------------|
| `@Component` | Generic component |
| `@Service` | Business logic layer |
| `@Repository` | Data access layer |
| `@Controller` | MVC controller (trả về view) |
| `@RestController` | REST API controller (trả về JSON) |
| `@Configuration` | Configuration class chứa `@Bean` |
| `@Bean` | Factory method trong `@Configuration` |

### Quy tắc
- **KHÔNG** dùng `@Component` khi có annotation cụ thể hơn
- `@Service` cho tất cả service classes
- `@Repository` cho tất cả repository interfaces/classes

---

## 5. Logging

### Quy tắc bắt buộc
- Dùng **SLF4J** (`@Slf4j` Lombok hoặc `LoggerFactory`)
- **KHÔNG** dùng `System.out.println()`
- **KHÔNG** log sensitive data (password, tokens, PII)
- Dùng **parameterized messages** `{}`, không dùng string concatenation

### Log levels
| Level | Khi nào dùng |
|-------|-------------|
| `ERROR` | Lỗi nghiêm trọng cần xử lý ngay |
| `WARN` | Cảnh báo, có thể gây lỗi |
| `INFO` | Sự kiện business quan trọng |
| `DEBUG` | Chi tiết cho debugging |
| `TRACE` | Chi tiết rất sâu (hiếm dùng) |

### ✅ Đúng
```java
@Slf4j
@Service
public class UserService {
    public UserResponse createUser(CreateUserRequest request) {
        log.info("Creating user with email: {}", request.email());
        // ...
        log.debug("User created successfully: id={}", user.getId());
    }

    public void deleteUser(Long id) {
        log.warn("Deleting user: id={}", id);
    }
}
```

### ❌ Sai
```java
System.out.println("Creating user: " + request);              // ❌
log.info("User password is: " + request.getPassword());       // ❌ Log password
log.info("Creating user: " + request.getEmail());             // ❌ String concat
```

---

## 6. Lombok Usage

### Annotations nên dùng
```java
@Getter                    // Thay vì viết getter thủ công
@Setter                    // Chỉ khi cần set (entity)
@RequiredArgsConstructor   // Constructor injection
@Builder                   // Builder pattern cho complex objects
@Slf4j                     // Logger
@ToString(exclude = {"password"})  // Exclude sensitive fields
@EqualsAndHashCode(of = {"id"})    // Chỉ dùng id cho entity
```

### Quy tắc
- **KHÔNG** dùng `@Data` cho JPA entities (gây issues với `hashCode()`)
- **LUÔN** exclude sensitive fields trong `@ToString`
- Dùng `@Builder` cho objects có nhiều fields
- Dùng `@Value` (Lombok) cho immutable classes

---

## Checklist trước khi commit

- [ ] Project structure đúng layered architecture
- [ ] Config dùng `${ENV_VAR:default}` cho sensitive values
- [ ] Constructor injection, không field injection
- [ ] Annotations đúng: `@Service`, `@Repository`, `@RestController`
- [ ] Logging dùng SLF4J, parameterized messages
- [ ] Không có `System.out.println()`
- [ ] Không log sensitive data
