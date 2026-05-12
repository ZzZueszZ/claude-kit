---
name: Oracle Performance Tuning
description: Hướng dẫn tối ưu hiệu suất Oracle Database — Indexing, Execution Plan, Query Optimization, Partitioning, Hints
---

# Oracle Performance Tuning

Chuẩn hóa tối ưu hiệu suất Oracle Database trong dự án Spring Boot.

---

## 1. Indexing Strategy

### Quy tắc bắt buộc
- **LUÔN** tạo index cho FK columns
- **LUÔN** tạo index cho cột dùng trong WHERE, JOIN, ORDER BY thường xuyên
- **KHÔNG** tạo index cho bảng nhỏ (< 1000 rows)
- **KHÔNG** tạo quá nhiều index trên bảng có INSERT/UPDATE nhiều
- Tên index: `idx_{table}_{column}`

### Các loại Index

```sql
-- B-Tree Index (mặc định — dùng cho hầu hết trường hợp)
CREATE INDEX "idx_messages_postbox_id" ON "citizen_messages" ("postbox_id");

-- Composite Index (nhiều cột — thứ tự cột quan trọng!)
-- Đặt cột có selectivity cao (ít giá trị lặp) trước
CREATE INDEX "idx_messages_postbox_status" 
    ON "citizen_messages" ("postbox_id", "status", "deleted");

-- Unique Index
CREATE UNIQUE INDEX "idx_users_email" ON "users" ("email");

-- Function-Based Index (cho query dùng function)
CREATE INDEX "idx_users_upper_email" ON "users" (UPPER("email"));
-- Query sẽ dùng index: WHERE UPPER("email") = 'JOHN@EXAMPLE.COM'

-- Partial Index (Oracle 12c+ — chỉ index rows thoả điều kiện)
CREATE INDEX "idx_messages_unseen" 
    ON "citizen_messages" ("postbox_id", "created_at")
    WHERE "status" = 'UNSEEN' AND "deleted" = 0;

-- Bitmap Index (cho cột có ít distinct values — CHỈN dùng cho OLAP/data warehouse, KHÔNG dùng cho OLTP)
-- CREATE BITMAP INDEX "idx_users_status" ON "users" ("status");
```

### Composite Index — Thứ tự cột

```sql
-- Query: WHERE postbox_id = ? AND status = ? ORDER BY created_at DESC
-- Index tối ưu: equality columns trước, range/order columns sau
CREATE INDEX "idx_msgs_query" ON "citizen_messages" ("postbox_id", "status", "created_at" DESC);

-- Quy tắc:
-- 1. Equality columns (=) → đặt trước
-- 2. Range columns (>, <, BETWEEN) → đặt giữa
-- 3. ORDER BY columns → đặt cuối
```

---

## 2. Execution Plan — EXPLAIN PLAN

### Đọc Execution Plan

```sql
-- Xem execution plan
EXPLAIN PLAN FOR
SELECT * FROM "citizen_messages"
WHERE "postbox_id" = 123 AND "status" = 'UNSEEN' AND "deleted" = 0
ORDER BY "created_at" DESC
FETCH FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Hoặc dùng AUTOTRACE
SET AUTOTRACE ON EXPLAIN STATISTICS;
```

### Các operation cần chú ý

| Operation | Tốt/Xấu | Mô tả |
|-----------|----------|--------|
| `TABLE ACCESS FULL` | ⚠️ Xấu (bảng lớn) | Full table scan — cần index |
| `INDEX RANGE SCAN` | ✅ Tốt | Dùng index đúng |
| `INDEX UNIQUE SCAN` | ✅ Rất tốt | Truy vấn bằng PK/unique |
| `INDEX FULL SCAN` | ⚠️ Coi chừng | Quét toàn bộ index |
| `NESTED LOOPS` | ✅ Tốt (ít rows) | Join tốt cho small dataset |
| `HASH JOIN` | ✅ Tốt (nhiều rows) | Join tốt cho large dataset |
| `SORT ORDER BY` | ⚠️ Coi chừng | Có thể tránh bằng index |

---

## 3. Query Optimization

### ✅ Best Practices

```sql
-- 1. Dùng EXISTS thay IN cho subquery lớn
-- ❌ Chậm
SELECT * FROM "users" WHERE "id" IN (
    SELECT "owner_id" FROM "business_postbox" WHERE "deleted" = 0
);
-- ✅ Nhanh hơn
SELECT * FROM "users" u WHERE EXISTS (
    SELECT 1 FROM "business_postbox" b WHERE b."owner_id" = u."id" AND b."deleted" = 0
);

-- 2. Tránh function trên indexed column trong WHERE
-- ❌ Index không được dùng
SELECT * FROM "users" WHERE UPPER("email") = 'JOHN@EXAMPLE.COM';
-- ✅ Tạo function-based index hoặc lưu sẵn UPPER
CREATE INDEX "idx_users_upper_email" ON "users" (UPPER("email"));

-- 3. Dùng UNION ALL thay UNION (khi không cần loại duplicate)
-- ❌ UNION loại duplicate → sort → chậm
SELECT "id" FROM "business_messages" WHERE "status" = 'UNSEEN'
UNION
SELECT "id" FROM "citizen_messages" WHERE "status" = 'UNSEEN';
-- ✅
SELECT "id" FROM "business_messages" WHERE "status" = 'UNSEEN'
UNION ALL
SELECT "id" FROM "citizen_messages" WHERE "status" = 'UNSEEN';

-- 4. SELECT chỉ cột cần thiết
-- ❌
SELECT * FROM "citizen_messages" WHERE "postbox_id" = 123;
-- ✅
SELECT "id", "subject", "status", "received_at" 
FROM "citizen_messages" WHERE "postbox_id" = 123;

-- 5. Batch INSERT/UPDATE thay vì từng row
-- ❌ 1000 lần INSERT
-- ✅ FORALL + BULK COLLECT (xem oracle-plsql skill)
```

### Pagination tối ưu

```sql
-- ✅ Keyset pagination (tốt cho infinite scroll, large dataset)
SELECT "id", "subject", "received_at"
FROM "citizen_messages"
WHERE "postbox_id" = :postboxId
  AND "deleted" = 0
  AND ("received_at", "id") < (:lastReceivedAt, :lastId)
ORDER BY "received_at" DESC, "id" DESC
FETCH FIRST 20 ROWS ONLY;
-- Cần composite index: (postbox_id, received_at DESC, id DESC)

-- ⚠️ OFFSET pagination (chậm khi offset lớn)
SELECT "id", "subject" FROM "citizen_messages"
WHERE "postbox_id" = :postboxId AND "deleted" = 0
ORDER BY "received_at" DESC
OFFSET 10000 ROWS FETCH NEXT 20 ROWS ONLY;
-- → offset 10000 = Oracle phải đọc 10020 rows rồi bỏ 10000
```

---

## 4. JPA/Hibernate Optimization

### Spring Boot config cho Oracle

```yaml
spring:
  datasource:
    url: jdbc:oracle:thin:@//localhost:1521/ORCL
    driver-class-name: oracle.jdbc.OracleDriver
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
  jpa:
    database-platform: org.hibernate.dialect.OracleDialect
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        default_batch_fetch_size: 20
        order_inserts: true
        order_updates: true
        jdbc:
          batch_size: 50
          fetch_size: 100
```

### Tránh N+1 Problem

```java
// ❌ N+1: load users → N queries cho mỗi user.roles
List<User> users = userRepo.findAll();
users.forEach(u -> u.getRoles().size()); // N queries!

// ✅ JOIN FETCH
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.roles WHERE u.status = :status")
List<User> findByStatusWithRoles(@Param("status") UserStatus status);

// ✅ @EntityGraph
@EntityGraph(attributePaths = {"roles"})
List<User> findByStatus(UserStatus status);

// ✅ @BatchSize trên Entity
@OneToMany(mappedBy = "user")
@BatchSize(size = 20)
private List<Order> orders;
```

### Native Query cho complex Oracle queries

```java
@Query(value = """
    SELECT m."id", m."subject", m."status",
           "fn_count_unread"(m."postbox_id") AS unread_count
    FROM "citizen_messages" m
    WHERE m."postbox_id" = :postboxId AND m."deleted" = 0
    ORDER BY m."received_at" DESC
    FETCH FIRST :limit ROWS ONLY
    """, nativeQuery = true)
List<Object[]> findMessagesWithUnreadCount(
    @Param("postboxId") Long postboxId,
    @Param("limit") int limit
);
```

---

## 5. Oracle Hints (dùng cẩn thận)

```sql
-- Force index (khi optimizer chọn full scan sai)
SELECT /*+ INDEX(m idx_messages_postbox_status) */
    "id", "subject"
FROM "citizen_messages" m
WHERE "postbox_id" = 123 AND "status" = 'UNSEEN';

-- Force parallel execution (cho query trên bảng rất lớn)
SELECT /*+ PARALLEL(m, 4) */ COUNT(*)
FROM "citizen_messages" m
WHERE "deleted" = 0;

-- Force hash join
SELECT /*+ USE_HASH(m p) */
    m."subject", p."postbox_name"
FROM "citizen_messages" m
JOIN "citizen_postbox" p ON m."postbox_id" = p."id";
```

> ⚠️ **Hints nên là giải pháp cuối cùng** — ưu tiên tạo index đúng và viết query tối ưu trước.

---

## 6. Partitioning (cho bảng lớn > 10M rows)

```sql
-- Range Partition theo thời gian (phổ biến nhất cho messages)
CREATE TABLE "citizen_messages_partitioned" (
    "id"          NUMBER GENERATED ALWAYS AS IDENTITY,
    "subject"     VARCHAR2(500),
    "received_at" TIMESTAMP NOT NULL,
    "deleted"     NUMBER(1) DEFAULT 0
)
PARTITION BY RANGE ("received_at") (
    PARTITION p_2025_q1 VALUES LESS THAN (TIMESTAMP '2025-04-01 00:00:00'),
    PARTITION p_2025_q2 VALUES LESS THAN (TIMESTAMP '2025-07-01 00:00:00'),
    PARTITION p_2025_q3 VALUES LESS THAN (TIMESTAMP '2025-10-01 00:00:00'),
    PARTITION p_2025_q4 VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00'),
    PARTITION p_2026_q1 VALUES LESS THAN (TIMESTAMP '2026-04-01 00:00:00'),
    PARTITION p_max     VALUES LESS THAN (MAXVALUE)
);

-- Tự động thêm partition (Oracle 12c+)
CREATE TABLE "audit_log" (...)
PARTITION BY RANGE ("created_at")
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(PARTITION p_init VALUES LESS THAN (TIMESTAMP '2025-01-01 00:00:00'));
```

---

## Checklist

- [ ] FK columns có index
- [ ] WHERE/JOIN/ORDER BY columns thường dùng có index
- [ ] Composite index thứ tự: equality → range → order
- [ ] Kiểm tra execution plan cho queries chậm
- [ ] Không có `TABLE ACCESS FULL` trên bảng lớn
- [ ] JPA batch_size, fetch_size đã config
- [ ] Không có N+1 problem (JOIN FETCH / @EntityGraph)
- [ ] SELECT chỉ cột cần thiết, không `SELECT *`
- [ ] Pagination dùng keyset cho large dataset
