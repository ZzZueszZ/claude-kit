---
name: Java OOP Principles
description: Hướng dẫn tuân thủ 4 trụ cột lập trình hướng đối tượng trong Java - Encapsulation, Inheritance, Polymorphism, Abstraction
---

# Java OOP Principles

Khi viết code Java, **LUÔN** tuân thủ 4 nguyên tắc OOP dưới đây. Agent phải kiểm tra và đảm bảo mọi class, method đều đúng với các nguyên tắc này.

---

## 1. Encapsulation (Đóng gói)

### Quy tắc bắt buộc
- **LUÔN** đặt fields là `private`
- Chỉ expose qua getter/setter khi **thực sự cần thiết**
- **ƯU TIÊN** immutable objects (dùng `final` fields)
- **KHÔNG** expose internal collections trực tiếp — trả về unmodifiable copy

### ✅ Đúng
```java
public class User {
    private final String username;
    private final String email;
    private final List<Role> roles;

    public User(String username, String email, List<Role> roles) {
        this.username = username;
        this.email = email;
        this.roles = List.copyOf(roles); // defensive copy
    }

    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public List<Role> getRoles() { return Collections.unmodifiableList(roles); }
}
```

### ❌ Sai
```java
public class User {
    public String username;    // ❌ public field
    public List<Role> roles;   // ❌ expose mutable collection

    public List<Role> getRoles() {
        return roles;           // ❌ return mutable reference
    }
}
```

### Khi nào KHÔNG cần getter/setter
- **DTO/Record**: Dùng Java Records cho data transfer objects
- **Builder pattern internal fields**: không cần getter cho builder fields

```java
// Dùng Record cho DTO
public record UserResponse(String username, String email, List<String> roles) {}
```

---

## 2. Inheritance (Kế thừa)

### Quy tắc bắt buộc
- **ƯU TIÊN Composition over Inheritance** — chỉ dùng inheritance khi có quan hệ IS-A rõ ràng
- **LUÔN** đánh dấu class là `final` nếu không thiết kế để kế thừa
- **KHÔNG** kế thừa quá 2 cấp (trừ framework classes)
- Sử dụng `@Override` annotation khi override method

### ✅ Đúng — Composition
```java
// ƯU TIÊN: Composition
public class OrderService {
    private final PaymentProcessor paymentProcessor;
    private final NotificationService notificationService;

    public OrderService(PaymentProcessor paymentProcessor,
                        NotificationService notificationService) {
        this.paymentProcessor = paymentProcessor;
        this.notificationService = notificationService;
    }

    public Order processOrder(Order order) {
        paymentProcessor.process(order.getPayment());
        notificationService.notify(order.getCustomer());
        return order;
    }
}
```

### ❌ Sai — Inheritance lạm dụng
```java
// ❌ Dùng inheritance chỉ để reuse code
public class OrderService extends PaymentProcessor {
    // OrderService IS NOT A PaymentProcessor!
}
```

### Khi nào NÊN dùng Inheritance
- Template Method pattern (abstract base class)
- Framework contracts (extends `WebSecurityConfigurerAdapter`)
- Shared state + behavior giữa các subclass liên quan chặt chẽ

---

## 3. Polymorphism (Đa hình)

### Quy tắc bắt buộc
- **ƯU TIÊN** interface-based polymorphism
- **LUÔN** program to interface, not implementation
- Dependency injection nên dùng interface type
- Tránh `instanceof` checks — dùng polymorphism thay thế

### ✅ Đúng
```java
// Interface
public interface NotificationSender {
    void send(String recipient, String message);
}

// Implementations
@Service("emailSender")
public class EmailNotificationSender implements NotificationSender {
    @Override
    public void send(String recipient, String message) {
        // send email
    }
}

@Service("smsSender")
public class SmsNotificationSender implements NotificationSender {
    @Override
    public void send(String recipient, String message) {
        // send SMS
    }
}

// Usage — depend on interface
@Service
public class OrderNotificationService {
    private final NotificationSender sender;

    public OrderNotificationService(@Qualifier("emailSender") NotificationSender sender) {
        this.sender = sender;
    }
}
```

### ❌ Sai — instanceof checks
```java
// ❌ Anti-pattern: type checking thay vì polymorphism
public void sendNotification(Object sender, String msg) {
    if (sender instanceof EmailSender) {
        ((EmailSender) sender).sendEmail(msg);
    } else if (sender instanceof SmsSender) {
        ((SmsSender) sender).sendSms(msg);
    }
    // ❌ Phải sửa method này mỗi khi thêm sender mới
}
```

---

## 4. Abstraction (Trừu tượng)

### Quy tắc bắt buộc
- **Abstract class** khi có shared state/behavior giữa các subclass
- **Interface** khi chỉ định nghĩa contract (behavior)
- **LUÔN** giữ abstraction ở đúng level — không quá chi tiết, không quá chung
- Dùng **sealed classes/interfaces** (Java 17+) khi biết trước tập hợp implementations

### Khi nào dùng Abstract Class vs Interface

| Tiêu chí | Abstract Class | Interface |
|--------|---------------|-----------|
| Shared state (fields) | ✅ Có | ❌ Không (chỉ constants) |
| Default method impl | ✅ Có | ✅ Có (từ Java 8) |
| Constructor | ✅ Có | ❌ Không |
| Multiple inheritance | ❌ Chỉ 1 | ✅ Nhiều |
| Khi nào dùng | IS-A + shared code | CAN-DO contract |

### ✅ Đúng
```java
// Abstract class — shared state + behavior
public abstract class BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    // Getters — shared across all entities
    public Long getId() { return id; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

// Interface — contract only
public interface Auditable {
    String getCreatedBy();
    String getModifiedBy();
}

// Sealed interface (Java 17+) — known set of implementations
public sealed interface Shape permits Circle, Rectangle, Triangle {
    double area();
}
```

---

## Checklist trước khi commit

- [ ] Tất cả fields đều `private` (trừ constants `public static final`)
- [ ] Không expose mutable collections
- [ ] Không dùng inheritance chỉ để reuse code
- [ ] Sử dụng interface cho DI (dependency injection)
- [ ] Không có `instanceof` checks thay cho polymorphism
- [ ] Abstract class có shared state, Interface chỉ có contract
- [ ] Java Records được dùng cho DTOs khi phù hợp
