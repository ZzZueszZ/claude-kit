---
name: Code Review & Source Analysis
description: Hướng dẫn review code Java và phân tích mã nguồn theo tiêu chuẩn chất lượng
---

# Code Review & Source Analysis

Hướng dẫn **review code** và **phân tích mã nguồn** Java cho dự án Spring Boot, đảm bảo chất lượng, bảo mật và hiệu năng.

---

## 1. Quy trình Review Code

### 1.1. Checklist tổng quan

| Bước | Nội dung kiểm tra | Mức ưu tiên |
|------|--------------------|------------|
| 1 | Logic nghiệp vụ đúng | 🔴 Critical |
| 2 | Bảo mật (SQL Injection, XSS, Auth) | 🔴 Critical |
| 3 | Xử lý Exception | 🔴 Critical |
| 4 | Performance & Query N+1 | 🟡 High |
| 5 | Naming & Code style | 🟢 Medium |
| 6 | Unit test coverage | 🟡 High |
| 7 | Documentation & Javadoc | 🟢 Medium |

### 1.2. Mức severity

- **🔴 Critical**: Phải fix ngay — lỗi logic, lỗ hổng bảo mật, mất data
- **🟡 High**: Nên fix — performance, thiếu validation, thiếu test
- **🟢 Medium**: Fix khi có thời gian — naming, code style, refactor
- **⚪ Low**: Suggestion — cải thiện readability, optional refactor

---

## 2. Review Logic Nghiệp vụ

### Checklist bắt buộc
- [ ] Logic xử lý đúng theo requirement
- [ ] Xử lý hết các edge cases (null, empty, boundary)
- [ ] Không có race condition trong concurrent access
- [ ] Transaction boundary đúng
- [ ] Idempotency cho API cần (POST, PUT)

### ✅ Đúng — Xử lý đầy đủ
```java
@Transactional
public OrderResponse createOrder(CreateOrderRequest request) {
    // 1. Validate input
    validateOrderRequest(request);

    // 2. Check business rules
    User user = userRepository.findById(request.getUserId())
        .orElseThrow(() -> new UserNotFoundException(request.getUserId()));

    if (!user.isActive()) {
        throw new BusinessException("User is not active");
    }

    // 3. Check stock availability BEFORE creating order
    List<OrderItem> items = request.getItems().stream()
        .map(item -> {
            Product product = productRepository.findByIdWithLock(item.getProductId())
                .orElseThrow(() -> new ProductNotFoundException(item.getProductId()));

            if (product.getStock() < item.getQuantity()) {
                throw new InsufficientStockException(product.getName());
            }
            product.decreaseStock(item.getQuantity());
            return OrderItem.of(product, item.getQuantity());
        })
        .toList();

    // 4. Create order
    Order order = Order.create(user, items);
    return orderMapper.toResponse(orderRepository.save(order));
}
```

### ❌ Sai — Thiếu xử lý
```java
// ❌ Không validate, không check stock, không transaction
public Order createOrder(CreateOrderRequest request) {
    User user = userRepository.getById(request.getUserId()); // ❌ No null check
    Order order = new Order();
    order.setUser(user);
    order.setItems(request.getItems()); // ❌ No stock check
    return orderRepository.save(order);
}
```

---

## 3. Review Bảo mật

### 3.1. SQL Injection

```java
// ❌ CRITICAL — SQL Injection
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// ✅ Đúng — Parameterized query
@Query("SELECT u FROM User u WHERE u.name = :name")
List<User> findByName(@Param("name") String name);
```

### 3.2. XSS Prevention

```java
// ❌ CRITICAL — Trả raw HTML từ user input
return ResponseEntity.ok(userInput);

// ✅ Đúng — Escape HTML
import org.apache.commons.text.StringEscapeUtils;
String safe = StringEscapeUtils.escapeHtml4(userInput);
```

### 3.3. Authentication & Authorization

```java
// ❌ CRITICAL — Không kiểm tra quyền
@GetMapping("/admin/users")
public List<User> getAllUsers() { ... }

// ✅ Đúng — Check authority
@PreAuthorize("hasRole('ADMIN')")
@GetMapping("/admin/users")
public List<User> getAllUsers() { ... }
```

### 3.4. Sensitive Data

```java
// ❌ Log sensitive data
log.info("User login: {}, password: {}", username, password);

// ✅ Đúng — Mask sensitive data
log.info("User login: {}", username);
// KHÔNG log password, token, credit card
```

### Checklist bảo mật
- [ ] Không có SQL injection (dùng parameterized queries)
- [ ] Input validation đầy đủ (`@Valid`, `@NotNull`, `@Size`)
- [ ] Output encoding (XSS prevention)
- [ ] Authentication/Authorization đúng endpoint
- [ ] Không log sensitive data (password, token, PII)
- [ ] CORS configuration đúng
- [ ] Rate limiting cho API public
- [ ] File upload validation (type, size)

---

## 4. Review Exception Handling

### Quy tắc bắt buộc
- **KHÔNG** catch generic `Exception` — catch specific exception
- **KHÔNG** swallow exception (catch rồi không làm gì)
- **LUÔN** có GlobalExceptionHandler
- **LUÔN** trả error response chuẩn format

### ✅ Đúng
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusiness(BusinessException ex) {
        log.warn("Business error: {}", ex.getMessage());
        return ResponseEntity.badRequest()
            .body(ErrorResponse.of(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse.of("NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex); // Log full stack trace
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ErrorResponse.of("INTERNAL_ERROR", "Lỗi hệ thống"));
    }
}
```

### ❌ Sai
```java
// ❌ Catch generic + swallow
try {
    doSomething();
} catch (Exception e) {
    // EMPTY — swallowed!
}

// ❌ Trả String thay vì ErrorResponse chuẩn
@ExceptionHandler(Exception.class)
public String handleError(Exception e) {
    return e.getMessage(); // ❌ Lộ internal message
}
```

---

## 5. Review Performance

### 5.1. N+1 Query Problem

```java
// ❌ N+1 — Mỗi order sẽ query thêm user
List<Order> orders = orderRepository.findAll();
orders.forEach(o -> System.out.println(o.getUser().getName())); // N queries!

// ✅ Đúng — JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.user")
List<Order> findAllWithUser();

// ✅ Hoặc dùng @EntityGraph
@EntityGraph(attributePaths = {"user", "items"})
List<Order> findAll();
```

### 5.2. Pagination

```java
// ❌ Load tất cả rồi cắt
List<User> all = userRepository.findAll();
return all.subList(0, 10); // ❌ Load hết DB vào memory

// ✅ Đúng — Query có LIMIT
Page<User> findByStatus(UserStatus status, Pageable pageable);
```

### 5.3. Caching

```java
// ✅ Cache cho data ít thay đổi
@Cacheable(value = "categories", key = "#id")
public Category findById(Long id) {
    return categoryRepository.findById(id)
        .orElseThrow(() -> new NotFoundException(id));
}

@CacheEvict(value = "categories", key = "#id")
public void update(Long id, CategoryRequest request) { ... }
```

### Checklist performance
- [ ] Không có N+1 query (dùng JOIN FETCH hoặc @EntityGraph)
- [ ] Có pagination cho list API
- [ ] Dùng `@Cacheable` cho data ít thay đổi
- [ ] Index trên các columns thường dùng trong WHERE/ORDER BY
- [ ] Không load toàn bộ entity khi chỉ cần vài fields (dùng projection)
- [ ] Bulk operations thay vì loop single

---

## 6. Review Code Style & Structure

### 6.1. Layer Architecture

```
Controller → Service → Repository
     ↓          ↓          ↓
   DTO/Request  Domain     Entity
```

| Layer | Trách nhiệm | Không được |
|-------|-------------|-----------|
| Controller | Nhận request, validate, trả response | Chứa business logic |
| Service | Business logic, transaction | Query database trực tiếp |
| Repository | Data access, queries | Chứa business logic |

### 6.2. Kiểm tra cấu trúc

- [ ] Controller KHÔNG chứa business logic
- [ ] Service KHÔNG inject HttpServletRequest
- [ ] Repository KHÔNG throw business exception
- [ ] DTO riêng cho Request/Response, KHÔNG dùng Entity làm DTO
- [ ] Mapper class riêng (MapStruct hoặc manual)

### 6.3. Method size

| Metric | Giới hạn | Action |
|--------|---------|--------|
| Method lines | ≤ 20 dòng | Extract sub-methods |
| Method params | ≤ 3 params | Dùng Request object |
| Class lines | ≤ 200 dòng | Tách class |
| Inject dependencies | ≤ 5 | Tách service |
| Cyclomatic complexity | ≤ 10 | Simplify logic |

---

## 7. Review Lombok & Entity Encapsulation

> Tham khảo: [Why Setters are Bad Practice](https://www.reddit.com/r/learnprogramming/comments/yco016/are_getters_and_setters_a_bad_pratice/)

### Quy tắc bắt buộc — 🔴 Critical
- **KHÔNG** dùng `@Data` trong Entity — sinh `@Setter`, `toString()`, `equals()` sai
- **KHÔNG** dùng `@Setter` trong Entity — phá vỡ encapsulation
- **CHỈ** dùng `@Getter`, `@Builder`, `@NoArgsConstructor(access = PROTECTED)`
- Thay đổi state qua **domain methods** có ý nghĩa nghiệp vụ
- Dùng `protected setId()` cho infrastructure layer (repository adapter)

### ✅ Đúng
```java
@Entity
@Getter // ✅ Chỉ @Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class Product extends BaseEntity {

    private String name;

    @Enumerated(EnumType.STRING)
    private ProductStatus status;

    private BigDecimal price;

    // ✅ Domain method — có ý nghĩa nghiệp vụ
    public void activate() {
        this.status = ProductStatus.ACTIVE;
    }

    public void updatePrice(BigDecimal newPrice) {
        if (newPrice.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("Price must be positive");
        }
        this.price = newPrice;
    }
}
```

### ❌ Sai
```java
// ❌ CRITICAL — @Data sinh setter cho tất cả fields
@Data
@Entity
public class Product {
    private String name;
    private BigDecimal price;
    // Bất kỳ class nào cũng gọi: product.setPrice(BigDecimal.ZERO)
}

// ❌ CRITICAL — @Setter phá vỡ encapsulation
@Getter
@Setter
@Entity
public class Product {
    private ProductStatus status;
    // Không validate, không business logic khi thay đổi status
}
```

### Ngoại lệ
- `@ConfigurationProperties` class — Spring **CẦN** `@Setter` để binding
- DTO / Request / Response class — có thể dùng `@Data` hoặc `record`

### Checklist Lombok
- [ ] Entity KHÔNG có `@Data`
- [ ] Entity KHÔNG có `@Setter`
- [ ] State changes qua domain methods (`updateStatus()`, `activate()`)
- [ ] Base entity có `protected setId()` cho infrastructure adapter
- [ ] Embeddable/ID class dùng `@Getter` + `@EqualsAndHashCode`, KHÔNG `@Data`

---

## 8. Review Transaction & Concurrency

### 8.1. Transaction

```java
// ✅ Đúng — @Transactional ở Service layer
@Service
public class OrderService {
    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request) {
        // All DB operations in one transaction
    }

    @Transactional(readOnly = true) // Optimize for read-only
    public OrderResponse getOrder(Long id) { ... }
}
```

### 8.2. Optimistic Locking

```java
@Entity
public class Product {
    @Version
    private Integer version; // Optimistic lock

    public void decreaseStock(int quantity) {
        if (this.stock < quantity) {
            throw new InsufficientStockException(this.name);
        }
        this.stock -= quantity;
    }
}
```

### Checklist transaction
- [ ] `@Transactional` ở Service layer, KHÔNG ở Controller
- [ ] `readOnly = true` cho query methods
- [ ] Không gọi external API trong transaction
- [ ] Dùng `@Version` cho concurrent update
- [ ] Không nested transaction (trừ khi cần `REQUIRES_NEW`)

---

## 9. Review Unit Test

### Quy tắc test
- [ ] Mỗi public method có ít nhất 1 test case
- [ ] Test cả happy path và error path
- [ ] Test boundary values
- [ ] Mock external dependencies
- [ ] Không test private methods trực tiếp
- [ ] Test name mô tả scenario: `should_returnUser_when_validId`

### ✅ Đúng
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock private UserRepository userRepository;
    @Mock private UserMapper userMapper;
    @InjectMocks private UserService userService;

    @Test
    void should_returnUser_when_validId() {
        // Given
        User user = createTestUser(1L, "john");
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userMapper.toResponse(user)).thenReturn(new UserResponse(1L, "john"));

        // When
        UserResponse result = userService.getUser(1L);

        // Then
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getName()).isEqualTo("john");
        verify(userRepository).findById(1L);
    }

    @Test
    void should_throwException_when_userNotFound() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(UserNotFoundException.class,
            () -> userService.getUser(99L));
    }
}
```

---

## 10. Phân tích Mã nguồn (Source Analysis)

### 10.1. Metrics cần đánh giá

| Metric | Công cụ | Ngưỡng tốt |
|--------|--------|-----------|
| Code coverage | JaCoCo | ≥ 80% |
| Cyclomatic complexity | SonarQube | ≤ 10 per method |
| Duplicate code | SonarQube | ≤ 3% |
| Technical debt | SonarQube | ≤ 5 days |
| Dependency count | Manual | ≤ 5 per class |

### 10.2. Static Analysis Rules

```
🔴 Bug — Logic errors, null pointers, resource leaks
🟡 Vulnerability — Security issues, injection, auth bypass
🔵 Code Smell — Naming, complexity, duplication
⚪ Debt — Deprecated API, missing docs
```

### 10.3. Dependency Analysis

Kiểm tra:
- [ ] Không có circular dependency giữa các module
- [ ] Dependency direction: Controller → Service → Repository (không ngược lại)
- [ ] Không import từ `internal` packages của library
- [ ] Version mới nhất cho các dependency security-critical

### 10.4. API Contract Analysis

```java
// ✅ API contract rõ ràng
@Operation(summary = "Tạo user mới")
@ApiResponses({
    @ApiResponse(responseCode = "201", description = "Tạo thành công"),
    @ApiResponse(responseCode = "400", description = "Dữ liệu không hợp lệ"),
    @ApiResponse(responseCode = "409", description = "Email đã tồn tại")
})
@PostMapping("/users")
public ResponseEntity<UserResponse> createUser(
    @Valid @RequestBody CreateUserRequest request) { ... }
```

---

## 11. Template báo cáo Review

### Format báo cáo

```markdown
# Code Review Report — [Tên module/PR]

## Tổng quan
- **Reviewer**: [Tên]
- **Ngày review**: [Date]
- **Files reviewed**: [Count]
- **Verdict**: ✅ Approved / ⚠️ Cần sửa / ❌ Reject

## Findings

### 🔴 Critical
1. [File:Line] — Mô tả issue
   - **Impact**: [Ảnh hưởng]
   - **Suggestion**: [Cách fix]

### 🟡 High
1. [File:Line] — Mô tả issue

### 🟢 Medium
1. [File:Line] — Mô tả issue

## Summary
- Critical: X issues
- High: Y issues
- Medium: Z issues
- Total: N issues
```

---

## Checklist tổng hợp trước khi approve

- [ ] **Logic**: Đúng requirement, xử lý edge cases
- [ ] **Bảo mật**: Không SQL injection, XSS, đủ auth
- [ ] **Exception**: Không swallow, có error response chuẩn
- [ ] **Performance**: Không N+1, có pagination, có cache
- [ ] **Code style**: Naming chuẩn, method ≤ 20 dòng
- [ ] **Architecture**: Đúng layer, không vi phạm dependency direction
- [ ] **Lombok**: Entity KHÔNG dùng `@Data`/`@Setter`, state changes qua domain methods
- [ ] **Transaction**: Đúng scope, readOnly cho reads
- [ ] **Test**: Coverage ≥ 80%, test cả error path
- [ ] **API**: Contract rõ ràng, validation đầy đủ
