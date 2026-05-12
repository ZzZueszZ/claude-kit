---
name: SOLID Principles
description: Hướng dẫn tuân thủ 5 nguyên tắc SOLID trong Java Spring Boot - SRP, OCP, LSP, ISP, DIP
---

# SOLID Principles

5 nguyên tắc thiết kế hướng đối tượng **BẮT BUỘC** tuân thủ khi viết code Java Spring Boot.

---

## S — Single Responsibility Principle (SRP)

> Mỗi class chỉ có **MỘT lý do để thay đổi**.

### Quy tắc bắt buộc
- **MỖI class** chỉ đảm nhận **1 responsibility**
- Controller chỉ handle HTTP request/response
- Service chỉ chứa business logic
- Repository chỉ chứa data access logic
- **KHÔNG** mix business logic vào Controller
- **KHÔNG** mix data access vào Service

### ✅ Đúng
```java
// Controller — chỉ handle HTTP
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    @PostMapping
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(userService.createUser(request));
    }
}

// Service — chỉ business logic
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        validateUniqueEmail(request.email());
        User user = userMapper.toEntity(request);
        user.setPassword(passwordEncoder.encode(request.password()));
        return userMapper.toResponse(userRepository.save(user));
    }
}

// Repository — chỉ data access
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
```

### ❌ Sai — God Controller
```java
@RestController
public class UserController {
    @Autowired
    private JdbcTemplate jdbcTemplate; // ❌ Data access trong controller

    @PostMapping("/users")
    public User createUser(@RequestBody Map<String, Object> body) {
        // ❌ Validation trong controller
        if (body.get("email") == null) throw new RuntimeException("Email required");

        // ❌ Business logic trong controller
        String hashedPassword = BCrypt.hashpw((String) body.get("password"), BCrypt.gensalt());

        // ❌ Data access trong controller
        jdbcTemplate.update("INSERT INTO users ...", ...);

        // ❌ Tất cả trong 1 method = vi phạm SRP
        return new User(...);
    }
}
```

---

## O — Open/Closed Principle (OCP)

> Class phải **mở** cho extension, **đóng** cho modification.

### Quy tắc bắt buộc
- Dùng **Strategy pattern** hoặc **interface** để mở rộng behavior
- **KHÔNG** sửa code hiện tại khi thêm feature mới
- Sử dụng Spring `@Qualifier` hoặc `@ConditionalOn...` cho different implementations

### ✅ Đúng — Strategy Pattern
```java
// Interface — closed for modification
public interface PricingStrategy {
    BigDecimal calculatePrice(Order order);
}

// Open for extension — thêm strategy mới không sửa code cũ
@Component("standard")
public class StandardPricing implements PricingStrategy {
    @Override
    public BigDecimal calculatePrice(Order order) {
        return order.getSubtotal();
    }
}

@Component("premium")
public class PremiumPricing implements PricingStrategy {
    @Override
    public BigDecimal calculatePrice(Order order) {
        return order.getSubtotal().multiply(BigDecimal.valueOf(0.9)); // 10% discount
    }
}

// Service sử dụng — không cần sửa khi thêm strategy mới
@Service
public class OrderService {
    private final Map<String, PricingStrategy> strategies;

    public OrderService(Map<String, PricingStrategy> strategies) {
        this.strategies = strategies;
    }

    public BigDecimal calculatePrice(Order order, String pricingType) {
        return strategies.getOrDefault(pricingType,
                strategies.get("standard")).calculatePrice(order);
    }
}
```

### ❌ Sai — if/else chain
```java
// ❌ Phải sửa method này mỗi khi thêm pricing type mới
public BigDecimal calculatePrice(Order order, String type) {
    if ("standard".equals(type)) {
        return order.getSubtotal();
    } else if ("premium".equals(type)) {
        return order.getSubtotal().multiply(BigDecimal.valueOf(0.9));
    } else if ("vip".equals(type)) { // ❌ Phải thêm else-if
        return order.getSubtotal().multiply(BigDecimal.valueOf(0.8));
    }
    throw new IllegalArgumentException("Unknown type");
}
```

---

## L — Liskov Substitution Principle (LSP)

> Subclass phải **thay thế** được parent class mà không làm thay đổi behavior.

### Quy tắc bắt buộc
- Subclass **KHÔNG** được throw exception mà parent không throw
- Subclass **KHÔNG** được strengthen preconditions
- Subclass **KHÔNG** được weaken postconditions
- `@Override` methods phải giữ nguyên contract

### ✅ Đúng
```java
public abstract class PaymentMethod {
    public abstract PaymentResult process(BigDecimal amount);
    public abstract boolean supports(String currency);
}

public class CreditCardPayment extends PaymentMethod {
    @Override
    public PaymentResult process(BigDecimal amount) {
        // Process credit card — cùng contract
        return new PaymentResult(true, "CC-" + transactionId);
    }

    @Override
    public boolean supports(String currency) {
        return List.of("USD", "EUR", "VND").contains(currency);
    }
}

public class BankTransferPayment extends PaymentMethod {
    @Override
    public PaymentResult process(BigDecimal amount) {
        // Process bank transfer — cùng contract
        return new PaymentResult(true, "BT-" + transactionId);
    }

    @Override
    public boolean supports(String currency) {
        return List.of("VND").contains(currency);
    }
}
```

### ❌ Sai — Vi phạm LSP
```java
public class ReadOnlyRepository extends UserRepository {
    @Override
    public User save(User user) {
        throw new UnsupportedOperationException("Read only!"); // ❌ Vi phạm LSP
        // Code gọi UserRepository.save() sẽ bị crash
    }
}
```

---

## I — Interface Segregation Principle (ISP)

> **KHÔNG** ép client implement interface mà nó không dùng.

### Quy tắc bắt buộc
- Interface nhỏ, **chuyên biệt**
- Tách interface lớn thành nhiều interface nhỏ
- Class chỉ implement interfaces mà nó **thực sự cần**

### ✅ Đúng — Interface nhỏ
```java
// Tách thành các interface nhỏ, chuyên biệt
public interface Readable {
    byte[] read(String path);
}

public interface Writable {
    void write(String path, byte[] data);
}

public interface Deletable {
    void delete(String path);
}

// Class chỉ implement những gì cần
public class S3Storage implements Readable, Writable, Deletable {
    @Override public byte[] read(String path) { /* ... */ }
    @Override public void write(String path, byte[] data) { /* ... */ }
    @Override public void delete(String path) { /* ... */ }
}

public class CdnStorage implements Readable {
    @Override public byte[] read(String path) { /* ... */ }
    // Không cần implement write/delete
}
```

### ❌ Sai — Fat interface
```java
// ❌ Fat interface — ép mọi storage implement tất cả
public interface FileStorage {
    byte[] read(String path);
    void write(String path, byte[] data);
    void delete(String path);
    void move(String from, String to);
    void setPermissions(String path, Permission perm);
    List<String> listFiles(String directory);
}

// ❌ CdnStorage bị ép implement methods không cần
public class CdnStorage implements FileStorage {
    @Override public void delete(String path) {
        throw new UnsupportedOperationException(); // ❌
    }
    @Override public void move(String from, String to) {
        throw new UnsupportedOperationException(); // ❌
    }
    // ...
}
```

---

## D — Dependency Inversion Principle (DIP)

> High-level modules không depend on low-level modules. Cả hai depend on **abstractions**.

### Quy tắc bắt buộc
- **LUÔN** inject interface, KHÔNG inject concrete class
- Dùng Spring `@Autowired` / constructor injection với interface type
- High-level module (Service) không biết implementation details
- Configuration should select implementations

### ✅ Đúng
```java
// Abstraction
public interface EmailService {
    void sendEmail(String to, String subject, String body);
}

// Low-level implementation
@Service
@Profile("production")
public class SmtpEmailService implements EmailService {
    @Override
    public void sendEmail(String to, String subject, String body) {
        // Real SMTP sending
    }
}

@Service
@Profile("development")
public class MockEmailService implements EmailService {
    @Override
    public void sendEmail(String to, String subject, String body) {
        log.info("Mock email to {}: {}", to, subject); // Just log in dev
    }
}

// High-level module — depends on abstraction
@Service
@RequiredArgsConstructor
public class UserRegistrationService {
    private final EmailService emailService; // ✅ Interface, not implementation
    private final UserRepository userRepository;

    public void register(CreateUserRequest request) {
        User user = userRepository.save(mapToUser(request));
        emailService.sendEmail(user.getEmail(), "Welcome!", "...");
    }
}
```

### ❌ Sai — Depend on concrete class
```java
@Service
public class UserRegistrationService {
    private final SmtpEmailService emailService; // ❌ Concrete class

    public UserRegistrationService(SmtpEmailService emailService) {
        this.emailService = emailService; // ❌ Tightly coupled
    }
}
```

---

## Checklist trước khi commit

- [ ] Mỗi class chỉ có 1 responsibility (SRP)
- [ ] Thêm feature mới không sửa code cũ — dùng strategy/interface (OCP)
- [ ] Subclass thay thế được parent không lỗi (LSP)
- [ ] Interface nhỏ, chuyên biệt — không có methods thừa (ISP)
- [ ] Inject interface, không inject concrete class (DIP)
- [ ] Controller không chứa business logic
- [ ] Service không chứa data access logic trực tiếp
