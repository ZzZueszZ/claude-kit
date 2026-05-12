---
name: Domain-Driven Design (DDD)
description: Hướng dẫn áp dụng DDD — Entities, Value Objects, Aggregates, Repositories, Domain Services trong Java Spring Boot
---

# Domain-Driven Design (DDD)

Chuẩn hóa cách thiết kế **domain layer** theo nguyên tắc DDD, đảm bảo domain logic tập trung, rõ ràng và không phụ thuộc framework.

---

## 1. Tổng quan DDD

### Mô hình phân tầng

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                  │  ← Controller, DTO
├─────────────────────────────────────────────────┤
│              Application Layer                   │  ← Use Cases, Orchestration
├─────────────────────────────────────────────────┤
│                Domain Layer                      │  ← Entities, Value Objects, Domain Services
├─────────────────────────────────────────────────┤
│             Infrastructure Layer                 │  ← JPA, External APIs, Messaging
└─────────────────────────────────────────────────┘
```

### Quy tắc vàng
- **Domain Layer KHÔNG phụ thuộc** bất kỳ layer nào khác
- **Domain KHÔNG import** Spring, JPA, Hibernate, Jackson, v.v.
- Dependency direction: **ngoài → trong** (Infra → Domain, KHÔNG ngược lại)

---

## 2. Entity

> Entity = đối tượng có **định danh** (Identity) xuyên suốt lifecycle.

### Quy tắc bắt buộc
- **CÓ** identity (`id`) — hai entity cùng `id` là cùng một object
- **KHÔNG** dùng `@Setter` hay `@Data` — dùng `@Getter` + `@Builder`
- Thay đổi state qua **domain methods** có ý nghĩa nghiệp vụ
- **CHỨA** business logic liên quan đến bản thân entity
- Entity domain **KHÔNG** có JPA annotations — tách riêng JPA Entity ở Infrastructure

### ✅ Đúng — Rich Domain Entity
```java
@Getter
@Builder
public class Product {
    private Long id;
    private String sku;
    private String name;
    private BigDecimal costPrice;
    private BigDecimal sellingPrice;
    private ProductStatus status;
    private int stockQuantity;
    private int minStockLevel;

    // ✅ Domain method — có ý nghĩa nghiệp vụ
    public void updateStatus(ProductStatus newStatus) {
        this.status = newStatus;
    }

    // ✅ Business logic nằm trong entity
    public BigDecimal getProfit() {
        if (costPrice == null || sellingPrice == null) return BigDecimal.ZERO;
        return sellingPrice.subtract(costPrice);
    }

    public BigDecimal getProfitMargin() {
        if (sellingPrice == null || sellingPrice.compareTo(BigDecimal.ZERO) == 0)
            return BigDecimal.ZERO;
        return getProfit()
            .divide(sellingPrice, 4, RoundingMode.HALF_UP)
            .multiply(BigDecimal.valueOf(100));
    }

    public boolean isLowStock() {
        return stockQuantity <= minStockLevel;
    }

    public void decreaseStock(int quantity) {
        if (quantity > this.stockQuantity) {
            throw new InsufficientStockException(this.name);
        }
        this.stockQuantity -= quantity;
    }

    public void increaseStock(int quantity) {
        this.stockQuantity += quantity;
    }
}
```

### ❌ Sai — Anemic Entity
```java
// ❌ Entity không có behavior — chỉ là data holder
@Getter
@Setter
public class Product {
    private Long id;
    private String name;
    private BigDecimal price;
    private int stock;
    // ❌ Tất cả logic nằm ở Service → Anemic Domain Model
}
```

---

## 3. Value Object

> Value Object = đối tượng **không có identity**, được định nghĩa bởi giá trị.

### Quy tắc bắt buộc
- **KHÔNG** có `id` — hai VO cùng giá trị là **bằng nhau**
- **Immutable** — tạo bằng constructor/factory, KHÔNG có setter
- Override `equals()` + `hashCode()` dựa trên **tất cả fields**
- Nên dùng `record` (Java 16+) hoặc `@Value` (Lombok)

### ✅ Đúng
```java
// Java Record — immutable by default
public record Money(BigDecimal amount, String currency) {

    public Money {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount must be non-negative");
        }
        if (currency == null || currency.isBlank()) {
            throw new IllegalArgumentException("Currency required");
        }
    }

    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new CurrencyMismatchException(this.currency, other.currency);
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }

    public Money multiply(int quantity) {
        return new Money(this.amount.multiply(BigDecimal.valueOf(quantity)), this.currency);
    }
}

// Dùng trong Entity
public class OrderItem {
    private Product product;
    private int quantity;
    private Money unitPrice;

    public Money getSubtotal() {
        return unitPrice.multiply(quantity);
    }
}
```

### Khi nào dùng Value Object
| Dùng VO | Dùng primitive |
|---------|----------------|
| Email, Phone, Address | Simple String không có validation |
| Money (amount + currency) | Single BigDecimal |
| DateRange (from + to) | Single LocalDate |
| GeoLocation (lat + lng) | Khi chỉ cần 1 giá trị đơn |

---

## 4. Aggregate & Aggregate Root

> Aggregate = cụm Entity/VO liên quan, được quản lý bởi **Aggregate Root**.

### Quy tắc bắt buộc
- Truy cập Aggregate **CHỈ** qua Aggregate Root
- Bên ngoài Aggregate **KHÔNG** trực tiếp thay đổi child entities
- Mỗi Aggregate có **1 Repository** duy nhất (cho Root)
- Transaction boundary = Aggregate boundary

### ✅ Đúng — Order Aggregate
```java
@Getter
@Builder
public class Order {
    private Long id;
    private Long customerId;
    private OrderStatus status;
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();
    private Money totalAmount;

    // ✅ Thay đổi child thông qua Aggregate Root
    public void addItem(Product product, int quantity, Money unitPrice) {
        if (this.status != OrderStatus.DRAFT) {
            throw new OrderNotEditableException(this.id);
        }
        OrderItem item = OrderItem.builder()
            .product(product)
            .quantity(quantity)
            .unitPrice(unitPrice)
            .build();
        this.items.add(item);
        recalculateTotal();
    }

    public void removeItem(Long productId) {
        this.items.removeIf(item -> item.getProduct().getId().equals(productId));
        recalculateTotal();
    }

    public void submit() {
        if (this.items.isEmpty()) {
            throw new EmptyOrderException();
        }
        this.status = OrderStatus.SUBMITTED;
    }

    public void cancel() {
        if (this.status == OrderStatus.SHIPPED) {
            throw new OrderAlreadyShippedException(this.id);
        }
        this.status = OrderStatus.CANCELLED;
    }

    private void recalculateTotal() {
        this.totalAmount = items.stream()
            .map(OrderItem::getSubtotal)
            .reduce(Money::add)
            .orElse(new Money(BigDecimal.ZERO, "VND"));
    }
}
```

### ❌ Sai
```java
// ❌ Bên ngoài trực tiếp thay đổi child entity
order.getItems().add(new OrderItem()); // ❌ Bypass Aggregate Root
order.getItems().get(0).setQuantity(5); // ❌ Trực tiếp thay đổi child

// ❌ Repository cho child entity
OrderItemRepository itemRepo; // ❌ Chỉ có OrderRepository
```

---

## 5. Repository (Domain Layer)

> Repository = **interface** ở domain layer, **implementation** ở infrastructure.

### Quy tắc bắt buộc
- Repository là **interface** trong `domain/repository/`
- Chỉ có **1 Repository per Aggregate Root**
- Trả về **Domain Entity**, KHÔNG trả JPA Entity
- Naming: `findById()`, `save()`, `delete()` — KHÔNG dùng JPA-specific names

### ✅ Đúng
```java
// domain/repository/ProductRepository.java
public interface ProductRepository {
    Optional<Product> findById(Long id);
    Optional<Product> findBySkuAndTenantId(String sku, Long tenantId);
    List<Product> findByTenantId(Long tenantId);
    Product save(Product product);
    void deleteById(Long id);
    boolean existsBySkuAndTenantId(String sku, Long tenantId);
}
```

### Adapter Implementation
```java
// infrastructure/persistence/adapter/ProductRepositoryAdapter.java
@Repository
@RequiredArgsConstructor
public class ProductRepositoryAdapter implements ProductRepository {

    private final ProductJpaRepository jpaRepository;
    private final ProductMapper mapper;

    @Override
    public Optional<Product> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Product save(Product product) {
        ProductJpaEntity entity = mapper.toJpaEntity(product);
        if (product.getId() != null) {
            entity.setId(product.getId()); // protected setter
        }
        return mapper.toDomain(jpaRepository.save(entity));
    }
}
```

---

## 6. Domain Service

> Domain Service = logic nghiệp vụ **spanning multiple Aggregates**.

### Khi nào dùng Domain Service
- Logic liên quan đến **2+ Aggregates** mà không thuộc về aggregate nào
- Logic phức tạp cần **inject external data** giữa các aggregates

### ✅ Đúng
```java
// Domain Service — logic spanning Order + Product
public class OrderPricingService {

    public Money calculateOrderTotal(Order order, DiscountPolicy discountPolicy) {
        Money subtotal = order.getSubtotal();
        Money discount = discountPolicy.calculate(subtotal);
        return subtotal.subtract(discount);
    }
}
```

### ❌ Sai
```java
// ❌ Domain Service chứa logic của 1 entity → nên di chuyển vào entity
public class ProductService {
    public boolean isLowStock(Product product) {
        return product.getStockQuantity() <= product.getMinStockLevel();
        // ❌ Logic này thuộc về Product entity
    }
}
```

---

## 7. Domain Event

> Domain Event = thông báo **điều gì đã xảy ra** trong domain.

### Pattern
```java
// Event
public record OrderSubmittedEvent(
    Long orderId,
    Long customerId,
    Money totalAmount,
    LocalDateTime occurredAt
) {}

// Phát event trong Aggregate Root
public class Order {
    @Getter
    private final List<Object> domainEvents = new ArrayList<>();

    public void submit() {
        this.status = OrderStatus.SUBMITTED;
        domainEvents.add(new OrderSubmittedEvent(
            this.id, this.customerId, this.totalAmount, LocalDateTime.now()));
    }

    public void clearEvents() {
        domainEvents.clear();
    }
}

// Application Service lắng nghe
@TransactionalEventListener
public void onOrderSubmitted(OrderSubmittedEvent event) {
    notificationService.notifyOrderConfirmation(event.orderId());
    inventoryService.reserveStock(event.orderId());
}
```

---

## 8. Anti-Corruption Layer (ACL)

### Khi tích hợp external system
```java
// Port — interface ở domain/application
public interface PaymentGateway {
    PaymentResult charge(Money amount, PaymentMethod method);
}

// Adapter — implementation ở infrastructure
@Component
public class StripePaymentAdapter implements PaymentGateway {
    private final StripeClient stripeClient;

    @Override
    public PaymentResult charge(Money amount, PaymentMethod method) {
        // Chuyển đổi domain objects sang Stripe API objects
        StripeChargeRequest request = mapToStripeRequest(amount, method);
        StripeChargeResponse response = stripeClient.charge(request);
        return mapToPaymentResult(response); // Trả về domain object
    }
}
```

---

## Package Structure chuẩn

```
com.ots.product/
├── domain/
│   ├── model/
│   │   ├── entity/          ← Product, Category, Shelf
│   │   ├── valueobject/     ← Money, Address, SKU
│   │   └── enums/           ← ProductStatus, UnitType
│   ├── repository/          ← ProductRepository (interface)
│   ├── service/             ← Domain Services
│   └── event/               ← OrderSubmittedEvent
├── application/
│   ├── service/             ← ProductService (use case orchestration)
│   ├── port/                ← TokenPort, PaymentGateway (interface)
│   ├── dto/
│   │   ├── request/         ← CreateProductRequest
│   │   └── response/        ← ProductResponse
│   └── mapper/              ← ProductMapper
├── infrastructure/
│   ├── persistence/
│   │   ├── entity/          ← ProductJpaEntity (JPA annotations)
│   │   ├── repository/      ← ProductJpaRepository (Spring Data)
│   │   └── adapter/         ← ProductRepositoryAdapter (implements domain interface)
│   ├── security/            ← JWT, filters
│   └── config/              ← Spring configs
└── presentation/
    └── controller/          ← ProductController (REST endpoints)
```

---

## Checklist DDD

- [ ] Domain entity KHÔNG import Spring/JPA/Hibernate
- [ ] Entity có business methods, KHÔNG phải anemic data holder
- [ ] Value Object là immutable, override `equals()/hashCode()`
- [ ] Aggregate Root quản lý tất cả thay đổi của children
- [ ] Chỉ 1 Repository per Aggregate Root
- [ ] Repository trả về Domain Entity, KHÔNG trả JPA Entity
- [ ] Domain Service chỉ cho logic spanning multiple aggregates
- [ ] Dependency direction: Infrastructure → Domain (KHÔNG ngược)
