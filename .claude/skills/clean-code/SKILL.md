---
name: Clean Code Principles
description: Hướng dẫn tuân thủ KISS, DRY, YAGNI và các nguyên tắc Clean Code trong Java
---

# Clean Code Principles

Các nguyên tắc **BẮT BUỘC** tuân thủ khi viết code Java để đảm bảo code sạch, dễ đọc, dễ bảo trì.

---

## 1. KISS — Keep It Simple, Stupid

> Code đơn giản nhất có thể mà vẫn đáp ứng yêu cầu.

### Quy tắc bắt buộc
- **KHÔNG** over-engineer — chỉ giải quyết bài toán hiện tại
- **KHÔNG** dùng design pattern khi if/else đơn giản là đủ
- **ƯU TIÊN** readability hơn cleverness
- **TRÁNH** nested conditions quá 3 cấp — extract method

### ✅ Đúng
```java
public boolean isEligibleForDiscount(User user) {
    return user.isPremium() && user.getOrderCount() > 10;
}
```

### ❌ Sai — Over-engineered
```java
// ❌ Tạo strategy pattern cho logic đơn giản
public interface EligibilityChecker {
    boolean check(User user);
}

public class PremiumChecker implements EligibilityChecker { ... }
public class OrderCountChecker implements EligibilityChecker { ... }

public class CompositeEligibilityChecker {
    private final List<EligibilityChecker> checkers;
    // ❌ Quá phức tạp cho 1 condition đơn giản
}
```

### Khi NÊN dùng pattern phức tạp hơn
- Khi có **>3 variations** của cùng logic
- Khi logic cần **mở rộng** thường xuyên
- Khi cần **test riêng** từng phần logic

---

## 2. DRY — Don't Repeat Yourself

> Mỗi knowledge chỉ có **MỘT representation** duy nhất trong hệ thống.

### Quy tắc bắt buộc
- **KHÔNG** copy-paste code — extract thành method/class chung
- **KHÔNG** duplicate business rules — centralize trong 1 nơi
- **KHÔNG** hardcode cùng giá trị ở nhiều nơi — dùng constants/config
- **CẨN THẬN**: DRY áp dụng cho **knowledge**, không phải ngẫu nhiên code giống nhau

### ✅ Đúng — Extract common logic
```java
// Constants tập trung
public final class AppConstants {
    public static final int MAX_LOGIN_ATTEMPTS = 5;
    public static final int TOKEN_EXPIRY_HOURS = 24;

    private AppConstants() {} // prevent instantiation
}

// Common validation extracted
@Component
public class UserValidator {
    public void validateEmail(String email) {
        if (!EMAIL_PATTERN.matcher(email).matches()) {
            throw new InvalidEmailException(email);
        }
    }

    public void validatePassword(String password) {
        if (password.length() < 8) {
            throw new WeakPasswordException("Minimum 8 characters");
        }
    }
}
```

### ❌ Sai — Duplicate logic
```java
// ❌ Cùng validation logic ở 2 service khác nhau
public class RegistrationService {
    public void register(String email) {
        if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) { // ❌ Duplicate
            throw new RuntimeException("Invalid email");
        }
    }
}

public class ProfileService {
    public void updateEmail(String email) {
        if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) { // ❌ Duplicate
            throw new RuntimeException("Invalid email");
        }
    }
}
```

### ⚠️ Khi KHÔNG nên DRY
- 2 đoạn code trông giống nhau nhưng thuộc **2 domain khác nhau**
- Extract quá sớm tạo ra **coupling không cần thiết**
- Rule: Nếu thay đổi 1 chỗ **không** ảnh hưởng chỗ kia → KHÔNG extract

---

## 3. YAGNI — You Ain't Gonna Need It

> KHÔNG viết code cho feature chưa có yêu cầu.

### Quy tắc bắt buộc
- **KHÔNG** tạo abstract class/interface khi chỉ có 1 implementation
- **KHÔNG** thêm fields/methods "phòng khi cần sau này"
- **KHÔNG** tạo generic solution khi chỉ cần specific solution
- **CHỈ** code khi có **yêu cầu cụ thể** từ user hoặc requirements

### ✅ Đúng — Đủ dùng
```java
// Chỉ có 1 implementation → không cần interface
@Service
public class UserService {
    public UserResponse getUser(Long id) {
        return userMapper.toResponse(
            userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id))
        );
    }
}
```

### ❌ Sai — Premature abstraction
```java
// ❌ Tạo interface khi chỉ có 1 implementation
public interface UserService { ... }
public interface UserServiceV2 extends UserService { ... } // ❌ "phòng khi cần v2"

// ❌ Thêm methods chưa dùng
public class User {
    private String middleName;     // ❌ Chưa có yêu cầu
    private String nickname;       // ❌ Chưa có yêu cầu
    private String secondaryEmail; // ❌ Chưa có yêu cầu
}
```

### Ngoại lệ cho YAGNI
- Interface cho **dependency injection** trong Spring (khi cần mock trong test)
- Base entity cho **audit fields** (createdAt, updatedAt)
- Standard patterns mà Spring Boot **recommend**

---

## 4. Naming Conventions

### Quy tắc bắt buộc

| Loại | Convention | Ví dụ |
|------|-----------|-------|
| Class | PascalCase, noun | `UserService`, `OrderController` |
| Method | camelCase, verb | `createUser()`, `findByEmail()` |
| Variable | camelCase, meaningful | `currentUser`, `orderTotal` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE` |
| Package | lowercase | `com.company.module` |
| Boolean | is/has/can prefix | `isActive`, `hasPermission` |
| Collection | plural noun | `users`, `orderItems` |

### Quy tắc đặt tên
- **KHÔNG** viết tắt — `usr` → `user`, `mgr` → `manager`
- **KHÔNG** dùng tên generic — `data`, `info`, `temp`, `obj`
- **KHÔNG** đặt tên theo type — `userList` → `users`, `nameString` → `name`
- Method name phải **mô tả** chức năng — `process()` → `processPayment()`

### ✅ Đúng
```java
public Optional<User> findActiveUserByEmail(String email) { ... }
public boolean hasPermission(User user, Permission permission) { ... }
public List<Order> getRecentOrders(Long userId, int limit) { ... }
```

### ❌ Sai
```java
public Object getData(String s) { ... }      // ❌ Tên generic
public User proc(String e) { ... }           // ❌ Tên viết tắt
public void doStuff(List<?> lst) { ... }     // ❌ Không rõ ý nghĩa
```

---

## 5. Method & Class Guidelines

### Method
- **Tối đa 20 dòng** — nếu dài hơn, extract sub-methods
- **Tối đa 3 parameters** — nếu nhiều hơn, dùng parameter object
- **Một method = Một việc** — tách nếu làm nhiều việc
- **KHÔNG** dùng boolean parameter — tách thành 2 methods

### ✅ Đúng
```java
// Parameter object thay vì nhiều params
public record CreateUserRequest(
    String username,
    String email,
    String password,
    String fullName
) {}

public UserResponse createUser(CreateUserRequest request) {
    validateRequest(request);
    User user = buildUser(request);
    User savedUser = userRepository.save(user);
    sendWelcomeEmail(savedUser);
    return userMapper.toResponse(savedUser);
}
```

### ❌ Sai
```java
// ❌ Quá nhiều params
public User createUser(String username, String email, String password,
                       String firstName, String lastName, String phone,
                       boolean sendEmail, boolean isAdmin) { ... }

// ❌ Boolean parameter
public List<User> getUsers(boolean includeInactive) { ... }
// Nên tách: getActiveUsers() và getAllUsers()
```

### Class
- **Tối đa 200 dòng** — nếu dài hơn, cần tách class
- **Tối đa 5 dependencies** inject — nếu nhiều hơn, class đang làm quá nhiều việc
- Mỗi class phải có **tên rõ ràng** mô tả responsibility

---

## 6. Comments

### Quy tắc bắt buộc
- **Code tự giải thích** — nếu cần comment thì code chưa đủ rõ
- Comment **WHY**, không comment **WHAT**
- **Javadoc** cho public API methods
- **KHÔNG** commit code đã comment-out — dùng git

### ✅ Đúng
```java
/**
 * Calculates discount based on user tier and order history.
 * Premium users get 10% off after their 10th order.
 */
public BigDecimal calculateDiscount(User user, Order order) {
    // Business rule: Premium discount only applies after grace period
    if (user.getRegistrationDate().plusDays(30).isAfter(LocalDate.now())) {
        return BigDecimal.ZERO;
    }
    return applyTierDiscount(user.getTier(), order.getSubtotal());
}
```

### ❌ Sai
```java
// ❌ Comment what, not why
// Get user by id
public User getUserById(Long id) { ... }

// ❌ Commented-out code
// public void oldMethod() { ... }

// ❌ Obsolete comment
// This method returns a list of users (thực tế return Page<User>)
public Page<User> getUsers(Pageable pageable) { ... }
```

---

## Checklist trước khi commit

- [ ] Không có over-engineering (KISS)
- [ ] Không có duplicate logic (DRY)
- [ ] Không có code cho feature chưa yêu cầu (YAGNI)
- [ ] Naming conventions đúng chuẩn
- [ ] Methods ≤ 20 dòng, ≤ 3 params
- [ ] Classes ≤ 200 dòng, ≤ 5 dependencies
- [ ] Không có commented-out code
- [ ] Comments giải thích WHY, không phải WHAT
