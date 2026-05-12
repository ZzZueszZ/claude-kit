---
name: Business Analysis Skills
description: Hướng dẫn kỹ năng phân tích nghiệp vụ (BA) - thu thập yêu cầu, viết user story, phân tích use case, tạo tài liệu BRD/SRS
---

# Business Analysis Skills

Các kỹ năng và nguyên tắc **BẮT BUỘC** khi thực hiện vai trò Business Analyst trong dự án phần mềm.

---

## 1. Thu thập và Phân tích Yêu cầu (Requirements Elicitation)

> Hiểu rõ bài toán nghiệp vụ TRƯỚC KHI viết bất kỳ dòng code nào.

### Quy tắc bắt buộc
- **LUÔN** xác định rõ **stakeholders** và vai trò của từng người
- **LUÔN** phân biệt rõ **Functional Requirements** (FR) và **Non-Functional Requirements** (NFR)
- **KHÔNG** giả định yêu cầu — phải có nguồn xác nhận (stakeholder, tài liệu, meeting notes)
- **LUÔN** xác định **scope** và **out-of-scope** rõ ràng
- **LUÔN** định nghĩa **acceptance criteria** cho mỗi yêu cầu

### Kỹ thuật thu thập yêu cầu

| Kỹ thuật | Khi nào dùng | Output |
|----------|-------------|--------|
| Interview | Hiểu sâu nghiệp vụ từ stakeholder | Meeting notes, pain points |
| Workshop | Cần consensus từ nhiều bên | Requirement list, priority |
| Observation | Hiểu workflow thực tế | Process flow, bottlenecks |
| Document Analysis | Hệ thống legacy, quy định pháp lý | Gap analysis |
| Prototyping | Yêu cầu chưa rõ ràng, cần visual | Wireframe, mockup |

### ✅ Đúng — Yêu cầu rõ ràng
```
FR-001: Hệ thống cho phép công dân đăng ký hộp thư số
- Actor: Công dân (đã xác thực qua VNeID)
- Precondition: Công dân có tài khoản VNeID mức độ 2
- Input: Họ tên, CCCD, SĐT, địa chỉ thường trú
- Output: Hộp thư số được tạo với mã UUID duy nhất
- Acceptance Criteria:
  1. Mỗi số CCCD chỉ được đăng ký 1 hộp thư
  2. Mã hộp thư tự sinh theo UUID v4
  3. Sau khi tạo, gửi thông báo xác nhận qua SMS
- Priority: Must Have
- Estimate: 5 story points
```

### ❌ Sai — Yêu cầu mơ hồ
```
FR-001: Hệ thống cho phép đăng ký hộp thư
(Thiếu: Actor là ai? Input gì? Output gì? Acceptance criteria?)
```

---

## 2. User Story & Use Case

### 2.1 User Story Format

> Format chuẩn: **As a [role], I want [goal], so that [benefit]**

### Quy tắc bắt buộc
- Mỗi user story phải có **acceptance criteria** (AC) rõ ràng
- Dùng format **Given-When-Then** cho AC
- Story phải **INVEST**: Independent, Negotiable, Valuable, Estimable, Small, Testable
- **KHÔNG** viết technical story — luôn viết từ góc nhìn user

### ✅ Đúng — User Story chuẩn INVEST
```
US-001: Gửi bưu phẩm số đến công dân

As a cán bộ hành chính,
I want to gửi bưu phẩm số đến hộp thư công dân,
So that công dân nhận được thông báo/quyết định hành chính kịp thời.

Acceptance Criteria:
  Given tôi đã đăng nhập với vai trò cán bộ hành chính
  And tôi đã soạn xong nội dung bưu phẩm
  When tôi chọn hộp thư công dân đích và nhấn "Gửi"
  Then bưu phẩm được gửi thành công
  And trạng thái bưu phẩm chuyển sang "Đã gửi"
  And công dân nhận được thông báo mới

Edge Cases:
  - Khi hộp thư đích không tồn tại → Hiển thị lỗi "Hộp thư không tồn tại"
  - Khi file đính kèm > 25MB → Hiển thị lỗi "Dung lượng vượt quá giới hạn"
  - Khi mất kết nối → Lưu nháp tự động, cho phép gửi lại
```

### ❌ Sai — User Story thiếu context
```
US-001: Gửi tin nhắn
As a user, I want to gửi tin nhắn, so that người khác nhận được.
(Thiếu: AC, edge cases, user role cụ thể)
```

### 2.2 Use Case Diagram & Description

### Quy tắc bắt buộc
- Mỗi use case phải có: **Actor, Precondition, Main Flow, Alternative Flow, Exception Flow, Postcondition**
- Đánh số bước tuần tự trong main flow
- Alternative flow reference về bước tương ứng trong main flow

### ✅ Đúng — Use Case mô tả đầy đủ
```
UC-003: Xem bưu phẩm số

Actor: Công dân
Precondition: Công dân đã đăng nhập, hộp thư đã được kích hoạt

Main Flow:
  1. Công dân mở danh sách bưu phẩm trong hộp thư
  2. Hệ thống hiển thị danh sách bưu phẩm (mới nhất trước)
  3. Công dân chọn bưu phẩm cần xem
  4. Hệ thống hiển thị nội dung chi tiết bưu phẩm
  5. Hệ thống cập nhật trạng thái sang "Đã xem"
  6. Hệ thống ghi nhận thời gian xem (seen_at)

Alternative Flow:
  2a. Không có bưu phẩm nào → Hiển thị "Hộp thư trống"
  3a. Bưu phẩm có file đính kèm → Hiển thị nút "Tải xuống"

Exception Flow:
  4a. Bưu phẩm đã bị xoá (deleted=true) → Hiển thị "Bưu phẩm không tồn tại"
  4b. Lỗi hệ thống → Hiển thị thông báo lỗi chung

Postcondition: Bưu phẩm được đánh dấu "Đã xem", seen_at được cập nhật
```

---

## 3. Tài liệu BRD & SRS

### 3.1 Business Requirements Document (BRD)

> BRD mô tả **VẤN ĐỀ NGHIỆP VỤ** và **MỤC TIÊU** cần đạt — KHÔNG mô tả giải pháp kỹ thuật.

### Cấu trúc BRD chuẩn
```
1. Executive Summary
2. Business Objectives
3. Current State (As-Is)
4. Future State (To-Be)
5. Scope
   5.1. In-Scope
   5.2. Out-of-Scope
6. Stakeholders
7. Business Requirements
   7.1. Functional Requirements
   7.2. Non-Functional Requirements
8. Business Rules
9. Assumptions & Constraints
10. Risks & Mitigation
11. Success Metrics (KPIs)
12. Glossary
```

### 3.2 Software Requirements Specification (SRS)

> SRS mô tả **CHI TIẾT KỸ THUẬT** hệ thống cần xây dựng.

### Cấu trúc SRS chuẩn (dựa trên IEEE 830)
```
1. Introduction
   1.1. Purpose
   1.2. Scope
   1.3. Definitions, Acronyms, Abbreviations
   1.4. References
2. Overall Description
   2.1. Product Perspective
   2.2. Product Functions
   2.3. User Classes and Characteristics
   2.4. Operating Environment
   2.5. Constraints
   2.6. Assumptions and Dependencies
3. Specific Requirements
   3.1. External Interface Requirements
   3.2. Functional Requirements (chi tiết từng module)
   3.3. Non-Functional Requirements
      - Performance
      - Security
      - Availability
      - Scalability
4. Data Requirements
   4.1. Data Dictionary
   4.2. ERD
5. Appendices
```

---

## 4. Process Modeling (BPMN)

### Quy tắc bắt buộc
- Dùng **BPMN 2.0** notation chuẩn
- Mỗi process phải có **Start Event** và **End Event** rõ ràng
- Xác định rõ **lanes** (swimlanes) cho từng actor/hệ thống
- **KHÔNG** để process flow mơ hồ — mọi nhánh phải có điều kiện rõ

### Mô tả luồng nghiệp vụ mẫu
```
Process: Gửi bưu phẩm số đến công dân

Lanes:
  - Cán bộ soạn thảo (Composer)
  - Cán bộ ký duyệt (Signer)
  - Hệ thống (System)
  - Công dân (Citizen)

Flow:
  [Start] → Cán bộ soạn thảo: Soạn nội dung bưu phẩm
         → Cán bộ soạn thảo: Đính kèm tệp tin (nếu có)
         → Cán bộ soạn thảo: Gửi yêu cầu ký duyệt
         → Cán bộ ký duyệt: Xem xét nội dung
         → [Gateway] Phê duyệt?
            → Có: Cán bộ ký duyệt: Ký số (digital signature)
                 → Hệ thống: Gửi bưu phẩm đến hộp thư công dân
                 → Hệ thống: Tạo thông báo (notification)
                 → Công dân: Nhận thông báo
                 → [End - Success]
            → Không: Cán bộ ký duyệt: Trả lại + ghi chú
                    → Cán bộ soạn thảo: Chỉnh sửa
                    → [Loop back to "Gửi yêu cầu ký duyệt"]
```

---

## 5. Data Dictionary & ERD

### Quy tắc bắt buộc
- Mỗi entity phải có **mô tả nghiệp vụ** rõ ràng (không chỉ mô tả kỹ thuật)
- Xác định **relationships** giữa các entity với **cardinality** cụ thể
- Đặt tên field theo **business meaning**, không dùng tên viết tắt
- Ghi chú rõ các **business rules** liên quan đến data

### ✅ Đúng — Data Dictionary rõ ràng
```
Entity: Hộp thư Công dân (citizen_postbox)
Business Description: Đại diện cho hộp thư số của mỗi công dân trong hệ thống,
  là nơi tiếp nhận bưu phẩm số từ cơ quan nhà nước và doanh nghiệp.

| Field | Type | Business Rule |
|-------|------|--------------|
| citizen_identification_number | VARCHAR(20) | Số CCCD 12 ký tự, unique trong hệ thống |
| citizen_phone_number | VARCHAR(15) | SĐT Việt Nam, bắt đầu bằng +84 hoặc 0 |
| citizen_gender | ENUM | Giá trị: MALE, FEMALE, OTHER |
| owner_id | BIGINT | FK → users.id, chủ tài khoản VNeID |

Relationships:
  - citizen_postbox 1 ←→ N citizen_messages (một hộp thư có nhiều bưu phẩm)
  - citizen_postbox 1 ←→ N folders (một hộp thư có nhiều thư mục)
  - citizen_postbox 1 ←→ N labels (một hộp thư có nhiều nhãn)
```

---

## 6. Acceptance Testing & UAT

### Quy tắc bắt buộc
- Viết **test case** từ acceptance criteria
- Mỗi test case phải có: ID, Description, Precondition, Steps, Expected Result, Priority
- Cover cả **happy path** và **edge cases**
- Dùng **traceability matrix** để map requirement → test case

### ✅ Đúng — Test Case chuẩn
```
TC-001: Đăng ký hộp thư công dân thành công
- Priority: High
- Precondition: Công dân có tài khoản VNeID mức 2, chưa có hộp thư
- Steps:
  1. Đăng nhập qua VNeID
  2. Chọn "Đăng ký hộp thư"
  3. Điền thông tin: Họ tên, CCCD, SĐT, Địa chỉ
  4. Nhấn "Hoàn tất đăng ký"
- Expected Result:
  - Hộp thư được tạo thành công
  - Hiển thị mã hộp thư (UUID)
  - Nhận SMS xác nhận
- Actual Result: [Điền khi test]
- Status: [Pass/Fail]

TC-002: Đăng ký hộp thư với CCCD đã tồn tại
- Priority: High
- Precondition: CCCD đã được dùng đăng ký hộp thư khác
- Steps:
  1. Đăng nhập qua VNeID
  2. Chọn "Đăng ký hộp thư"
  3. Điền thông tin với CCCD đã tồn tại
  4. Nhấn "Hoàn tất đăng ký"
- Expected Result:
  - Hiển thị lỗi: "Số CCCD đã được đăng ký hộp thư"
  - Không tạo hộp thư mới
```

---

## 7. Wireframe & Mockup Review

### Quy tắc bắt buộc khi review
- Kiểm tra **đầy đủ fields** theo requirement
- Kiểm tra **validation rules** hiển thị đúng
- Kiểm tra **error states** và **empty states**
- Kiểm tra **responsive** trên các thiết bị
- Kiểm tra **accessibility** (contrast, font size, alt text)
- Đảm bảo **UX flow** logic và intuitive

### Checklist review wireframe
```
□ Tất cả fields từ requirement đều có trên UI
□ Labels và placeholder text rõ ràng bằng tiếng Việt
□ Validation message hiển thị inline dưới field lỗi
□ Loading state khi submit form
□ Success/Error notification rõ ràng
□ Navigation breadcrumb đúng
□ Pagination cho danh sách
□ Search/filter cho danh sách lớn
□ Confirm dialog cho hành động quan trọng (xoá, gửi)
□ Empty state khi không có data
```

---

## 8. Ví dụ Thực tế — Module Nhãn Thông báo

> Module quản lý danh mục nhãn thông báo: CRUD, cấu hình hiển thị, và quy tắc tự động gán nhãn.

### 8.1 Tổng quan Module

```
Module: Nhãn Thông báo (Notification Labels)
Mục đích: Cho phép QTHT (Quản trị hệ thống) quản lý danh mục nhãn
  để phân loại, tổ chức và tự động gắn nhãn cho thông báo/bưu phẩm.

Chức năng chính:
  1. CRUD nhãn thông báo (Tạo, Xem, Sửa, Xoá)
  2. Cấu hình hiển thị nhãn (màu sắc, vị trí, thứ tự)
  3. Cấu hình quy tắc tự động gán nhãn (rule-based labeling)

Actors:
  - QTHT (Quản trị hệ thống): Quản lý danh mục, cấu hình hiển thị và rules
  - Hệ thống: Tự động gán nhãn theo rules đã cấu hình
  - Người dùng cuối: Xem nhãn trên thông báo
```

---

### 8.2 User Stories — CRUD Nhãn

```
US-LABEL-001: Xem danh sách nhãn thông báo

As a QTHT,
I want to xem danh sách tất cả nhãn thông báo đã tạo,
So that tôi nắm được các nhãn hiện có trong hệ thống.

Acceptance Criteria:
  Given tôi đã đăng nhập với vai trò QTHT
  When tôi truy cập menu "Danh mục > Nhãn thông báo"
  Then hệ thống hiển thị danh sách nhãn dạng bảng
  And mỗi dòng hiển thị: Tên nhãn, Màu sắc, Tag, Trạng thái, Ngày tạo
  And hỗ trợ tìm kiếm theo tên nhãn
  And hỗ trợ lọc theo trạng thái (Hoạt động / Ngừng hoạt động)
  And hỗ trợ phân trang (20 bản ghi/trang)
```

```
US-LABEL-002: Tạo nhãn thông báo mới

As a QTHT,
I want to tạo nhãn thông báo mới,
So that có thêm nhãn để phân loại thông báo.

Acceptance Criteria:
  Given tôi đang ở màn hình danh sách nhãn
  When tôi nhấn "Thêm mới"
  Then hệ thống hiển thị form tạo nhãn với các trường:
    - Tên nhãn (bắt buộc, tối đa 100 ký tự)
    - Tag (bắt buộc, tối đa 50 ký tự, chỉ chữ-số-gạch ngang)
    - Màu sắc (bắt buộc, color picker)
    - Cấp nhãn (tuỳ chọn, dropdown: cấp 1, cấp 2, cấp 3)
    - Nhãn cha (tuỳ chọn, dropdown danh sách nhãn cùng hộp thư)
    - Trạng thái (mặc định: Hoạt động)
  When tôi điền đầy đủ thông tin và nhấn "Lưu"
  Then nhãn được tạo thành công
  And hiển thị thông báo "Tạo nhãn thành công"
  And quay về danh sách nhãn

Edge Cases:
  - Tên nhãn đã tồn tại → Hiển thị lỗi "Tên nhãn đã tồn tại"
  - Tag đã tồn tại → Hiển thị lỗi "Tag đã được sử dụng"
  - Bỏ trống trường bắt buộc → Hiển thị validation inline
```

```
US-LABEL-003: Cập nhật nhãn thông báo

As a QTHT,
I want to chỉnh sửa thông tin nhãn thông báo,
So that cập nhật nhãn cho phù hợp với nhu cầu hiện tại.

Acceptance Criteria:
  Given tôi đang ở danh sách nhãn
  When tôi nhấn nút "Sửa" trên dòng nhãn cần chỉnh sửa
  Then hệ thống hiển thị form chỉnh sửa với dữ liệu hiện tại
  When tôi thay đổi thông tin và nhấn "Lưu"
  Then nhãn được cập nhật thành công
  And hiển thị thông báo "Cập nhật nhãn thành công"

Edge Cases:
  - Tên nhãn mới trùng với nhãn khác → Hiển thị lỗi
  - Nhãn đang được gán cho thông báo → Cho phép sửa, thông báo sẽ tự cập nhật
```

```
US-LABEL-004: Xoá nhãn thông báo

As a QTHT,
I want to xoá nhãn thông báo không cần thiết,
So that danh mục nhãn gọn gàng và dễ quản lý.

Acceptance Criteria:
  Given tôi đang ở danh sách nhãn
  When tôi nhấn nút "Xoá" trên dòng nhãn cần xoá
  Then hệ thống hiển thị dialog xác nhận: "Bạn có chắc chắn muốn xoá nhãn [tên nhãn]?"
  When tôi nhấn "Xác nhận"
  Then nhãn được xoá mềm (deleted = true)
  And hiển thị thông báo "Xoá nhãn thành công"
  And nhãn không còn hiển thị trong danh sách

Edge Cases:
  - Nhãn đang được gán cho thông báo → Hiển thị cảnh báo:
    "Nhãn đang được gán cho X thông báo. Xoá nhãn sẽ gỡ nhãn khỏi các thông báo này."
  - Nhãn có nhãn con → Hiển thị lỗi: "Không thể xoá nhãn đang có nhãn con"
```

---

### 8.3 Use Cases — Cấu hình Hiển thị Nhãn

```
UC-LABEL-DISPLAY: Cấu hình hiển thị nhãn

Actor: QTHT
Precondition: QTHT đã đăng nhập, có quyền quản trị danh mục

Main Flow:
  1. QTHT truy cập menu "Danh mục > Nhãn thông báo > Cấu hình hiển thị"
  2. Hệ thống hiển thị form thiết lập cách hiển thị nhãn gồm:
     - Kiểu hiển thị: Badge / Tag / Dot indicator / Text only
     - Vị trí hiển thị trên thông báo: Trước tiêu đề / Sau tiêu đề / Góc phải
     - Thứ tự ưu tiên hiển thị: Theo cấp nhãn / Theo thời gian gán / Tuỳ chỉnh (drag & drop)
     - Số lượng nhãn tối đa hiển thị: 1-5 (mặc định: 3)
     - Hiển thị nhãn trên danh sách: Có / Không
     - Hiển thị nhãn trên chi tiết: Có / Không
     - Preview: Xem trước giao diện hiển thị nhãn
  3. QTHT thiết lập các tuỳ chọn theo nhu cầu
  4. QTHT nhấn "Xem trước" để kiểm tra hiển thị
  5. Hệ thống hiển thị preview giao diện nhãn trên thông báo mẫu
  6. QTHT nhấn "Lưu cấu hình"
  7. Hệ thống lưu cấu hình và áp dụng ngay lập tức

Alternative Flow:
  4a. QTHT nhấn "Khôi phục mặc định" → Hệ thống reset về cấu hình mặc định
  6a. QTHT nhấn "Huỷ" → Không lưu, quay về danh sách

Exception Flow:
  7a. Lưu thất bại → Hiển thị lỗi "Không thể lưu cấu hình. Vui lòng thử lại."

Postcondition: Cấu hình hiển thị nhãn được cập nhật, tất cả thông báo
  hiển thị nhãn theo cấu hình mới.
```

**Data: Cấu hình Hiển thị Nhãn**

```
Entity: label_display_config

| Field | Type | Business Rule |
|-------|------|--------------|
| display_type | ENUM | Giá trị: BADGE, TAG, DOT, TEXT_ONLY. Mặc định: BADGE |
| position | ENUM | Giá trị: BEFORE_TITLE, AFTER_TITLE, RIGHT_CORNER. Mặc định: BEFORE_TITLE |
| sort_order | ENUM | Giá trị: BY_LEVEL, BY_ASSIGN_TIME, CUSTOM. Mặc định: BY_LEVEL |
| max_display_count | INTEGER | Giới hạn: 1-5. Mặc định: 3 |
| show_on_list | BOOLEAN | Mặc định: true |
| show_on_detail | BOOLEAN | Mặc định: true |
| property_id | BIGINT | FK → Mã đơn vị, mỗi đơn vị có cấu hình riêng |
```

---

### 8.4 Use Cases — Quy tắc Tự động Gán Nhãn

```
UC-LABEL-RULE: Cấu hình quy tắc tự động gán nhãn

Actor: QTHT
Precondition: QTHT đã đăng nhập, đã có ít nhất 1 nhãn trong danh mục

Main Flow:
  1. QTHT truy cập menu "Danh mục > Nhãn thông báo > Quy tắc tự động"
  2. Hệ thống hiển thị danh sách rules đã cấu hình (bảng)
  3. QTHT nhấn "Thêm quy tắc mới"
  4. Hệ thống hiển thị form thiết lập rule gồm:
     a. Thông tin chung:
        - Tên quy tắc (bắt buộc)
        - Mô tả (tuỳ chọn)
        - Nhãn được gán (bắt buộc, dropdown chọn nhãn)
        - Trạng thái: Bật / Tắt (mặc định: Bật)
        - Thứ tự ưu tiên: Số nguyên (quy tắc ưu tiên cao chạy trước)
     b. Điều kiện lọc (AND/OR logic):
        - Theo nội dung thông báo:
          + Tiêu đề chứa từ khoá (text input, hỗ trợ nhiều từ khoá)
          + Nội dung chứa từ khoá (text input)
        - Theo người gửi:
          + Mã người gửi (text input hoặc dropdown)
          + Tên đơn vị gửi (text input, hỗ trợ wildcard)
          + Hệ thống gửi (dropdown: Nội bộ / Liên thông / Tất cả)
        - Theo độ ưu tiên thông báo:
          + Mức ưu tiên (multi-select: Bình thường / Quan trọng / Khẩn cấp)
        - Theo phạm vi:
          + Loại hộp thư (multi-select: Công dân / Doanh nghiệp / Cơ quan)
  5. QTHT thiết lập điều kiện và nhấn "Kiểm tra thử" (dry run)
  6. Hệ thống hiển thị danh sách thông báo phù hợp với rule (preview, max 20 kết quả)
  7. QTHT xác nhận và nhấn "Lưu quy tắc"
  8. Hệ thống lưu rule và bắt đầu áp dụng cho thông báo mới

Alternative Flow:
  3a. QTHT chọn rule hiện có để sửa → Hiển thị form với dữ liệu hiện tại
  5a. Không có điều kiện nào → Hiển thị lỗi "Phải có ít nhất 1 điều kiện"
  6a. Không có thông báo nào phù hợp → Hiển thị "Không tìm thấy thông báo phù hợp"
  8a. QTHT chọn "Áp dụng cho thông báo cũ" → Hệ thống chạy rule trên thông báo hiện có (async job)

Exception Flow:
  4a. Không có nhãn nào → Hiển thị thông báo "Vui lòng tạo nhãn trước"
  8b. Rule trùng điều kiện với rule khác → Hiển thị cảnh báo nhưng vẫn cho lưu

Postcondition: Rule được lưu, thông báo mới đến sẽ tự động được gán nhãn
  nếu phù hợp điều kiện.
```

**Data: Quy tắc Tự động Gán Nhãn**

```
Entity: label_auto_assign_rule

| Field | Type | Business Rule |
|-------|------|--------------|
| id | BIGINT | PK, tự tăng |
| name | VARCHAR(200) | Tên quy tắc, bắt buộc |
| description | VARCHAR(500) | Mô tả, tuỳ chọn |
| label_id | BIGINT | FK → labels.id, nhãn sẽ được gán |
| status | ENUM | ACTIVE / INACTIVE. Mặc định: ACTIVE |
| priority | INTEGER | Thứ tự ưu tiên, nhỏ hơn = ưu tiên cao hơn |
| condition_logic | ENUM | AND / OR. Logic kết hợp các điều kiện |
| conditions | JSON | Danh sách điều kiện (xem chi tiết bên dưới) |
| apply_to_existing | BOOLEAN | Có áp dụng cho thông báo cũ không |
| property_id | BIGINT | FK → Mã đơn vị |

JSON Structure cho "conditions":
[
  {
    "type": "SUBJECT_CONTAINS",       // Tiêu đề chứa từ khoá
    "value": ["quyết định", "thông báo"]
  },
  {
    "type": "SENDER_CODE",             // Mã người gửi
    "value": ["GOV-001", "GOV-002"]
  },
  {
    "type": "SENDER_SYSTEM",           // Hệ thống gửi
    "value": ["INTERNAL"]              // INTERNAL, INTEROP, ALL
  },
  {
    "type": "PRIORITY",                // Mức ưu tiên
    "value": ["HIGH", "URGENT"]        // NORMAL, HIGH, URGENT
  },
  {
    "type": "POSTBOX_TYPE",            // Loại hộp thư
    "value": ["CITIZEN", "BUSINESS"]
  }
]
```

### 8.5 Luồng xử lý — Tự động Gán nhãn khi nhận thông báo

```
Process: Auto-assign Label on Message Received

Flow:
  [Start: Thông báo mới đến hộp thư]
    → Hệ thống: Lấy danh sách rules (status = ACTIVE, sắp theo priority)
    → [Loop] Với mỗi rule:
        → Hệ thống: Kiểm tra điều kiện (conditions) với thông báo
        → [Gateway] Thoả mãn tất cả/bất kỳ điều kiện (AND/OR)?
           → Có: Gán nhãn (label_id) cho thông báo
                → Tạo bản ghi label_messages
                → [Tiếp tục rule tiếp theo]
           → Không: [Bỏ qua, tiếp tục rule tiếp theo]
    → [End Loop]
    → [End: Hoàn tất gán nhãn]

Lưu ý:
  - Một thông báo có thể được gán nhiều nhãn (nếu thoả nhiều rules)
  - Rule chạy theo thứ tự priority (nhỏ → lớn)
  - Nếu thông báo đã có nhãn → Không gán trùng
```

---

## Checklist trước khi bàn giao cho Development

- [ ] Tất cả requirements có acceptance criteria
- [ ] User stories đúng format INVEST
- [ ] Use cases có đủ main flow, alternative flow, exception flow
- [ ] Data dictionary đầy đủ business rules
- [ ] ERD đã được review bởi tech lead
- [ ] Wireframes đã được approve bởi stakeholder
- [ ] Test cases cover happy path và edge cases
- [ ] Traceability matrix: Requirement → User Story → Test Case
- [ ] Glossary/từ điển nghiệp vụ đầy đủ
- [ ] Risks và assumptions được document
