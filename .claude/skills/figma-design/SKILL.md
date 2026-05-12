---
name: Figma Design Skills
description: Hướng dẫn kỹ năng thiết kế UI/UX trên Figma - Design System, Components, Auto Layout, Prototyping, Dev Handoff
---

# Figma Design Skills

Các nguyên tắc và kỹ năng **BẮT BUỘC** khi thiết kế giao diện UI/UX trên Figma cho dự án phần mềm.

---

## 1. Design System & Tokens

> Mọi thiết kế phải dựa trên **Design System** nhất quán. KHÔNG thiết kế ad-hoc.

### Quy tắc bắt buộc
- **LUÔN** định nghĩa **Design Tokens** trước khi bắt đầu thiết kế
- **KHÔNG** dùng giá trị hardcode — luôn dùng variables/styles
- **LUÔN** dùng **8px grid system** cho spacing
- **LUÔN** tạo **Color Styles**, **Text Styles**, **Effect Styles** trong Figma

### Design Tokens cần có

```
📁 Design Tokens
├── 🎨 Colors
│   ├── Primary: Brand color chính (VD: #1A56DB)
│   ├── Secondary: Brand color phụ
│   ├── Neutral: Gray scale (50→900)
│   ├── Success: #10B981 (green)
│   ├── Warning: #F59E0B (amber)
│   ├── Error: #EF4444 (red)
│   ├── Info: #3B82F6 (blue)
│   └── Surface: Background colors
├── 📝 Typography
│   ├── Font Family: Inter / Roboto / Be Vietnam Pro
│   ├── Heading: H1(32px), H2(24px), H3(20px), H4(18px)
│   ├── Body: Large(16px), Medium(14px), Small(12px)
│   ├── Caption: 11px
│   └── Line Height: 1.5 (body), 1.25 (heading)
├── 📏 Spacing (8px grid)
│   ├── 4px (xxs), 8px (xs), 12px (sm)
│   ├── 16px (md), 24px (lg), 32px (xl)
│   └── 48px (2xl), 64px (3xl)
├── 🔲 Border Radius
│   ├── None: 0px
│   ├── Small: 4px
│   ├── Medium: 8px
│   ├── Large: 12px
│   └── Full: 9999px (pill)
└── 🌑 Shadows
    ├── sm: 0 1px 2px rgba(0,0,0,0.05)
    ├── md: 0 4px 6px rgba(0,0,0,0.1)
    └── lg: 0 10px 15px rgba(0,0,0,0.1)
```

### ✅ Đúng — Dùng Design Tokens
```
Button Primary:
  - Background: $color-primary-600
  - Text: $color-white
  - Border Radius: $radius-medium
  - Padding: $spacing-sm $spacing-md (12px 16px)
  - Font: $text-body-medium / Semi-bold
  - Shadow: $shadow-sm
```

### ❌ Sai — Hardcode values
```
Button:
  - Background: #2563EB  ← Hardcode, không dùng variable
  - Border Radius: 6px   ← Không align với grid
  - Padding: 10px 14px   ← Không align với 8px grid
  - Font: 13px           ← Không align với type scale
```

---

## 2. Component Architecture

> Component phải **reusable**, **consistent**, và hỗ trợ **variants**.

### Quy tắc bắt buộc
- **LUÔN** dùng **Auto Layout** cho mọi component
- **LUÔN** tạo **Variants** cho các state: Default, Hover, Active, Disabled, Error
- **LUÔN** dùng **Component Properties** (Boolean, Instance Swap, Text) thay vì tạo nhiều variant thừa
- **KHÔNG** detach component từ library — override properties thay vì detach
- **ĐÁNH SỐ** thứ tự layers hợp lý, dùng naming convention nhất quán

### Component Library cần có

```
📁 Components
├── 🔘 Buttons
│   ├── Primary / Secondary / Ghost / Destructive
│   ├── Sizes: Small (32px), Medium (40px), Large (48px)
│   └── States: Default, Hover, Active, Disabled, Loading
├── 📝 Inputs
│   ├── Text Input / Textarea / Select / Datepicker
│   ├── States: Default, Focus, Filled, Error, Disabled
│   └── With/Without: Label, Helper text, Error text, Icon
├── 📋 Tables
│   ├── Header Row / Data Row / Footer
│   ├── States: Default, Selected, Hover
│   └── Features: Sortable, Filterable, Pagination
├── 🃏 Cards
│   ├── Content Card / Stats Card / List Item
│   └── With/Without: Image, Actions, Badge
├── 🔔 Notifications
│   ├── Toast / Alert / Banner
│   └── Types: Success, Warning, Error, Info
├── 🧭 Navigation
│   ├── Sidebar / Top Nav / Breadcrumb / Tabs
│   └── States: Active, Inactive, Collapsed
├── 📦 Modals & Dialogs
│   ├── Confirm Dialog / Form Dialog / Alert Dialog
│   └── Sizes: Small, Medium, Large, Full screen
└── 📊 Data Display
    ├── Badge / Tag / Avatar / Status Indicator
    ├── Progress Bar / Skeleton Loader
    └── Empty State / Error State
```

### ✅ Đúng — Component có Variants đầy đủ
```
Component: Button
├── Property: Variant = Primary | Secondary | Ghost | Destructive
├── Property: Size = Small | Medium | Large
├── Property: State = Default | Hover | Active | Disabled | Loading
├── Property: Icon Left = (Boolean) true/false
├── Property: Icon Right = (Boolean) true/false
├── Property: Label = (Text) "Button"
└── Auto Layout: Horizontal, Spacing 8px, Padding 12px 16px
```

### ❌ Sai — Không dùng Variants
```
❌ Tạo frame riêng cho từng state:
  - Button-Primary-Default
  - Button-Primary-Hover
  - Button-Primary-Disabled
  (Không liên kết, update phải sửa từng cái)
```

---

## 3. Auto Layout Best Practices

### Quy tắc bắt buộc
- **MỌI component** phải dùng Auto Layout
- Dùng **Fill Container** cho responsive width, **Hug Contents** cho dynamic content
- Dùng **spacing** theo 8px grid
- Sử dụng **Min/Max width** cho responsive constraints
- **Nested Auto Layout** cho layout phức tạp

### ✅ Đúng — Auto Layout cho Form
```
Form Container (Auto Layout: Vertical, Gap: 24px, Padding: 32px)
├── Form Title (Hug/Fill)
├── Form Fields Group (Auto Layout: Vertical, Gap: 16px)
│   ├── Field Row (Auto Layout: Horizontal, Gap: 16px)
│   │   ├── Input: Họ tên (Fill, Min-W: 200px)
│   │   └── Input: Số CCCD (Fill, Min-W: 200px)
│   ├── Field Row (Auto Layout: Horizontal, Gap: 16px)
│   │   ├── Input: Email (Fill)
│   │   └── Input: SĐT (Fill)
│   └── Input: Địa chỉ (Fill - full width)
└── Actions (Auto Layout: Horizontal, Gap: 12px, Align: Right)
    ├── Button Secondary: "Huỷ"
    └── Button Primary: "Lưu"
```

### ❌ Sai — Dùng Absolute Position
```
❌ Đặt element bằng drag-n-drop với absolute position
❌ Hardcode width/height cho mọi element
❌ Không dùng spacing consistent
```

---

## 4. Page Structure & File Organization

### Quy tắc bắt buộc
- **MỖI file Figma** phải có cấu trúc pages rõ ràng
- **LUÔN** có page **Cover** với thumbnail và thông tin project
- **TÁCH** riêng pages theo chức năng
- **ĐÁNH SỐ** pages theo thứ tự

### Cấu trúc file chuẩn
```
📁 Project Figma File
├── 📄 Cover (Thumbnail + Project info)
├── 📄 0. Design Tokens (Colors, Typography, Spacing, Icons)
├── 📄 1. Components (Component Library)
├── 📄 2. Patterns (Common patterns: Auth flow, CRUD, Search...)
├── 📄 3. Pages — Module A
│   ├── 3.1 Danh sách (List view)
│   ├── 3.2 Chi tiết (Detail view)
│   ├── 3.3 Tạo mới (Create form)
│   └── 3.4 Chỉnh sửa (Edit form)
├── 📄 4. Pages — Module B
├── 📄 5. Responsive (Tablet, Mobile variants)
├── 📄 6. Prototyping (Interactive flows)
└── 📄 _Archive (Designs cũ, không dùng nữa)
```

### Frame Naming Convention
```
✅ Đúng:
  - "Dashboard / Overview"
  - "Hộp thư / Danh sách bưu phẩm"
  - "Hộp thư / Chi tiết bưu phẩm"
  - "Hộp thư / Soạn bưu phẩm / Step 1 - Nội dung"

❌ Sai:
  - "Frame 1"
  - "Untitled"
  - "Copy of Dashboard"
```

---

## 5. Responsive Design

### Quy tắc bắt buộc
- **LUÔN** thiết kế cho **3 breakpoints** chính: Desktop (1440px), Tablet (768px), Mobile (375px)
- **ƯU TIÊN** Desktop First cho admin system, Mobile First cho citizen app
- Dùng **Constraints** và **Auto Layout** để responsive tự nhiên
- **KIỂM TRA** readability trên mọi kích thước

### Breakpoints chuẩn

| Breakpoint | Width | Target | Layout |
|-----------|-------|--------|--------|
| Mobile | 375px | Smartphone | 1 column |
| Tablet | 768px | iPad | 2 columns |
| Desktop | 1440px | Laptop/Monitor | Sidebar + Content |
| Wide | 1920px | Large monitor | Max-width container |

### Layout Grid Settings
```
Desktop (1440px):
  - Columns: 12
  - Gutter: 24px
  - Margin: 80px (hoặc Sidebar 256px + Content)
  - Max content width: 1280px

Tablet (768px):
  - Columns: 8
  - Gutter: 16px
  - Margin: 24px

Mobile (375px):
  - Columns: 4
  - Gutter: 16px
  - Margin: 16px
```

---

## 6. Prototyping & Interaction

### Quy tắc bắt buộc
- **LUÔN** tạo prototype cho **happy path** chính
- Thêm **micro-interactions**: hover states, transitions, loading states
- Dùng **Smart Animate** cho transition mượt
- Tạo **interactive components** cho dropdown, modal, tab switching
- Prototype phải có **realistic data** — không dùng "Lorem ipsum"

### Interaction Patterns cần thiết

```
📋 Form Interactions:
  - Focus state khi click vào input
  - Validation error hiển thị real-time
  - Loading spinner khi submit
  - Success toast sau khi submit thành công
  - Confirm dialog trước hành động quan trọng

📊 Table Interactions:
  - Sort column (click header)
  - Filter panel (toggle open/close)
  - Row hover highlight
  - Checkbox select rows
  - Pagination navigation
  - Row click → navigate to detail

🧭 Navigation:
  - Sidebar collapse/expand
  - Active state highlight
  - Breadcrumb navigation
  - Tab switching with content change
```

### Transition Settings chuẩn
```
✅ Đúng:
  - Page transition: Smart Animate, 300ms, Ease Out
  - Modal open: Move In (Bottom), 250ms, Ease Out
  - Modal close: Move Out (Bottom), 200ms, Ease In
  - Dropdown: Smart Animate, 200ms, Ease Out
  - Toast: Move In (Top), 300ms, Ease Out → Auto dismiss 3s

❌ Sai:
  - Instant transition (không animation)
  - Quá chậm (>500ms cho micro-interaction)
  - Dùng Dissolve cho mọi thứ
```

---

## 7. Dev Handoff & Specifications

### Quy tắc bắt buộc
- **LUÔN** annotate spacing, sizing trong design
- Dùng **Dev Mode** trong Figma cho developer inspect
- **EXPORT** assets đúng format và kích thước
- **DOCUMENT** interaction behavior mà Figma không thể prototype

### Annotation Checklist
```
□ Spacing giữa các element (margin, padding)
□ Font style, size, weight, color cho mỗi text element
□ Color codes cho backgrounds, borders
□ Border radius
□ Shadow values
□ Icon sizes và names
□ Responsive behavior notes
□ Interaction descriptions (hover, click, transition)
□ Error states và validation messages
□ Loading states
□ Empty states
□ Max character limits cho text fields
```

### Export Settings chuẩn
```
Icons:
  - Format: SVG
  - Size: 16px, 20px, 24px variants
  - Color: currentColor (cho dynamic coloring)

Images:
  - Format: PNG hoặc WebP
  - Resolution: 1x, 2x (Retina)
  - Max file size: < 200KB

Illustrations:
  - Format: SVG (nếu có thể) hoặc PNG 2x
```

### Specification Documentation mẫu
```
Component: Danh sách bưu phẩm (Message List)

Layout:
  - Container: Full width, max-width 1280px
  - Padding: 24px
  - Gap between items: 1px (border separator)

List Item:
  - Height: 72px (hug content, min-height)
  - Padding: 16px 24px
  - Background: White (default), $color-primary-50 (unread)
  - Border bottom: 1px solid $color-neutral-200
  - Hover: Background $color-neutral-50

  Content:
  - Sender Name: $text-body-medium, Semi-bold, $color-neutral-900
  - Subject: $text-body-medium, Regular, $color-neutral-900
  - Preview: $text-body-small, Regular, $color-neutral-500, truncate 1 line
  - Time: $text-caption, Regular, $color-neutral-400, right-aligned
  - Unread indicator: 8px circle, $color-primary-600

Interactions:
  - Click row → Navigate to message detail
  - Long press (mobile) → Show context menu
  - Swipe left (mobile) → Show delete action
  - Pull to refresh → Refresh message list
```

---

## 8. Design Review Checklist

### Trước khi bàn giao cho Development

- [ ] Design Tokens đầy đủ (Colors, Typography, Spacing, Shadows)
- [ ] Tất cả components dùng Auto Layout
- [ ] Components có đủ Variants (states, sizes)
- [ ] File structure rõ ràng, pages được đánh số
- [ ] Frame naming convention nhất quán
- [ ] Responsive cho Desktop, Tablet, Mobile
- [ ] Prototype cho happy path chính
- [ ] Micro-interactions: hover, focus, loading, success/error
- [ ] Realistic data (không có "Lorem ipsum", "Test 123")
- [ ] Empty states và error states cho mọi page
- [ ] Dev annotations đầy đủ (spacing, colors, fonts)
- [ ] Assets exported đúng format (SVG icons, 2x images)
- [ ] Accessibility: contrast ratio ≥ 4.5:1, touch target ≥ 44px
- [ ] Consistent với Design System — không có element tự tạo ngoài system
- [ ] Stakeholder đã review và approve
