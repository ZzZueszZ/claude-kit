---
description: Quy trình tạo database migration (Flyway SQL) cho các service
---

## Bước 1: Xác nhận yêu cầu
- Hỏi rõ migration thuộc **service nào**:
  - `business-post` → `projects/digipost/business-post/migration/core/sql/oracle/`
  - `citizen-post` → `projects/digipost/citizen-post/migration/core/sql/oracle/`
  - `government-post` → `projects/digipost/government-post/migration/core/sql/oracle/`
  - `notification` → `projects/digipost/notification/migration/core/sql/oracle/`
  - `digital-signature` → `projects/digipost/digital-signature/migration/core/sql/oracle/`
- Xác nhận loại migration: DDL (create/alter table) hay DML (insert/update data)

## Bước 2: Xác định version tiếp theo
// turbo
- Kiểm tra file migration mới nhất trong thư mục `core/sql/oracle/` của service tương ứng
- Version format: `V{YYYYMMDD}_{seq}__` 
  - Nếu ngày hôm nay chưa có migration → seq = `01`
  - Nếu ngày hôm nay đã có migration → tăng seq lên (02, 03...)

## Bước 3: Tạo file migration
- Đặt tên theo format: `V{YYYYMMDD}_{seq}__{type}_{description}.sql`
  - `{type}`: `ddl` cho DDL, `dml` cho DML
  - `{description}`: mô tả ngắn dùng underscore, ví dụ: `create_table_users`, `alter_table_messages`
- Database: **Oracle** — sử dụng Oracle SQL syntax
- Lưu ý Oracle-specific:
  - Dùng `NUMBER` thay vì `INT/BIGINT`
  - Dùng `VARCHAR2` thay vì `VARCHAR`
  - Dùng `CLOB` cho text dài
  - Dùng `TIMESTAMP` cho datetime
  - Sequence cho auto-increment

## Bước 4: Xác nhận
- Hiển thị nội dung file migration cho user review
- **KHÔNG tự động chạy Flyway migrate**
- **KHÔNG commit hoặc push**
