---
description: Quy trình tìm hiểu code và phân tích kiến trúc của một service
---

## Bước 1: Xác nhận scope
- Hỏi user cần tìm hiểu **service nào** hoặc **feature nào**
- Xác nhận mục đích: hiểu tổng quan, tìm bug, chuẩn bị thêm feature, etc.

## Bước 2: Scan cấu trúc tổng quan
// turbo
- List thư mục `src/main/java/tech/app/` để xem core modules
- List thư mục `src/main/java/tech/features/` để xem feature modules
- Đọc `build.gradle` để xem dependencies
- Đọc `gradle.properties` để xem config versions

## Bước 3: Phân tích theo layer
- **Controller layer** (`controller/api/`, `controller/grpc/`): Xem API endpoints
- **Service layer** (`service/`): Xem business logic, CQRS pattern
- **Domain layer** (`domain/`): Xem entities, value objects
- **Repository layer** (`repository/`): Xem data access (JPA/MongoDB/Feign/gRPC)
- **Event layer** (`event/`): Xem Kafka message handlers
- **Bootstrap layer** (`bootstrap/`): Xem config, constants

## Bước 4: Phân tích luồng
- Trace từ Controller → Service → Repository cho use case cụ thể
- Kiểm tra inter-service communication (Feign/gRPC)
- Kiểm tra event-driven flows (Kafka producers/consumers)

## Bước 5: Báo cáo
- Tổng hợp kiến trúc dạng dễ hiểu cho user
- Vẽ diagram nếu cần (mermaid)
- Liệt kê các API endpoints chính
