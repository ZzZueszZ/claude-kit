---
name: Oracle PL/SQL
description: Hướng dẫn viết PL/SQL chuẩn — Stored Procedures, Functions, Packages, Cursors, Exception Handling
---

# Oracle PL/SQL

Chuẩn hóa viết PL/SQL cho Oracle Database.

---

## 1. Quy tắc đặt tên biến

| Loại | Prefix | Ví dụ |
|------|--------|-------|
| Variable | `v_` | `v_user_id`, `v_count` |
| Parameter IN | `p_` | `p_user_id`, `p_status` |
| Parameter OUT | `o_` | `o_result`, `o_error_code` |
| Cursor | `cur_` | `cur_users` |
| Constant | `c_` | `c_max_retry` |
| Exception | `e_` | `e_user_not_found` |

---

## 2. Stored Procedures

- Procedure cho **thao tác có side-effects** (INSERT, UPDATE, DELETE)
- **LUÔN** có exception handling
- **LUÔN** dùng prefix cho parameters/variables

```sql
CREATE OR REPLACE PROCEDURE "sp_soft_delete_user" (
    p_user_id    IN  NUMBER,
    p_updated_by IN  NUMBER,
    o_result     OUT NUMBER,
    o_message    OUT VARCHAR2
) AS
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists
    FROM "users" WHERE "id" = p_user_id AND "deleted" = 0;

    IF v_exists = 0 THEN
        o_result := -1;
        o_message := 'User not found: ' || p_user_id;
        RETURN;
    END IF;

    UPDATE "users"
    SET "deleted" = 1, "updated_at" = CURRENT_TIMESTAMP, "updated_by" = p_updated_by
    WHERE "id" = p_user_id AND "deleted" = 0;

    COMMIT;
    o_result := 0;
    o_message := 'Success';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        o_result := -2;
        o_message := 'Error: ' || SQLERRM;
END;
/
```

---

## 3. Functions

- Function cho **tính toán trả về giá trị** — KHÔNG có side-effects
- Có thể dùng trong SELECT, WHERE clause

```sql
CREATE OR REPLACE FUNCTION "fn_count_unread" (
    p_postbox_id IN NUMBER
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM "citizen_messages"
    WHERE "postbox_id" = p_postbox_id AND "status" = 'UNSEEN' AND "deleted" = 0;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN RETURN -1;
END;
/

-- Deterministic: Oracle cache kết quả
CREATE OR REPLACE FUNCTION "fn_format_status" (
    p_status IN VARCHAR2
) RETURN VARCHAR2 DETERMINISTIC AS
BEGIN
    RETURN CASE p_status
        WHEN 'ACTIVE' THEN 'Hoạt động'
        WHEN 'INACTIVE' THEN 'Tạm khóa'
        ELSE 'Không xác định'
    END;
END;
/
```

---

## 4. Cursors

### Cursor FOR Loop (khuyến nghị)

```sql
BEGIN
    FOR rec IN (
        SELECT "id", "username" FROM "users"
        WHERE "status" = 'ACTIVE' AND "deleted" = 0
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec."id" || ': ' || rec."username");
    END LOOP;
END;
/
```

### BULK COLLECT với LIMIT (large dataset)

```sql
DECLARE
    CURSOR cur_old IS
        SELECT "id" FROM "citizen_messages"
        WHERE "created_at" < ADD_MONTHS(SYSDATE, -12) AND "deleted" = 0;
    TYPE t_ids IS TABLE OF NUMBER;
    v_ids t_ids;
BEGIN
    OPEN cur_old;
    LOOP
        FETCH cur_old BULK COLLECT INTO v_ids LIMIT 1000;
        EXIT WHEN v_ids.COUNT = 0;
        FORALL i IN 1..v_ids.COUNT
            UPDATE "citizen_messages" SET "deleted" = 1 WHERE "id" = v_ids(i);
        COMMIT;
    END LOOP;
    CLOSE cur_old;
END;
/
```

---

## 5. Exception Handling

### Predefined Exceptions

| Exception | ORA Code | Mô tả |
|-----------|----------|--------|
| `NO_DATA_FOUND` | ORA-01403 | SELECT INTO không có row |
| `TOO_MANY_ROWS` | ORA-01422 | SELECT INTO nhiều row |
| `DUP_VAL_ON_INDEX` | ORA-00001 | Vi phạm UNIQUE |
| `VALUE_ERROR` | ORA-06502 | Lỗi kiểu dữ liệu |

### Custom Exception

```sql
-- Dùng RAISE_APPLICATION_ERROR cho custom errors (range -20000 đến -20999)
IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Label not found: ' || p_label_id);
END IF;
```

---

## 6. Packages

- Group related procedures/functions vào package
- Tên: `pkg_{domain}` → `pkg_message_mgmt`

```sql
-- Specification (public API)
CREATE OR REPLACE PACKAGE "pkg_message_mgmt" AS
    PROCEDURE mark_as_seen(p_message_id IN NUMBER, p_user_id IN NUMBER);
    FUNCTION get_unread_count(p_postbox_id IN NUMBER) RETURN NUMBER;
END;
/

-- Body (implementation)
CREATE OR REPLACE PACKAGE BODY "pkg_message_mgmt" AS
    PROCEDURE mark_as_seen(p_message_id IN NUMBER, p_user_id IN NUMBER) IS
    BEGIN
        UPDATE "citizen_messages"
        SET "status" = 'SEEN', "seen_at" = CURRENT_TIMESTAMP, "updated_by" = p_user_id
        WHERE "id" = p_message_id AND "status" = 'UNSEEN';
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    FUNCTION get_unread_count(p_postbox_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM "citizen_messages"
        WHERE "postbox_id" = p_postbox_id AND "status" = 'UNSEEN' AND "deleted" = 0;
        RETURN v_count;
    END;
END;
/
```

### Gọi package từ JPA

```java
@Repository
@RequiredArgsConstructor
public class MessageCustomRepository {
    private final EntityManager em;

    public void markAsSeen(Long messageId, Long userId) {
        StoredProcedureQuery query = em.createStoredProcedureQuery("pkg_message_mgmt.mark_as_seen");
        query.registerStoredProcedureParameter("p_message_id", Long.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("p_user_id", Long.class, ParameterMode.IN);
        query.setParameter("p_message_id", messageId);
        query.setParameter("p_user_id", userId);
        query.execute();
    }
}
```

---

## 7. Triggers

- **HẠN CHẾ** dùng trigger — ưu tiên application layer
- Chỉ dùng cho: auto-update timestamps, audit logging
- Tên: `trg_{table}_{action}`

```sql
CREATE OR REPLACE TRIGGER "trg_users_before_update"
BEFORE UPDATE ON "users"
FOR EACH ROW
BEGIN
    :NEW."updated_at" := CURRENT_TIMESTAMP;
END;
/
```

---

## Checklist

- [ ] Biến PL/SQL có prefix chuẩn (`v_`, `p_`, `o_`)
- [ ] Procedure/function có EXCEPTION handling
- [ ] Custom errors dùng `RAISE_APPLICATION_ERROR(-20xxx)`
- [ ] Related code gom vào package
- [ ] BULK COLLECT có LIMIT cho large dataset
- [ ] Function không có side-effects
- [ ] KHÔNG có business logic trong trigger
