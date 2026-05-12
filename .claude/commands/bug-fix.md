---
description: Quy trình fix bug trong các microservice
---

## Bước 1: Thu thập thông tin
- Hỏi rõ hiện tượng bug (error message, log, behavior)
- Xác nhận bug thuộc **service nào** (business-post, citizen-post, government-post, notification, digital-signature)
- Xác nhận **môi trường** xảy ra bug (dev/staging/production)

## Bước 2: Phân tích nguyên nhân
- Tìm file liên quan trong source code
- Đọc và phân tích code tại khu vực nghi ngờ
- Kiểm tra flow: Controller → Service → Repository → Domain
- Kiểm tra event/message handler nếu liên quan đến Kafka
- Kiểm tra gRPC/Feign client nếu liên quan đến inter-service communication

## Bước 3: Đề xuất giải pháp
- Giải thích root cause cho user
- Đề xuất cách fix cụ thể
- **BẮT BUỘC hỏi user xác nhận trước khi sửa code**

## Bước 4: Thực hiện fix
- Chỉ sửa đúng phần cần fix, không refactor thêm
- **KHÔNG xóa code cũ** mà không hỏi user
- Giữ nguyên coding style của project (Lombok, MapStruct, CQRS pattern)

## Bước 5: Kiểm tra
- Đảm bảo code compile: `./gradlew compileJava`
- Chạy test nếu có: `./gradlew test`
- Kiểm tra các file liên quan có bị ảnh hưởng không
- Liệt kê tất cả file đã thay đổi cho user review
- Liệt kê tất cả file đã thay đổi cho user review

