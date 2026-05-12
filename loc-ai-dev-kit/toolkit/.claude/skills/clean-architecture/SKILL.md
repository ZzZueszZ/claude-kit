---
name: Clean Architecture
description: Hướng dẫn áp dụng Clean Architecture (Hexagonal / Ports & Adapters) trong Java Spring Boot
---

# Clean Architecture

Chuẩn hóa kiến trúc ứng dụng theo **Clean Architecture** (Robert C. Martin) kết hợp **Hexagonal Architecture** (Ports & Adapters), đảm bảo tách biệt concerns, testability, và independence from frameworks.

---

## 1. Nguyên tắc cốt lõi

### The Dependency Rule

> Source code dependencies phải **CHỈ** hướng **vào trong** (inward).

```
┌──────────────────────────────────────────────────────┐
│  Infrastructure / Frameworks (Outermost)             │
│  ┌──────────────────────────────────────────────┐    │
│  │  Presentation / Interface Adapters            │    │
│  │  ┌──────────────────────────────────────┐     │    │
│  │  │  Application / Use Cases              │     │    │
│  │  │  ┌──────────────────────────┐         │     │    │
│  │  │  │  Domain / Entities       │         │     │    │
│  │  │  │  (Innermost - NO deps)   │         │     │    │
│  │  │  └──────────────────────────┘         │     │    │
│  │  └──────────────────────────────────────┘     │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

### Quy tắc vàng
| Quy tắc | Mô tả |
|---------|--------|
| **Dependency Rule** | Code bên ngoài phụ thuộc bên trong, KHÔNG ngược lại |
| **Domain Independence** | Domain layer KHÔNG import framework (Spring, JPA, Jackson) |
| **Dependency Inversion** | Domain define interface, Infrastructure implement |
| **Single Responsibility** | Mỗi layer chỉ 1 trách nhiệm duy nhất |

---

## 2. Domain Layer (Innermost)

> Chứa **business rules** và **domain model**. KHÔNG phụ thuộc bất cứ thứ gì bên ngoài.

### Cho phép
- Domain Entities, Value Objects, Enums
- Domain Repository interfaces
- Domain Services (logic spanning multiple aggregates)
- Domain Events
- Domain Exceptions

### KHÔNG cho phép
- ❌ `@Entity`, `@Table`, `@Column` (JPA)
- ❌ `@Service`, `@Component`, `@Autowired` (Spring)
- ❌ `@JsonProperty`, `@JsonIgnore` (Jackson)
- ❌ `HttpServletRequest`, `ResponseEntity` (Web)
- ❌ Bất kỳ framework annotation nào

### ✅ Đúng — Pure Domain
```java
package com.ots.product.domain.model.entity;

import com.ots.product.domain.model.enums.ProductStatus;
import lombok.Builder;
import lombok.Getter;
import java.math.BigDecimal;

// ✅ Chỉ import Java core + domain packages
@Getter
@Builder
public class Product {
    private Long id;
    private String sku;
    private String name;
    private BigDecimal sellingPrice;
    private ProductStatus status;
    private int stockQuantity;

    // ✅ Business logic trong entity
    public boolean isLowStock() {
        return stockQuantity <= 10;
    }

    public void activate() {
        this.status = ProductStatus.ACTIVE;
    }
}
```

### Domain Repository Interface
```java
package com.ots.product.domain.repository;

// ✅ Interface — KHÔNG có Spring annotation
public interface ProductRepository {
    Optional<Product> findById(Long id);
    Product save(Product product);
    void deleteById(Long id);
}
```

---

## 3. Application Layer (Use Cases)

> **Orchestration** — điều phối domain objects để thực hiện use case. KHÔNG chứa business logic.

### Cho phép
- Application Services (Use Case classes)
- Port interfaces (cho external systems)
- DTO (Request/Response)
- Mappers
- Application-level Exceptions

### KHÔNG cho phép
- ❌ Business logic (phải nằm trong Domain)
- ❌ Direct database queries
- ❌ HTTP concerns (`@RequestBody`, `ResponseEntity`)
- ❌ Framework-specific configurations

### ✅ Đúng — Application Service
```java
package com.ots.product.application.service;

import com.ots.product.domain.repository.ProductRepository;
import com.ots.common.base.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository; // Domain interface

    @Transactional
    public ProductResponse createProduct(CreateProductRequest request) {
        // 1. Validate uniqueness
        if (productRepository.existsBySkuAndTenantId(request.sku(), tenantId)) {
            throw BusinessException.duplicate("Product", "sku", request.sku());
        }

        // 2. Build domain entity
        Product product = Product.builder()
            .sku(request.sku())
            .name(request.name())
            .sellingPrice(request.sellingPrice())
            .status(ProductStatus.ACTIVE)
            .build();

        // 3. Persist via domain repository
        Product saved = productRepository.save(product);

        // 4. Map to response
        return toResponse(saved);
    }
}
```

### Port Interface
```java
package com.ots.auth.application.port;

// ✅ Port — interface ở application layer
// Infrastructure sẽ implement (JwtTokenProvider)
public interface TokenPort {
    String generateAccessToken(Long userId, String email, ...);
    String generateRefreshToken(Long userId, String email);
    boolean isTokenValid(String token);
    String extractEmail(String token);
}
```

### ❌ Sai — Application Service chứa business logic
```java
@Service
public class ProductService {
    public BigDecimal calculateProfit(Product product) {
        // ❌ Business logic phải nằm trong Product entity
        return product.getSellingPrice().subtract(product.getCostPrice());
    }

    public boolean isLowStock(Product product) {
        // ❌ Nên là product.isLowStock()
        return product.getStockQuantity() <= product.getMinStockLevel();
    }
}
```

---

## 4. Infrastructure Layer (Outermost)

> **Implementation details** — JPA, REST clients, messaging, file storage. Implement domain/application interfaces.

### Cho phép
- JPA Entities (`@Entity`, `@Table`, `@Column`)
- Spring Data Repositories (`JpaRepository`)
- Repository Adapters (implement domain interfaces)
- Security configs, JWT implementation
- External API clients
- Spring configurations (`@Configuration`, `@Bean`)

### Pattern: Repository Adapter
```java
package com.ots.product.infrastructure.persistence.adapter;

@Repository
@RequiredArgsConstructor
public class ProductRepositoryAdapter implements ProductRepository {

    private final ProductJpaRepository jpaRepository;

    @Override
    public Optional<Product> findById(Long id) {
        return jpaRepository.findById(id)
            .map(this::toDomain);
    }

    @Override
    public Product save(Product product) {
        ProductJpaEntity entity = toJpaEntity(product);
        if (product.getId() != null) {
            entity.setId(product.getId()); // protected setter
        }
        ProductJpaEntity saved = jpaRepository.save(entity);
        return toDomain(saved);
    }

    // --- Mapping between Domain <-> JPA ---
    private Product toDomain(ProductJpaEntity entity) {
        return Product.builder()
            .id(entity.getId())
            .sku(entity.getSku())
            .name(entity.getName())
            .status(entity.getStatus())
            .build();
    }

    private ProductJpaEntity toJpaEntity(Product domain) {
        return ProductJpaEntity.builder()
            .sku(domain.getSku())
            .name(domain.getName())
            .status(domain.getStatus())
            .build();
    }
}
```

### JPA Entity (tách riêng khỏi Domain Entity)
```java
package com.ots.product.infrastructure.persistence.entity;

@Entity
@Table(name = "products")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class ProductJpaEntity extends BaseJpaEntity {

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    private ProductStatus status;

    // ❌ KHÔNG có business logic ở đây
    // Business logic nằm trong Domain Entity
}
```

---

## 5. Presentation Layer

> Nhận HTTP request, validate input, gọi Application Service, trả response.

### Cho phép
- REST Controllers (`@RestController`)
- Request/Response DTO validation (`@Valid`, `@NotNull`)
- Swagger/OpenAPI annotations (`@Operation`, `@ApiResponse`)

### KHÔNG cho phép
- ❌ Business logic
- ❌ Direct repository access
- ❌ Transaction management (`@Transactional`)

### ✅ Đúng
```java
package com.ots.product.presentation.controller;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService; // Application layer

    @PostMapping
    public ResponseEntity<ProductResponse> create(
            @Valid @RequestBody CreateProductRequest request) {
        // ✅ Controller chỉ delegate — không có logic
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(productService.createProduct(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(productService.getProduct(id));
    }
}
```

---

## 6. Dependency Flow (tổng quan)

```
Controller ──→ Application Service ──→ Domain Repository (interface)
                                              ↑
                                    Infrastructure Adapter (implements)
                                              ↓
                                    JPA Repository ──→ Database
```

### Import Rules

| Layer | CÓ THỂ import | KHÔNG ĐƯỢC import |
|-------|---------------|-------------------|
| **Domain** | Java core, Lombok (`@Getter`, `@Builder`) | Spring, JPA, Jackson, Infrastructure |
| **Application** | Domain, Spring (`@Service`, `@Transactional`) | Infrastructure, Presentation |
| **Infrastructure** | Domain, Application, Spring, JPA, libraries | Presentation |
| **Presentation** | Application (DTOs, Services), Spring Web | Domain entities trực tiếp, Infrastructure |

---

## 7. Ports & Adapters Pattern

### Inbound Adapter (driving)
```
HTTP Request → Controller (Inbound Adapter)
                    ↓
              Application Service (Use Case)
```

### Outbound Adapter (driven)
```
Application Service → Domain Repository Interface (Port)
                              ↓
                    RepositoryAdapter (Outbound Adapter) → Database
```

```
Application Service → TokenPort (Port)
                          ↓
                JwtTokenProvider (Outbound Adapter) → JWT Library
```

### Khi nào tạo Port
| Cần Port | Không cần Port |
|----------|----------------|
| External API (payment, email, SMS) | Internal logic |
| Database access | In-memory calculation |
| Messaging (Kafka, RabbitMQ) | Simple utility |
| File storage (S3, GCS) | Pure domain logic |
| Authentication (JWT, OAuth) | |

---

## 8. Testing theo Layer

### Unit Test cho từng layer

| Layer | Test gì | Mock gì |
|-------|---------|---------|
| **Domain** | Entity behavior, Value Object | Không cần mock — pure logic |
| **Application** | Use case orchestrations | Mock Repository, Ports |
| **Infrastructure** | Adapter mapping, DB queries | `@DataJpaTest`, Testcontainers |
| **Presentation** | Request/Response, validation | `@WebMvcTest`, mock Service |

### ✅ Test Domain — không cần mock
```java
@Test
void should_decrease_stock() {
    Product product = Product.builder()
        .stockQuantity(10)
        .build();

    product.decreaseStock(3);

    assertThat(product.getStockQuantity()).isEqualTo(7);
}

@Test
void should_throw_when_insufficient_stock() {
    Product product = Product.builder()
        .stockQuantity(2)
        .build();

    assertThrows(InsufficientStockException.class,
        () -> product.decreaseStock(5));
}
```

### ✅ Test Application — mock dependencies
```java
@ExtendWith(MockitoExtension.class)
class ProductServiceTest {
    @Mock private ProductRepository productRepository;
    @InjectMocks private ProductService productService;

    @Test
    void should_create_product() {
        CreateProductRequest request = new CreateProductRequest("SKU001", "Test", ...);
        when(productRepository.existsBySkuAndTenantId("SKU001", 1L)).thenReturn(false);
        when(productRepository.save(any())).thenReturn(Product.builder().id(1L).build());

        ProductResponse result = productService.createProduct(request);

        assertThat(result).isNotNull();
        verify(productRepository).save(any());
    }
}
```

---

## 9. Common Mistakes

### ❌ Domain import JPA
```java
// domain/model/entity/Product.java
import jakarta.persistence.Entity;   // ❌ VIOLATION
import jakarta.persistence.Column;   // ❌ VIOLATION
```

### ❌ Controller chứa business logic
```java
@PostMapping
public ResponseEntity<?> create(@RequestBody CreateProductRequest req) {
    if (productRepository.existsBySku(req.sku())) { // ❌ Logic ở Controller
        throw new DuplicateException();
    }
    Product product = new Product();
    product.setName(req.name()); // ❌ Setter
    productRepository.save(product); // ❌ Direct repo access
}
```

### ❌ Application Service chứa business rules
```java
@Service
public class OrderService {
    public void submitOrder(Long orderId) {
        Order order = orderRepository.findById(orderId).orElseThrow();
        if (order.getItems().isEmpty()) { // ❌ Business rule ở Service
            throw new EmptyOrderException();
        }
        order.setStatus(OrderStatus.SUBMITTED); // ❌ Setter thay vì domain method
    }
}

// ✅ Đúng — business rule trong entity
public class Order {
    public void submit() {
        if (this.items.isEmpty()) throw new EmptyOrderException();
        this.status = OrderStatus.SUBMITTED;
    }
}
```

### ❌ Infrastructure leaking vào Domain
```java
// domain/repository/ProductRepository.java
import org.springframework.data.jpa.repository.JpaRepository; // ❌ VIOLATION

public interface ProductRepository extends JpaRepository<Product, Long> { } // ❌
// Domain repository KHÔNG extend JPA repository
```

---

## Package Structure chuẩn

```
com.ots.{service}/
├── domain/                        ← INNERMOST — no framework deps
│   ├── model/
│   │   ├── entity/                ← Rich domain entities
│   │   ├── valueobject/           ← Immutable value objects
│   │   └── enums/                 ← Domain enums
│   ├── repository/                ← Repository interfaces (ports)
│   ├── service/                   ← Domain services
│   └── event/                     ← Domain events
│
├── application/                   ← USE CASES — orchestration
│   ├── service/                   ← Application services
│   ├── port/                      ← Port interfaces (external systems)
│   ├── dto/
│   │   ├── request/               ← Input DTOs
│   │   └── response/              ← Output DTOs
│   └── mapper/                    ← Domain ↔ DTO mappers
│
├── infrastructure/                ← OUTERMOST — framework details
│   ├── persistence/
│   │   ├── entity/                ← JPA entities (@Entity, @Table)
│   │   ├── repository/            ← Spring Data JPA repos
│   │   └── adapter/               ← Implements domain interfaces
│   ├── security/                  ← JWT, auth filters
│   ├── client/                    ← External API clients
│   └── config/                    ← Spring configs
│
└── presentation/                  ← INTERFACE — HTTP endpoints
    └── controller/                ← REST controllers
```

---

## Checklist Clean Architecture

- [ ] Domain layer KHÔNG import Spring, JPA, Jackson
- [ ] Dependency direction: ngoài → trong (KHÔNG ngược lại)
- [ ] Controller CHỈ delegate, KHÔNG chứa business logic
- [ ] Application Service orchestrate, KHÔNG chứa business rules
- [ ] Domain entity CÓ behavior (methods), KHÔNG phải anemic
- [ ] Repository interface ở Domain, implementation ở Infrastructure
- [ ] JPA Entity tách riêng khỏi Domain Entity
- [ ] Port interface cho mọi external dependency
- [ ] Mỗi layer chỉ test concerns của layer đó
