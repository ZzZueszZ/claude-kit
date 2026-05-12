---
name: Spring Data JPA
description: Hướng dẫn thiết kế Entity, Repository, Query, Transaction trong Spring Data JPA
---

# Spring Data JPA

Chuẩn hóa thiết kế data layer với Spring Data JPA.

---

## 1. Entity Design

### Quy tắc bắt buộc
- **LUÔN** có Base Entity cho audit fields
- **KHÔNG** dùng `@Data` (Lombok) cho entities — sinh `@Setter`, `toString()`, `equals()` sai
- **KHÔNG** dùng `@Setter` (Lombok) cho entities — phá vỡ encapsulation, xem phần [Encapsulation Pattern](#encapsulation-pattern)
- **LUÔN** implement `equals()` and `hashCode()` dựa trên business key hoặc `id`
- Dùng `@GeneratedValue(strategy = GenerationType.IDENTITY)` cho auto-increment
- **KHÔNG** dùng `GenerationType.AUTO` (behavior khác nhau giữa databases)

### Base Entity
```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter // ✅ Chỉ dùng @Getter — KHÔNG @Setter, KHÔNG @Data
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @CreatedBy
    @Column(updatable = false)
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;

    // ✅ Protected setter — chỉ cho infrastructure layer (repository adapter)
    protected void setId(Long id) {
        this.id = id;
    }
}
```

### Chuẩn Entity
```java
@Entity
@Table(name = "users", uniqueConstraints = {
    @UniqueConstraint(columnNames = "email"),
    @UniqueConstraint(columnNames = "username")
})
@Getter // ✅ KHÔNG @Setter — dùng domain methods để thay đổi state
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@ToString(exclude = {"password", "roles"})
public class User extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String username;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(length = 100)
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.ACTIVE;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    @Builder.Default
    private Set<Role> roles = new HashSet<>();

    // ✅ Domain methods — thay đổi state thông qua methods có ý nghĩa nghiệp vụ
    public void activate() {
        this.status = UserStatus.ACTIVE;
    }

    public void deactivate() {
        this.status = UserStatus.INACTIVE;
    }

    public void updateProfile(String fullName, String email) {
        this.fullName = fullName;
        this.email = email;
    }

    public void changePassword(String newPassword) {
        this.password = newPassword;
    }

    public void addRole(Role role) {
        this.roles.add(role);
    }

    public void removeRole(Role role) {
        this.roles.remove(role);
    }

    public boolean hasRole(String roleName) {
        return roles.stream().anyMatch(r -> r.getName().equals(roleName));
    }

    // equals/hashCode based on id
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User other)) return false;
        return getId() != null && getId().equals(other.getId());
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
```

---

## 2. Relationship Mapping

### Quy tắc bắt buộc
- **LUÔN** dùng `FetchType.LAZY` cho collections (`@OneToMany`, `@ManyToMany`)
- **ƯU TIÊN** `FetchType.LAZY` cho `@ManyToOne` (default là EAGER)
- Quản lý **bidirectional relationships** với helper methods
- **KHÔNG** dùng `CascadeType.ALL` trừ parent-child quan hệ chặt

### Relationship Patterns

```java
// OneToMany — bidirectional (Parent side)
@Entity
public class Order extends BaseEntity {
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();

    // Helper methods cho bidirectional sync
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }
}

// ManyToOne — bidirectional (Child side)
@Entity
public class OrderItem extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false)
    private BigDecimal price;
}
```

---

## 3. Repository Pattern

### Quy tắc bắt buộc
- Extend `JpaRepository<Entity, IdType>` cho full CRUD
- Dùng **derived query methods** cho simple queries
- Dùng `@Query` (JPQL) cho complex queries
- Dùng **Specification** cho dynamic queries (search/filter)
- **KHÔNG** viết native SQL trừ khi performance critical

### Repository Template
```java
public interface UserRepository extends JpaRepository<User, Long> {

    // Derived query methods
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    List<User> findByStatus(UserStatus status);

    // JPQL for complex queries
    @Query("SELECT u FROM User u JOIN FETCH u.roles WHERE u.email = :email")
    Optional<User> findByEmailWithRoles(@Param("email") String email);

    @Query("SELECT u FROM User u WHERE u.status = :status AND u.createdAt > :since")
    Page<User> findActiveUsersSince(
        @Param("status") UserStatus status,
        @Param("since") LocalDateTime since,
        Pageable pageable
    );

    // Count queries
    @Query("SELECT COUNT(u) FROM User u WHERE u.status = :status")
    long countByStatus(@Param("status") UserStatus status);

    // Update queries
    @Modifying
    @Query("UPDATE User u SET u.status = :status WHERE u.id = :id")
    int updateStatus(@Param("id") Long id, @Param("status") UserStatus status);

    // Delete queries
    @Modifying
    @Query("DELETE FROM User u WHERE u.status = 'INACTIVE' AND u.updatedAt < :before")
    int deleteInactiveUsersBefore(@Param("before") LocalDateTime before);
}
```

---

## 4. N+1 Problem & Solutions

### Vấn đề N+1
```java
// ❌ N+1: 1 query cho users + N queries cho roles
List<User> users = userRepository.findAll(); // Query 1
for (User user : users) {
    user.getRoles().size(); // Query N (mỗi user 1 query)
}
```

### Giải pháp

#### 1. JOIN FETCH (Recommended cho 1 collection)
```java
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.roles")
List<User> findAllWithRoles();
```

#### 2. @EntityGraph (Declarative)
```java
@EntityGraph(attributePaths = {"roles"})
List<User> findByStatus(UserStatus status);

// Named EntityGraph
@NamedEntityGraph(
    name = "User.withRolesAndOrders",
    attributeNodes = {
        @NamedAttributeNode("roles"),
        @NamedAttributeNode("orders")
    }
)
@Entity
public class User { ... }

@EntityGraph(value = "User.withRolesAndOrders")
Optional<User> findById(Long id);
```

#### 3. @BatchSize (Batch loading)
```java
@Entity
public class User {
    @OneToMany(mappedBy = "user")
    @BatchSize(size = 20) // Load roles in batches of 20
    private List<Order> orders;
}
```

### Quy tắc
- **LUÔN** kiểm tra SQL logs trong dev: `spring.jpa.show-sql=true`
- **ƯU TIÊN** `JOIN FETCH` cho most common queries
- `@EntityGraph` cho reusable fetch strategies
- `@BatchSize` khi không thể dùng JOIN FETCH

---

## 5. Transaction Management

### Quy tắc bắt buộc
- `@Transactional` đặt trên **Service layer**, KHÔNG đặt trên Controller/Repository
- Read-only operations dùng `@Transactional(readOnly = true)`
- **LUÔN** specify `rollbackFor` cho checked exceptions

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true) // Default read-only cho class
public class UserService {

    private final UserRepository userRepository;

    // Read-only — dùng class-level annotation
    public UserResponse getUser(Long id) {
        return userMapper.toResponse(
            userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", id))
        );
    }

    // Write — override class-level annotation
    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        // Write operation
        User user = userRepository.save(mapToUser(request));
        return userMapper.toResponse(user);
    }

    // Custom rollback
    @Transactional(rollbackFor = {BusinessException.class, IOException.class})
    public void importUsers(MultipartFile file) throws IOException {
        // If any exception → rollback
    }
}
```

---

## 6. Soft Delete Pattern

### Implementation
```java
@MappedSuperclass
public abstract class SoftDeletableEntity extends BaseEntity {
    @Column(name = "deleted")
    @Builder.Default
    private boolean deleted = false;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public void softDelete() {
        this.deleted = true;
        this.deletedAt = LocalDateTime.now();
    }
}

// Entity
@Entity
@Where(clause = "deleted = false") // Hibernate filter
public class User extends SoftDeletableEntity { ... }

// Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Tự động filter deleted = false nhờ @Where

    // Khi cần query including deleted
    @Query("SELECT u FROM User u WHERE u.id = :id")
    @IgnoreWhere
    Optional<User> findByIdIncludingDeleted(@Param("id") Long id);
}
```

---

## 7. Database Migration (Flyway)

### File structure
```
src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__create_roles_table.sql
├── V3__create_user_roles_table.sql
└── V4__add_user_status_column.sql
```

### Quy tắc
- Tên file: `V{version}__{description}.sql`
- **KHÔNG BAO GIỜ** sửa migration đã chạy
- **LUÔN** tạo migration mới cho thay đổi schema
- Dùng `ddl-auto: validate` trong production

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # Chỉ validate, không auto generate
  flyway:
    enabled: true
    locations: classpath:db/migration
```

---

## Encapsulation Pattern

### ❌ KHÔNG dùng `@Setter` hoặc `@Data`

> Tham khảo: [Why Setters are Bad Practice](https://www.reddit.com/r/learnprogramming/comments/yco016/are_getters_and_setters_a_bad_pratice/)

Lý do:
1. **Phá vỡ encapsulation** — bất kỳ class nào cũng có thể thay đổi state entity
2. **Không validate** — setter không kiểm tra business rules
3. **Khó trace** — không biết ai, khi nào thay đổi field
4. **Anemic domain model** — entity trở thành data holder không có behavior

### ✅ Pattern chuẩn

| Component | Annotations | Ghi chú |
|-----------|-------------|---------|
| JPA Entity | `@Getter`, `@Builder`, `@NoArgsConstructor(PROTECTED)` | KHÔNG `@Setter`, KHÔNG `@Data` |
| Base Entity | thêm `protected setId(Long id)` | Cho infrastructure adapter set ID khi update |
| Domain Entity | Dùng domain methods: `updateStatus()`, `activate()` | KHÔNG field-level setter |
| Embeddable/ID class | `@Getter`, `@EqualsAndHashCode`, `@AllArgsConstructor` | Thay `@Data` |

### ⚠️ Ngoại lệ
- `@ConfigurationProperties` class — **CẦN** `@Setter` vì Spring binding requirement
- DTO/Request/Response class — có thể dùng `@Data` hoặc `record`

---

## Checklist trước khi commit

- [ ] Entity extends BaseEntity (audit fields)
- [ ] **KHÔNG** dùng `@Data` hoặc `@Setter` cho entities
- [ ] State changes qua domain methods, KHÔNG qua setter
- [ ] Relationships dùng `FetchType.LAZY`
- [ ] Không có N+1 (kiểm tra SQL logs)
- [ ] `@Transactional` trên Service, không trên Controller
- [ ] Read-only queries dùng `@Transactional(readOnly = true)`
- [ ] `equals()/hashCode()` implement đúng cho entities
- [ ] Database migration files đặt tên chuẩn
