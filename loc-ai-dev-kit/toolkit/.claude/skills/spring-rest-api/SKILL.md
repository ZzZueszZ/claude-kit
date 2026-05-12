---
name: Spring REST API Design
description: Hướng dẫn thiết kế RESTful API chuẩn trong Spring Boot - Controller, DTO, Response patterns, Pagination
---

# Spring REST API Design

Chuẩn hóa thiết kế RESTful API trong Spring Boot.

---

## 1. RESTful URL Conventions

### Quy tắc bắt buộc
- URL dùng **noun** (danh từ), KHÔNG dùng verb (động từ)
- URL dùng **lowercase** và **kebab-case** cho multi-word
- Collection dùng **plural** nouns
- Versioning qua URL prefix: `/api/v1/...`

### URL patterns chuẩn

| Method | URL | Mô tả |
|--------|-----|--------|
| `GET` | `/api/v1/users` | Lấy danh sách users |
| `GET` | `/api/v1/users/{id}` | Lấy user theo ID |
| `POST` | `/api/v1/users` | Tạo user mới |
| `PUT` | `/api/v1/users/{id}` | Cập nhật toàn bộ user |
| `PATCH` | `/api/v1/users/{id}` | Cập nhật một phần user |
| `DELETE` | `/api/v1/users/{id}` | Xóa user |
| `GET` | `/api/v1/users/{id}/orders` | Lấy orders của user |

### ✅ Đúng
```
GET    /api/v1/users
GET    /api/v1/users/123
POST   /api/v1/users
GET    /api/v1/users/123/orders
GET    /api/v1/order-items
```

### ❌ Sai
```
GET    /api/v1/getUsers           ❌ verb trong URL
POST   /api/v1/createUser         ❌ verb trong URL
GET    /api/v1/user               ❌ singular
GET    /api/v1/Users              ❌ uppercase
GET    /api/v1/order_items        ❌ snake_case
```

---

## 2. Controller Pattern

### Quy tắc bắt buộc
- Controller chỉ handle **HTTP concerns** (request/response)
- **KHÔNG** chứa business logic
- **LUÔN** dùng `ResponseEntity<T>` cho response
- **LUÔN** dùng `@Valid` cho request validation
- Dùng **proper HTTP status codes**

### Template chuẩn
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "User Management", description = "APIs for managing users")
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<UserResponse>>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {
        Page<UserResponse> users = userService.getUsers(
            PageRequest.of(page, size, Sort.by(parseSortOrders(sort)))
        );
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(userService.getUser(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        UserResponse user = userService.createUser(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(user.id()).toUri();
        return ResponseEntity.created(location).body(ApiResponse.success(user));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(ApiResponse.success(userService.updateUser(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
```

---

## 3. HTTP Status Codes

### Status codes bắt buộc sử dụng đúng

| Status | Khi nào dùng |
|--------|-------------|
| `200 OK` | GET, PUT, PATCH thành công |
| `201 Created` | POST tạo resource thành công |
| `204 No Content` | DELETE thành công |
| `400 Bad Request` | Validation error, request không hợp lệ |
| `401 Unauthorized` | Chưa authenticate |
| `403 Forbidden` | Không có quyền |
| `404 Not Found` | Resource không tồn tại |
| `409 Conflict` | Duplicate resource (email đã tồn tại) |
| `422 Unprocessable Entity` | Business rule violation |
| `500 Internal Server Error` | Lỗi server không mong đợi |

### ❌ KHÔNG dùng
```java
return ResponseEntity.ok(null);                    // ❌ Trả 200 khi không tìm thấy
return ResponseEntity.status(200).body(error);     // ❌ Trả 200 cho error
return ResponseEntity.status(500).body("Not found"); // ❌ 500 cho 404
```

---

## 4. DTO Pattern

### Quy tắc bắt buộc
- **LUÔN** tách Request DTO và Response DTO
- **KHÔNG** expose Entity ra ngoài Controller
- Dùng **Java Records** cho DTOs (Java 16+)
- Validation annotations đặt trên **Request DTO**

### Request DTO
```java
public record CreateUserRequest(
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be 3-50 characters")
    String username,

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email,

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$",
             message = "Password must contain uppercase, lowercase, and digit")
    String password
) {}

public record UpdateUserRequest(
    @Size(min = 3, max = 50)
    String username,

    @Email
    String email,

    String fullName
) {}
```

### Response DTO
```java
public record UserResponse(
    Long id,
    String username,
    String email,
    String fullName,
    List<String> roles,
    LocalDateTime createdAt
) {}

// Nested response
public record OrderResponse(
    Long id,
    BigDecimal total,
    OrderStatus status,
    UserSummaryResponse customer, // subset of UserResponse
    List<OrderItemResponse> items,
    LocalDateTime createdAt
) {}

public record UserSummaryResponse(Long id, String username, String email) {}
```

---

## 5. API Response Wrapper

### Standard response format
```java
@Getter
@Builder
public class ApiResponse<T> {
    private final boolean success;
    private final String message;
    private final T data;
    private final LocalDateTime timestamp;

    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message("Success")
                .data(data)
                .timestamp(LocalDateTime.now())
                .build();
    }

    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(LocalDateTime.now())
                .build();
    }

    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
    }
}
```

### JSON response format
```json
{
    "success": true,
    "message": "Success",
    "data": {
        "id": 1,
        "username": "john_doe",
        "email": "john@example.com"
    },
    "timestamp": "2024-01-15T10:30:00"
}
```

---

## 6. Object Mapping (Entity ↔ DTO)

### Sử dụng MapStruct (ƯU TIÊN)
```java
@Mapper(componentModel = "spring")
public interface UserMapper {
    UserResponse toResponse(User entity);
    List<UserResponse> toResponseList(List<User> entities);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "password", ignore = true)
    User toEntity(CreateUserRequest request);
}
```

### Hoặc manual mapper
```java
@Component
public class UserMapper {
    public UserResponse toResponse(User user) {
        return new UserResponse(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            user.getFullName(),
            user.getRoles().stream().map(Role::getName).toList(),
            user.getCreatedAt()
        );
    }

    public User toEntity(CreateUserRequest request) {
        User user = new User();
        user.setUsername(request.username());
        user.setEmail(request.email());
        return user;
    }
}
```

### ❌ KHÔNG mapping trong Controller hoặc Service trực tiếp
```java
// ❌ Mapping logic trong controller
@GetMapping("/{id}")
public ResponseEntity<?> getUser(@PathVariable Long id) {
    User user = userRepository.findById(id).orElseThrow();
    Map<String, Object> response = new HashMap<>();
    response.put("id", user.getId());           // ❌ Manual mapping
    response.put("name", user.getUsername());     // ❌ trong controller
    return ResponseEntity.ok(response);
}
```

---

## 7. Pagination & Sorting

### Template chuẩn
```java
// Controller
@GetMapping
public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getUsers(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String search) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
    Page<UserResponse> users = userService.searchUsers(search, pageable);
    return ResponseEntity.ok(ApiResponse.success(PageResponse.of(users)));
}

// PageResponse wrapper
public record PageResponse<T>(
    List<T> content,
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean first,
    boolean last
) {
    public static <T> PageResponse<T> of(Page<T> page) {
        return new PageResponse<>(
            page.getContent(),
            page.getNumber(),
            page.getSize(),
            page.getTotalElements(),
            page.getTotalPages(),
            page.isFirst(),
            page.isLast()
        );
    }
}
```

---

## Checklist trước khi commit

- [ ] URL chuẩn RESTful: plural noun, kebab-case, versioned
- [ ] HTTP status codes đúng cho từng operation
- [ ] Request/Response DTO tách riêng, dùng Java Records
- [ ] Entity KHÔNG expose ra ngoài API
- [ ] Validation trên Request DTO (`@Valid`, `@NotBlank`, etc.)
- [ ] ApiResponse wrapper cho tất cả responses
- [ ] Mapper riêng (MapStruct hoặc manual), không mapping trong Controller
- [ ] Pagination/Sorting support cho list endpoints
