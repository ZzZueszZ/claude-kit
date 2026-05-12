---
name: Spring Exception Handling
description: Hướng dẫn xử lý exception chuẩn trong Spring Boot - GlobalExceptionHandler, custom exceptions, RFC 7807
---

# Spring Exception Handling

Chuẩn hóa xử lý lỗi trong Spring Boot applications.

---

## 1. Exception Hierarchy

### Quy tắc bắt buộc
- Tạo **custom exception hierarchy** riêng cho project
- Tách **BusinessException** (lỗi logic) và **TechnicalException** (lỗi hệ thống)
- **KHÔNG** dùng generic `RuntimeException` hoặc `Exception`
- **KHÔNG** catch và swallow exceptions

### Exception Structure
```
BaseException (abstract)
├── BusinessException (abstract)
│   ├── ResourceNotFoundException
│   ├── DuplicateResourceException
│   ├── InvalidOperationException
│   └── AccessDeniedException
└── TechnicalException (abstract)
    ├── ExternalServiceException
    ├── FileProcessingException
    └── DatabaseException
```

### Implementation
```java
// Base Exception
@Getter
public abstract class BaseException extends RuntimeException {
    private final String errorCode;
    private final HttpStatus httpStatus;

    protected BaseException(String message, String errorCode, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    protected BaseException(String message, String errorCode,
                            HttpStatus httpStatus, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }
}

// Business Exceptions
public class ResourceNotFoundException extends BaseException {
    public ResourceNotFoundException(String resourceName, Object id) {
        super(
            String.format("%s not found with id: %s", resourceName, id),
            "RESOURCE_NOT_FOUND",
            HttpStatus.NOT_FOUND
        );
    }

    public ResourceNotFoundException(String resourceName, String field, Object value) {
        super(
            String.format("%s not found with %s: %s", resourceName, field, value),
            "RESOURCE_NOT_FOUND",
            HttpStatus.NOT_FOUND
        );
    }
}

public class DuplicateResourceException extends BaseException {
    public DuplicateResourceException(String resourceName, String field, Object value) {
        super(
            String.format("%s already exists with %s: %s", resourceName, field, value),
            "DUPLICATE_RESOURCE",
            HttpStatus.CONFLICT
        );
    }
}

public class InvalidOperationException extends BaseException {
    public InvalidOperationException(String message) {
        super(message, "INVALID_OPERATION", HttpStatus.UNPROCESSABLE_ENTITY);
    }
}
```

---

## 2. Global Exception Handler

### Template chuẩn
```java
@RestControllerAdvice
@Slf4j
@Order(Ordered.HIGHEST_PRECEDENCE)
public class GlobalExceptionHandler {

    // Handle custom business exceptions
    @ExceptionHandler(BaseException.class)
    public ResponseEntity<ErrorResponse> handleBaseException(BaseException ex,
                                                              WebRequest request) {
        log.warn("Business error: [{}] {}", ex.getErrorCode(), ex.getMessage());

        ErrorResponse error = ErrorResponse.builder()
            .status(ex.getHttpStatus().value())
            .errorCode(ex.getErrorCode())
            .message(ex.getMessage())
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.status(ex.getHttpStatus()).body(error);
    }

    // Handle validation errors (@Valid)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(
            MethodArgumentNotValidException ex, WebRequest request) {

        Map<String, String> fieldErrors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                error -> error.getDefaultMessage() != null ?
                    error.getDefaultMessage() : "Invalid value",
                (existing, replacement) -> existing
            ));

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .errorCode("VALIDATION_ERROR")
            .message("Validation failed")
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .fieldErrors(fieldErrors)
            .build();

        return ResponseEntity.badRequest().body(error);
    }

    // Handle constraint violation (path/query param validation)
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(
            ConstraintViolationException ex, WebRequest request) {

        Map<String, String> fieldErrors = ex.getConstraintViolations()
            .stream()
            .collect(Collectors.toMap(
                v -> v.getPropertyPath().toString(),
                ConstraintViolation::getMessage,
                (existing, replacement) -> existing
            ));

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .errorCode("CONSTRAINT_VIOLATION")
            .message("Constraint violation")
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .fieldErrors(fieldErrors)
            .build();

        return ResponseEntity.badRequest().body(error);
    }

    // Handle type mismatch (e.g., String instead of Long for path variable)
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(
            MethodArgumentTypeMismatchException ex, WebRequest request) {

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .errorCode("TYPE_MISMATCH")
            .message(String.format("Parameter '%s' should be of type %s",
                ex.getName(), ex.getRequiredType() != null ?
                    ex.getRequiredType().getSimpleName() : "unknown"))
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.badRequest().body(error);
    }

    // Handle access denied
    @ExceptionHandler(org.springframework.security.access.AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(
            org.springframework.security.access.AccessDeniedException ex,
            WebRequest request) {

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.FORBIDDEN.value())
            .errorCode("ACCESS_DENIED")
            .message("You don't have permission to access this resource")
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }

    // Handle all other unhandled exceptions
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(
            Exception ex, WebRequest request) {

        log.error("Unexpected error", ex);

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
            .errorCode("INTERNAL_ERROR")
            .message("An unexpected error occurred. Please try again later.")
            .path(extractPath(request))
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }

    private String extractPath(WebRequest request) {
        return ((ServletWebRequest) request).getRequest().getRequestURI();
    }
}
```

---

## 3. Error Response Format (RFC 7807 inspired)

```java
@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {
    private final int status;
    private final String errorCode;
    private final String message;
    private final String path;
    private final LocalDateTime timestamp;
    private final Map<String, String> fieldErrors;
}
```

### JSON examples
```json
// Business error
{
    "status": 404,
    "errorCode": "RESOURCE_NOT_FOUND",
    "message": "User not found with id: 123",
    "path": "/api/v1/users/123",
    "timestamp": "2024-01-15T10:30:00"
}

// Validation error
{
    "status": 400,
    "errorCode": "VALIDATION_ERROR",
    "message": "Validation failed",
    "path": "/api/v1/users",
    "timestamp": "2024-01-15T10:30:00",
    "fieldErrors": {
        "email": "Invalid email format",
        "password": "Password must be at least 8 characters"
    }
}

// Internal error (KHÔNG expose chi tiết)
{
    "status": 500,
    "errorCode": "INTERNAL_ERROR",
    "message": "An unexpected error occurred. Please try again later.",
    "path": "/api/v1/orders",
    "timestamp": "2024-01-15T10:30:00"
}
```

---

## 4. Sử dụng Exceptions trong Service

### Quy tắc bắt buộc
- Throw custom exception, KHÔNG throw `RuntimeException`
- Service method nên throw **ít nhất** 1 custom exception cho error case
- Dùng `orElseThrow()` cho Optional results

```java
@Service
@RequiredArgsConstructor
public class UserService {

    public UserResponse getUser(Long id) {
        return userMapper.toResponse(
            userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", id))
        );
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        // Check duplicate
        if (userRepository.existsByEmail(request.email())) {
            throw new DuplicateResourceException("User", "email", request.email());
        }

        // Business validation
        if (!isValidDomain(request.email())) {
            throw new InvalidOperationException(
                "Email domain is not allowed for registration");
        }

        User user = userMapper.toEntity(request);
        user.setPassword(passwordEncoder.encode(request.password()));
        return userMapper.toResponse(userRepository.save(user));
    }

    @Transactional
    public void deactivateUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User", id));

        if (user.getStatus() == UserStatus.INACTIVE) {
            throw new InvalidOperationException("User is already inactive");
        }

        user.setStatus(UserStatus.INACTIVE);
    }
}
```

---

## 5. Anti-Patterns

### ❌ KHÔNG BAO GIỜ

```java
// ❌ Catch và swallow
try {
    processOrder(order);
} catch (Exception e) {
    // do nothing ← MẤT LỖI
}

// ❌ Catch generic Exception
try {
    processOrder(order);
} catch (Exception e) {
    throw new RuntimeException(e); // ❌ Mất context
}

// ❌ Return null thay vì throw
public User findUser(Long id) {
    return userRepository.findById(id).orElse(null); // ❌ NullPointerException
}

// ❌ Return error trong response body + HTTP 200
@GetMapping("/{id}")
public ResponseEntity<?> getUser(@PathVariable Long id) {
    try {
        return ResponseEntity.ok(userService.getUser(id));
    } catch (Exception e) {
        return ResponseEntity.ok(Map.of("error", e.getMessage())); // ❌ HTTP 200 cho error
    }
}

// ❌ Expose stack trace
@ExceptionHandler(Exception.class)
public ResponseEntity<?> handle(Exception e) {
    return ResponseEntity.status(500).body(Map.of(
        "error", e.getMessage(),
        "stackTrace", Arrays.toString(e.getStackTrace()) // ❌ Security risk
    ));
}
```

---

## Checklist trước khi commit

- [ ] Custom exception hierarchy (BaseException → Business/Technical)
- [ ] GlobalExceptionHandler handles tất cả exception types
- [ ] ErrorResponse format nhất quán
- [ ] Validation errors trả về field-level details
- [ ] Internal errors KHÔNG expose stack trace
- [ ] Service methods throw custom exceptions, không throw RuntimeException
- [ ] Không có empty catch blocks
- [ ] Logging level đúng: warn cho business, error cho technical
