---
name: Java Design Patterns
description: Hướng dẫn áp dụng các Design Patterns phổ biến trong Java Spring Boot - Creational, Structural, Behavioral
---

# Java Design Patterns

Các design patterns **phổ biến** và cách áp dụng trong Java Spring Boot.

> **Nguyên tắc**: Chỉ dùng pattern khi nó **giải quyết vấn đề thực tế**, KHÔNG dùng chỉ vì "best practice".

---

## Creational Patterns

---

### 1. Builder Pattern

> Tách biệt quá trình **construction** của complex object khỏi **representation** của nó.

#### Bản chất
- Object có nhiều fields (>3), nhiều optional → constructor dài, dễ nhầm thứ tự
- Builder cho phép xây dựng object **step-by-step** với named methods
- Kết quả: object **immutable**, **readable**, **self-documenting**

#### Class Diagram
```
┌───────────────────┐         ┌──────────────────────┐
│   SearchCriteria  │◄────────│  SearchCriteriaBuilder│
├───────────────────┤  builds ├──────────────────────┤
│ - keyword: String │         │ + keyword(String)     │
│ - status: Status  │         │ + status(Status)      │
│ - page: int       │         │ + page(int)           │
│ - size: int       │         │ + build()             │
└───────────────────┘         └──────────────────────┘
```

#### Ví dụ — Lombok Builder (ƯU TIÊN)
```java
@Builder
@Getter
public class SearchCriteria {
    private final String keyword;
    private final UserStatus status;
    @Builder.Default
    private final int page = 0;
    @Builder.Default
    private final int size = 20;
    private final LocalDateTime fromDate;
    private final LocalDateTime toDate;
}

// Usage — named parameters, rõ ràng
SearchCriteria criteria = SearchCriteria.builder()
    .keyword("john")
    .status(UserStatus.ACTIVE)
    .page(0)
    .size(10)
    .build();
```

#### Ví dụ — Step Builder (enforce thứ tự bắt buộc)
```java
// Khi cần enforce build order: to → subject → body → (optional cc) → build
public class EmailMessage {
    private final String to;
    private final String subject;
    private final String body;
    private final List<String> cc;

    private EmailMessage(Builder builder) {
        this.to = builder.to;
        this.subject = builder.subject;
        this.body = builder.body;
        this.cc = List.copyOf(builder.cc);
    }

    // Step interfaces — compiler enforce thứ tự
    public interface ToStep { SubjectStep to(String to); }
    public interface SubjectStep { BodyStep subject(String subject); }
    public interface BodyStep { BuildStep body(String body); }
    public interface BuildStep {
        BuildStep cc(String cc);
        EmailMessage build();
    }

    public static ToStep builder() { return new Builder(); }

    private static class Builder implements ToStep, SubjectStep, BodyStep, BuildStep {
        private String to, subject, body;
        private final List<String> cc = new ArrayList<>();

        public SubjectStep to(String to) { this.to = to; return this; }
        public BodyStep subject(String subject) { this.subject = subject; return this; }
        public BuildStep body(String body) { this.body = body; return this; }
        public BuildStep cc(String cc) { this.cc.add(cc); return this; }
        public EmailMessage build() { return new EmailMessage(this); }
    }
}

// Usage — IDE guide từng step, KHÔNG THỂ bỏ qua required fields
EmailMessage email = EmailMessage.builder()
    .to("user@example.com")       // ← buộc phải gọi first
    .subject("Welcome")           // ← buộc phải gọi second
    .body("Hello!")               // ← buộc phải gọi third
    .cc("manager@example.com")    // ← optional
    .build();
```

#### So sánh cách tạo object

| Cách | Ưu điểm | Nhược điểm |
|------|---------|------------|
| **Constructor** | Đơn giản | Nhiều params → nhầm thứ tự, telescoping |
| **Setter** | Flexible | Object mutable, có thể incomplete |
| **Lombok @Builder** | Readable, immutable | Cần Lombok dependency |
| **Step Builder** | Enforce required fields | Code dài hơn |

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Object có >3 constructor params | Simple POJO 1-2 fields |
| Cần immutable objects | Object cần mutable (live updates) |
| Domain entities, DTOs, config | Khi constructor đơn giản đủ |
| Search criteria với nhiều optional filters | |

---

### 2. Factory Method Pattern

> Tạo object **dựa trên điều kiện** mà client KHÔNG cần biết implementation cụ thể.

#### Bản chất
- Ẩn creation logic → client chỉ cần biết **interface**
- Mở rộng dễ dàng: thêm implementation mới **không sửa code cũ** (Open/Closed)
- Spring DI tự động collect implementations → **auto-wired factory**

#### Class Diagram
```
┌───────────────────────┐
│   <<interface>>       │
│  NotificationSender   │
├───────────────────────┤
│ + send(to, msg)       │
│ + getType(): Type     │
└───────┬───────────────┘
        │ implements
   ┌────┼──────────┐
   ▼    ▼          ▼
┌──────┐ ┌──────┐ ┌──────┐
│Email │ │ SMS  │ │ Push │
│Sender│ │Sender│ │Sender│
└──────┘ └──────┘ └──────┘
        │
        ▼ collected by
┌───────────────────────┐
│  NotificationFactory  │
├───────────────────────┤
│ - senders: Map<>      │
│ + getSender(type)     │
└───────────────────────┘
```

#### Ví dụ — Spring Auto-Collecting Factory
```java
// 1. Interface
public interface NotificationSender {
    void send(String recipient, String message);
    NotificationType getType();
}

// 2. Implementations — mỗi class tự đăng ký type
@Component
public class EmailNotificationSender implements NotificationSender {
    @Override
    public void send(String recipient, String message) {
        // Gửi email qua SMTP
    }

    @Override
    public NotificationType getType() { return NotificationType.EMAIL; }
}

@Component
public class SmsNotificationSender implements NotificationSender {
    @Override
    public void send(String recipient, String message) {
        // Gửi SMS qua Twilio/API
    }

    @Override
    public NotificationType getType() { return NotificationType.SMS; }
}

// 3. Factory — Spring auto-collects tất cả implementations
@Component
public class NotificationFactory {
    private final Map<NotificationType, NotificationSender> senders;

    @Autowired
    public NotificationFactory(List<NotificationSender> senderList) {
        // Spring inject TẤT CẢ beans implement NotificationSender
        this.senders = senderList.stream()
            .collect(Collectors.toMap(
                NotificationSender::getType,
                Function.identity()
            ));
    }

    public NotificationSender getSender(NotificationType type) {
        NotificationSender sender = senders.get(type);
        if (sender == null) {
            throw new UnsupportedOperationException("No sender for: " + type);
        }
        return sender;
    }
}
```

#### Trick: Thêm implementation mới — KHÔNG sửa Factory
```java
// Chỉ cần thêm class mới + @Component → Factory tự detect
@Component
public class PushNotificationSender implements NotificationSender {
    @Override
    public void send(String recipient, String message) { /* push logic */ }

    @Override
    public NotificationType getType() { return NotificationType.PUSH; }
}
// → NotificationFactory tự có PUSH sender, KHÔNG sửa dòng nào
```

#### So sánh if/else vs Factory

```java
// ❌ If/else — thêm type → sửa code
public void send(NotificationType type, String to, String msg) {
    if (type == EMAIL) sendEmail(to, msg);
    else if (type == SMS) sendSms(to, msg);
    else if (type == PUSH) sendPush(to, msg);   // ← phải thêm
    else if (type == SLACK) sendSlack(to, msg);  // ← lại phải thêm
    // Vi phạm Open/Closed Principle
}

// ✅ Factory — thêm type → chỉ thêm class mới
factory.getSender(type).send(to, msg); // KHÔNG SỬA
```

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| ≥3 implementations của cùng interface | Chỉ có 1 implementation (YAGNI) |
| Cần chọn implementation runtime | Logic đơn giản, if/else 2 cases đủ |
| Thường xuyên thêm implementation mới | Static, không thay đổi |

---

### 3. Singleton Pattern (Spring Context)

> Đảm bảo class chỉ có **MỘT instance** duy nhất.

#### Bản chất
- Trong Spring: **mặc định tất cả beans là Singleton** (`@Scope("singleton")`)
- KHÔNG cần tự implement Singleton — Spring IoC container quản lý
- **Khi nào tự implement**: Shared state bên ngoài Spring context

#### Spring Singleton vs GOF Singleton

| Aspect | Spring Singleton | GOF Singleton |
|--------|-----------------|---------------|
| **Scope** | Per ApplicationContext | Per ClassLoader |
| **Quản lý** | Spring Container | Class tự quản lý |
| **Thread-safe** | Container đảm bảo creation | Tự implement |
| **Testable** | Inject mock dễ dàng | Khó mock, khó test |

#### ✅ Đúng — Spring Bean (mặc định singleton)
```java
@Service // ← Spring tự quản lý, CHỈ 1 instance
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository repository;
    // Thread-safe nếu không có mutable state
}
```

#### ❌ Sai — Tự implement Singleton trong Spring project
```java
// ❌ KHÔNG CẦN trong Spring — Spring đã lo
public class ProductService {
    private static ProductService instance;
    private ProductService() {}
    public static ProductService getInstance() { ... }
}
```

#### ⚠️ Cẩn thận: Singleton + Mutable State
```java
// ⚠️ NGUY HIỂM — Singleton với mutable field
@Service
public class CounterService {
    private int count = 0; // ⚠️ Shared mutable state → race condition

    public void increment() {
        count++; // NOT thread-safe!
    }
}

// ✅ Fix — dùng AtomicInteger hoặc synchronized
@Service
public class CounterService {
    private final AtomicInteger count = new AtomicInteger(0);

    public void increment() {
        count.incrementAndGet(); // Thread-safe
    }
}
```

---

## Structural Patterns

---

### 4. Adapter Pattern (Ports & Adapters)

> Chuyển đổi **interface** của class này thành interface mà client mong đợi.

#### Bản chất
- Kết nối 2 interface **không tương thích**
- Trong Clean Architecture: **Repository Adapter** chuyển đổi Domain ↔ Infrastructure
- Giữ Domain layer **độc lập** khỏi framework

#### Class Diagram
```
┌──────────────────────┐         ┌──────────────────────┐
│   <<interface>>      │         │   <<interface>>      │
│  ProductRepository   │         │  JpaRepository<>     │
│     (Domain Port)    │         │   (Spring Data)      │
├──────────────────────┤         ├──────────────────────┤
│ + findById(Long)     │         │ + findById(Long)     │
│ + save(Product)      │         │ + save(Entity)       │
│   returns Domain obj │         │   returns JPA Entity │
└──────────┬───────────┘         └──────────┬───────────┘
           │ implements                     │ extends
           ▼                                ▼
┌──────────────────────────────────────────────────────┐
│             ProductRepositoryAdapter                  │
│  (Infrastructure — bridges Domain ↔ JPA)              │
├──────────────────────────────────────────────────────┤
│ - jpaRepository: ProductJpaRepository                 │
│ + findById(Long): Optional<Product>                   │  ← Domain object
│ + save(Product): Product                              │  ← Domain object
│ - toDomain(ProductJpaEntity): Product                 │  ← mapping
│ - toJpaEntity(Product): ProductJpaEntity              │  ← mapping
└──────────────────────────────────────────────────────┘
```

#### Ví dụ — Repository Adapter
```java
// Domain Port (interface)
public interface ProductRepository {
    Optional<Product> findById(Long id);
    Product save(Product product);
    void deleteById(Long id);
}

// Infrastructure Adapter (implementation)
@Repository
@RequiredArgsConstructor
public class ProductRepositoryAdapter implements ProductRepository {

    private final ProductJpaRepository jpaRepository;

    @Override
    public Optional<Product> findById(Long id) {
        return jpaRepository.findById(id)
            .map(this::toDomain);              // JPA Entity → Domain Entity
    }

    @Override
    public Product save(Product product) {
        ProductJpaEntity entity = toJpaEntity(product);  // Domain → JPA
        if (product.getId() != null) {
            entity.setId(product.getId());                // protected setter
        }
        return toDomain(jpaRepository.save(entity));      // JPA → Domain
    }

    // --- Mapping methods ---
    private Product toDomain(ProductJpaEntity e) {
        return Product.builder()
            .id(e.getId())
            .sku(e.getSku())
            .name(e.getName())
            .status(e.getStatus())
            .build();
    }

    private ProductJpaEntity toJpaEntity(Product d) {
        return ProductJpaEntity.builder()
            .sku(d.getSku())
            .name(d.getName())
            .status(d.getStatus())
            .build();
    }
}
```

#### Ví dụ — External API Adapter
```java
// Application Port
public interface PaymentGateway {
    PaymentResult charge(Money amount, PaymentMethod method);
}

// Infrastructure Adapter — wrap Stripe API
@Component
@RequiredArgsConstructor
public class StripePaymentAdapter implements PaymentGateway {

    private final StripeClient client;

    @Override
    public PaymentResult charge(Money amount, PaymentMethod method) {
        // Chuyển đổi Domain → Stripe format
        StripeChargeRequest req = StripeChargeRequest.builder()
            .amount(amount.getAmount().longValue())
            .currency(amount.getCurrency())
            .source(method.getToken())
            .build();

        StripeChargeResponse res = client.charges().create(req);

        // Chuyển đổi Stripe → Domain
        return new PaymentResult(
            res.getId(),
            res.getStatus().equals("succeeded") ? PaymentStatus.SUCCESS : PaymentStatus.FAILED
        );
    }
}
```

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Kết nối Domain ↔ Infrastructure (DB, API) | Code cùng layer, cùng interface |
| Wrap third-party library | Internal service-to-service call |
| Cần isolate framework dependency | Khi 2 interfaces đã tương thích |

---

### 5. Decorator Pattern

> **Thêm behavior** cho object mà không sửa code gốc — wrap & extend.

#### Bản chất
- Decorator implement **CÙNG interface** với object được wrap
- Gọi method gốc (delegate) rồi **thêm logic trước/sau**
- Stack được: Decorator A → Decorator B → Base implementation

#### Class Diagram
```
┌─────────────────────────┐
│     <<interface>>       │
│  OrderPriceCalculator   │
├─────────────────────────┤
│ + calculate(Order)      │
└────────┬────────────────┘
         │ implements
    ┌────┴─────────────┐
    ▼                  ▼
┌───────────────┐  ┌──────────────────────┐
│ BasicPrice    │  │ TaxPriceCalculator   │
│ Calculator    │  │ (Decorator)          │
│ (@Primary)    │  ├──────────────────────┤
│               │  │ - delegate: Calculator│ ← wraps BasicPrice
│               │  │ + calculate(Order)   │ ← delegate + add tax
└───────────────┘  └──────────────────────┘
```

#### Ví dụ — Price Calculator với Tax
```java
// Base
@Component
@Primary
public class BasicPriceCalculator implements OrderPriceCalculator {
    @Override
    public BigDecimal calculate(Order order) {
        return order.getItems().stream()
            .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}

// Decorator — thêm thuế
@Component
public class TaxPriceCalculator implements OrderPriceCalculator {
    private final OrderPriceCalculator delegate;
    private final TaxService taxService;

    public TaxPriceCalculator(@Primary OrderPriceCalculator delegate,
                               TaxService taxService) {
        this.delegate = delegate;
        this.taxService = taxService;
    }

    @Override
    public BigDecimal calculate(Order order) {
        BigDecimal basePrice = delegate.calculate(order);       // ← gọi base
        BigDecimal tax = taxService.calculateTax(basePrice);    // ← thêm logic
        return basePrice.add(tax);
    }
}
```

#### So sánh Decorator vs AOP

| Aspect | Decorator | Spring AOP (`@Aspect`) |
|--------|-----------|----------------------|
| **Granularity** | Per-interface, explicit | Cross-cutting, declarative |
| **Control** | Full control over wrapping | Pointcut expressions |
| **Use case** | Thêm business logic | Logging, security, audit |
| **Visibility** | Explicit trong code | "Magic" — ẩn trong aspect |

> **Quy tắc**: Dùng **AOP** cho cross-cutting (logging, audit). Dùng **Decorator** cho business-level wrapping.

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Thêm business behavior (tax, discount) | Logging, audit → dùng AOP |
| Wrap third-party services | Khi chỉ cần if/else đơn giản |
| Cần stack nhiều behaviors | Khi behavior không liên quan đến cùng interface |

---

### 6. Facade Pattern

> **Đơn giản hóa** complex subsystem — cung cấp unified interface.

#### Bản chất
- Ẩn sự phức tạp của nhiều services phối hợp nhau
- Client (Controller) chỉ gọi **1 method** thay vì 5-6 services
- KHÔNG thêm logic mới — chỉ **orchestrate** existing services

#### Class Diagram
```
┌──────────────┐
│  Controller  │ ← client chỉ biết Facade
└──────┬───────┘
       │ calls
       ▼
┌──────────────────┐
│   OrderFacade    │ ← orchestrate complex flow
├──────────────────┤
│ + placeOrder()   │
└──┬──┬──┬──┬──┬───┘
   │  │  │  │  │ delegates to
   ▼  ▼  ▼  ▼  ▼
 Inventory Payment Shipping Notification Order
 Service   Service  Service  Service      Repository
```

#### Ví dụ
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class OrderFacade {
    private final InventoryService inventoryService;
    private final PaymentService paymentService;
    private final ShippingService shippingService;
    private final NotificationService notificationService;
    private final OrderRepository orderRepository;

    @Transactional
    public OrderResponse placeOrder(PlaceOrderRequest request) {
        // 1. Check inventory
        inventoryService.checkAndReserve(request.items());

        // 2. Process payment
        PaymentResult payment = paymentService.charge(
            request.paymentMethod(), request.totalAmount());

        // 3. Create order
        Order order = Order.builder()
            .items(request.items())
            .paymentId(payment.transactionId())
            .status(OrderStatus.CONFIRMED)
            .build();
        orderRepository.save(order);

        // 4. Schedule shipping
        shippingService.scheduleDelivery(order);

        // 5. Notify customer
        notificationService.sendOrderConfirmation(order);

        return orderMapper.toResponse(order);
    }
}
```

#### So sánh Facade vs Service

| Facade | Service |
|--------|---------|
| Orchestrate **nhiều services** | Chứa logic **1 domain** |
| Thin layer — chỉ phối hợp | Fat layer — chứa business logic |
| Controller → Facade → Services | Controller → Service → Repository |

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Flow gọi ≥3 services phối hợp | Chỉ gọi 1-2 services |
| Complex business process | CRUD đơn giản |
| Cần simplify Controller | Khi service đã đủ đơn giản |

---

## Behavioral Patterns

---

### 7. Strategy Pattern

> **Chọn algorithm** lúc runtime — encapsulate algorithm family.

#### Bản chất
- Nhiều cách xử lý cùng 1 việc → tách mỗi cách thành class riêng
- Client chọn strategy phù hợp, KHÔNG cần biết chi tiết
- **Khác Factory**: Factory tạo object khác nhau, Strategy thay đổi **behavior**

#### Class Diagram
```
┌──────────────────────┐           ┌──────────────────────┐
│     <<interface>>    │           │   DiscountService    │
│  DiscountStrategy    │◄──────────│   (Context)          │
├──────────────────────┤  uses     ├──────────────────────┤
│ + apply(price, order)│           │ - strategies: Map<>  │
│ + getDiscountType()  │           │ + calculateDiscount()│
└──────────┬───────────┘           └──────────────────────┘
           │
    ┌──────┼──────────────┐
    ▼      ▼              ▼
┌────────┐ ┌────────────┐ ┌──────────────┐
│Percent │ │FixedAmount │ │FreeShipping  │
│Discount│ │Discount    │ │Discount      │
│  10%   │ │  50,000₫   │ │  = ship fee  │
└────────┘ └────────────┘ └──────────────┘
```

#### Ví dụ
```java
// Strategy interface
public interface DiscountStrategy {
    BigDecimal apply(BigDecimal originalPrice, Order order);
    String getDiscountType();
}

// Implementations
@Component
public class PercentageDiscount implements DiscountStrategy {
    @Override
    public BigDecimal apply(BigDecimal price, Order order) {
        return price.multiply(BigDecimal.valueOf(0.1)); // 10% off
    }
    @Override
    public String getDiscountType() { return "PERCENTAGE"; }
}

@Component
public class FixedAmountDiscount implements DiscountStrategy {
    @Override
    public BigDecimal apply(BigDecimal price, Order order) {
        return BigDecimal.valueOf(50000); // Fixed 50k
    }
    @Override
    public String getDiscountType() { return "FIXED"; }
}

@Component
public class FreeShippingDiscount implements DiscountStrategy {
    @Override
    public BigDecimal apply(BigDecimal price, Order order) {
        return order.getShippingFee(); // Discount = shipping fee
    }
    @Override
    public String getDiscountType() { return "FREE_SHIPPING"; }
}

// Context — Spring auto-collects
@Service
public class DiscountService {
    private final Map<String, DiscountStrategy> strategies;

    public DiscountService(List<DiscountStrategy> strategyList) {
        this.strategies = strategyList.stream()
            .collect(Collectors.toMap(
                DiscountStrategy::getDiscountType,
                Function.identity()
            ));
    }

    public BigDecimal calculateDiscount(String type, BigDecimal price, Order order) {
        DiscountStrategy strategy = strategies.get(type);
        if (strategy == null) return BigDecimal.ZERO;
        return strategy.apply(price, order);
    }
}
```

#### So sánh Strategy vs Factory vs if/else

| Approach | Use case | Mở rộng |
|----------|----------|---------|
| **if/else** | ≤2 cases, không thay đổi | Sửa code mỗi lần thêm |
| **Factory** | Tạo **object khác nhau** | Thêm class |
| **Strategy** | Chọn **behavior khác nhau** | Thêm class |

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| ≥3 algorithms cùng mục đích | Chỉ 1-2 options → if/else đủ |
| Algorithm thay đổi runtime | Logic cố định, không đổi |
| Mỗi algorithm phức tạp, cần test riêng | Logic đơn giản 1-2 dòng |

---

### 8. Template Method Pattern

> Định nghĩa **skeleton** của algorithm — subclass implement các steps khác nhau.

#### Bản chất
- Abstract class định nghĩa **thứ tự steps** (template method)
- Subclass **override** specific steps mà KHÔNG thay đổi flow tổng thể
- Template method thường `final` → subclass KHÔNG thay đổi flow

```
Algorithm Flow (fixed):  validate → fetchData → formatData → saveFile
                           ↓           ↓            ↓           ↓
                        common      abstract     abstract     hook
                        (base)     (must impl)  (must impl)  (can override)
```

#### Class Diagram
```
┌──────────────────────────┐
│     DataExporter         │  ← Abstract class
├──────────────────────────┤
│ + export() «final»      │  ← Template method (skeleton)
│ # validate()             │  ← Common step
│ # fetchData() «abstract» │  ← Subclass MUST implement
│ # formatData() «abstract»│  ← Subclass MUST implement
│ # saveFile()             │  ← Hook (override optional)
└──────────┬───────────────┘
      ┌────┴──────────┐
      ▼               ▼
┌───────────┐   ┌───────────┐
│CsvExporter│   │PdfExporter│
│           │   │           │
│ fetchData │   │ fetchData │
│ formatCsv │   │ formatPdf │
│           │   │ saveToS3  │  ← override hook
└───────────┘   └───────────┘
```

#### Ví dụ
```java
public abstract class DataExporter {

    // Template method — FINAL, không cho override
    public final ExportResult export(ExportRequest request) {
        validate(request);                                    // step 1: common
        List<Map<String, Object>> data = fetchData(request);  // step 2: abstract
        byte[] content = formatData(data);                    // step 3: abstract
        String filePath = saveFile(request.fileName(), content); // step 4: hook
        return new ExportResult(filePath, data.size());
    }

    protected void validate(ExportRequest request) {
        if (request.fileName() == null) {
            throw new IllegalArgumentException("File name required");
        }
    }

    // Abstract — subclass PHẢI implement
    protected abstract List<Map<String, Object>> fetchData(ExportRequest request);
    protected abstract byte[] formatData(List<Map<String, Object>> data);

    // Hook — có default, subclass CÓ THỂ override
    protected String saveFile(String fileName, byte[] content) {
        return FileUtils.saveToLocal(fileName, content);
    }
}

@Service
public class CsvExporter extends DataExporter {
    @Override
    protected List<Map<String, Object>> fetchData(ExportRequest request) {
        return dataRepository.findAll();
    }

    @Override
    protected byte[] formatData(List<Map<String, Object>> data) {
        return CsvUtils.toCsv(data); // CSV format
    }
}

@Service
public class PdfExporter extends DataExporter {
    @Override
    protected List<Map<String, Object>> fetchData(ExportRequest request) {
        return dataRepository.findAll();
    }

    @Override
    protected byte[] formatData(List<Map<String, Object>> data) {
        return PdfUtils.toPdf(data); // PDF format
    }

    @Override
    protected String saveFile(String fileName, byte[] content) {
        return s3Service.upload(fileName, content); // Override: save to S3
    }
}
```

#### So sánh Template Method vs Strategy

| Aspect | Template Method | Strategy |
|--------|----------------|----------|
| **Relationship** | Inheritance (is-a) | Composition (has-a) |
| **Fixed part** | Skeleton algorithm fixed | Toàn bộ algorithm thay đổi |
| **Flexibility** | Chỉ thay đổi specific steps | Thay đổi toàn bộ behavior |
| **Spring** | Abstract class + subclass | Interface + implementations |

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Cùng flow, khác 1-2 steps | Khi flow cũng khác nhau → Strategy |
| Export (CSV/PDF/Excel) | Khi chỉ cần 1 implementation |
| Process pipeline cố định | Khi cần runtime switching |

---

### 9. Observer Pattern (Spring Events)

> Khi **sự kiện xảy ra**, thông báo cho tất cả bên liên quan mà KHÔNG cần coupling.

#### Bản chất
- Publisher **không biết** có bao nhiêu listeners
- Listeners **tự đăng ký** xử lý event
- **Loose coupling**: thêm/bớt listener KHÔNG sửa publisher

#### Ví dụ — Spring Events
```java
// 1. Event — record immutable
public record UserRegisteredEvent(
    Long userId,
    String email,
    String username,
    LocalDateTime registeredAt
) {}

// 2. Publisher — chỉ publish, không biết ai handle
@Service
@RequiredArgsConstructor
public class UserService {
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        User user = userRepository.save(mapToUser(request));

        // Publish — không cần biết ai handle
        eventPublisher.publishEvent(new UserRegisteredEvent(
            user.getId(), user.getEmail(), user.getUsername(), LocalDateTime.now()));

        return userMapper.toResponse(user);
    }
}

// 3. Listeners — tự đăng ký, loosely coupled
@Component @Slf4j
public class WelcomeEmailListener {
    @EventListener
    @Async // ← chạy async, không block publisher
    public void onUserRegistered(UserRegisteredEvent event) {
        log.info("Sending welcome to: {}", event.email());
        emailService.sendWelcomeEmail(event.email(), event.username());
    }
}

@Component
public class DefaultRoleAssigner {
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUserRegistered(UserRegisteredEvent event) {
        // Chạy SAU KHI transaction commit thành công
        roleService.assignDefaultRole(event.userId());
    }
}
```

#### @EventListener vs @TransactionalEventListener

| Annotation | Chạy khi | Use case |
|------------|----------|----------|
| `@EventListener` | Ngay lập tức (cùng transaction) | Side effects không critical |
| `@TransactionalEventListener(AFTER_COMMIT)` | Sau transaction commit | Data đã chắc chắn lưu |
| `@TransactionalEventListener(AFTER_ROLLBACK)` | Sau transaction rollback | Cleanup, compensation |

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Side effects (email, analytics, notification) | Critical business logic cần đảm bảo thứ tự |
| Multiple handlers cho cùng event | Khi cần return value từ handler |
| Async processing | Sync flow bắt buộc |
| Decouple modules | In-module method call đủ đơn giản |

---

### 10. Chain of Responsibility

> Truyền request qua **chuỗi handlers** — mỗi handler quyết định xử lý hoặc pass tiếp.

#### Bản chất
- Request đi qua dãy handlers tuần tự
- Mỗi handler: **xử lý** request hoặc **pass** cho handler tiếp theo
- Spring Security Filters chính là Chain of Responsibility

#### Class Diagram
```
Request → [Handler A] → [Handler B] → [Handler C] → Response
              │               │              │
              ▼               ▼              ▼
          Validate        Transform       Process
           or skip          or skip        or skip
```

#### Ví dụ — Validation Chain
```java
// Handler interface
public interface OrderValidator {
    void validate(Order order);
    int getOrder(); // Thứ tự chạy
}

@Component
public class StockValidator implements OrderValidator {
    @Override
    public void validate(Order order) {
        for (OrderItem item : order.getItems()) {
            if (item.getProduct().getStockQuantity() < item.getQuantity()) {
                throw new InsufficientStockException(item.getProduct().getName());
            }
        }
    }
    @Override
    public int getOrder() { return 1; }
}

@Component
public class PaymentValidator implements OrderValidator {
    @Override
    public void validate(Order order) {
        if (order.getPaymentMethod() == null) {
            throw new PaymentRequiredException();
        }
    }
    @Override
    public int getOrder() { return 2; }
}

@Component
public class AddressValidator implements OrderValidator {
    @Override
    public void validate(Order order) {
        if (order.getShippingAddress() == null) {
            throw new AddressRequiredException();
        }
    }
    @Override
    public int getOrder() { return 3; }
}

// Chain executor
@Component
public class OrderValidationChain {
    private final List<OrderValidator> validators;

    public OrderValidationChain(List<OrderValidator> validators) {
        this.validators = validators.stream()
            .sorted(Comparator.comparingInt(OrderValidator::getOrder))
            .toList();
    }

    public void validateOrder(Order order) {
        validators.forEach(v -> v.validate(order)); // Chạy tuần tự
    }
}
```

#### Real-world: Spring Security Filter Chain
```
Request → CorsFilter → CsrfFilter → AuthFilter → AuthorizationFilter → Controller
                                        │
                                 JwtAuthenticationFilter
                                 (custom)
```

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Validation pipeline (nhiều bước) | Khi chỉ 1-2 validations |
| Request processing chain | Khi thứ tự không quan trọng |
| Middleware / filter pattern | Simple if/else chain đủ |

---

### 11. Specification Pattern

> **Encapsulate business rules** thành reusable, composable objects.

#### Bản chất
- Mỗi rule = 1 Specification class
- Combine bằng `and()`, `or()`, `not()`
- Dùng cho **complex filtering/querying** và **business rule validation**

#### Ví dụ — JPA Specification
```java
// Spring Data JPA Specification
public class ProductSpecifications {

    public static Specification<ProductJpaEntity> hasStatus(ProductStatus status) {
        return (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<ProductJpaEntity> hasTenant(Long tenantId) {
        return (root, query, cb) -> cb.equal(root.get("tenantId"), tenantId);
    }

    public static Specification<ProductJpaEntity> nameLike(String keyword) {
        return (root, query, cb) ->
            cb.like(cb.lower(root.get("name")), "%" + keyword.toLowerCase() + "%");
    }

    public static Specification<ProductJpaEntity> priceBetween(BigDecimal min, BigDecimal max) {
        return (root, query, cb) -> cb.between(root.get("sellingPrice"), min, max);
    }

    public static Specification<ProductJpaEntity> isLowStock() {
        return (root, query, cb) ->
            cb.lessThanOrEqualTo(root.get("stockQuantity"), root.get("minStockLevel"));
    }
}

// Usage — composable queries
@Service
public class ProductQueryService {
    private final ProductJpaRepository repository;

    public Page<Product> search(ProductSearchRequest request, Pageable pageable) {
        Specification<ProductJpaEntity> spec = Specification.where(null);

        if (request.status() != null) {
            spec = spec.and(ProductSpecifications.hasStatus(request.status()));
        }
        if (request.keyword() != null) {
            spec = spec.and(ProductSpecifications.nameLike(request.keyword()));
        }
        if (request.minPrice() != null && request.maxPrice() != null) {
            spec = spec.and(ProductSpecifications.priceBetween(
                request.minPrice(), request.maxPrice()));
        }
        if (request.lowStockOnly()) {
            spec = spec.and(ProductSpecifications.isLowStock());
        }

        return repository.findAll(spec, pageable).map(this::toDomain);
    }
}
```

#### So sánh if/else query vs Specification

```java
// ❌ If/else spaghetti cho dynamic queries
if (status != null && keyword != null && minPrice != null) {
    findByStatusAndNameAndPrice(status, keyword, minPrice, maxPrice);
} else if (status != null && keyword != null) {
    findByStatusAndName(status, keyword);
} else if (status != null) {
    findByStatus(status);
}
// → 2^n combinations!

// ✅ Specification — composable
spec.and(hasStatus(status))
    .and(nameLike(keyword))
    .and(priceBetween(min, max));
```

#### Khi nào dùng / không dùng

| ✅ Dùng | ❌ Không dùng |
|---------|-------------|
| Dynamic search/filter với nhiều criteria | Fixed query, không đổi |
| Complex WHERE conditions composable | Chỉ 1-2 filter fields |
| Business rules cần reuse/combine | One-off validation |

---

## Pattern Selection Guide

| Vấn đề | Pattern | Spring Support |
|---------|---------|----------------|
| Object có nhiều params | **Builder** | `@Builder` (Lombok) |
| Chọn implementation runtime | **Factory** | `List<Interface>` injection |
| 1 instance duy nhất | **Singleton** | Mặc định cho tất cả `@Bean` |
| Kết nối 2 interface khác nhau | **Adapter** | Repository Adapter pattern |
| Thêm behavior không sửa code | **Decorator** | `@Primary` + delegation |
| Đơn giản hóa complex subsystem | **Facade** | `@Service` orchestration |
| Nhiều algorithms cùng purpose | **Strategy** | `Map<String, Interface>` |
| Same flow, different steps | **Template Method** | Abstract class |
| Loose coupling side effects | **Observer** | `@EventListener` |
| Request qua chuỗi handlers | **Chain of Responsibility** | Security Filters |
| Complex composable queries | **Specification** | `JpaSpecificationExecutor` |

---

## Checklist trước khi dùng pattern

- [ ] Vấn đề CÓ THỰC SỰ cần pattern? (KISS)
- [ ] Đã có yêu cầu mở rộng chưa? (YAGNI — ≥3 implementations mới dùng)
- [ ] Spring có built-in support không? (Events, DI, AOP, Security Filters)
- [ ] Team có hiểu pattern này không? (Readability > cleverness)
- [ ] Pattern có giảm complexity hay tăng complexity?
- [ ] Có thể dùng if/else đơn giản thay pattern không?
