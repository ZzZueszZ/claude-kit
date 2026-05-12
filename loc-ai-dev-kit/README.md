# Loc AI Dev Kit

Base repo để version hóa và tái sử dụng Claude Code toolkit cho nhiều project.

## Cấu trúc

```txt
loc-ai-dev-kit/
  README.md
  toolkit/
    install.sh
    install.ps1
    .claude/
      commands/
      skills/
      agents/
    templates/
      CLAUDE.md
      CLAUDE.spring.md
      CLAUDE.node.md
```

## Mục tiêu

Repo này dùng để lưu các phần có thể tái sử dụng cho Claude Code:

- `.claude/commands`: slash commands dùng chung.
- `.claude/skills`: skills dùng chung.
- `.claude/agents`: agent definitions dùng chung.
- `templates/`: template `CLAUDE.md` theo loại project.
- `install.sh` / `install.ps1`: script copy toolkit vào project hiện tại.

## Cách version hóa thư viện

Nên tách toolkit thành repo Git riêng, ví dụ:

```txt
github.com/loc/claude-toolkit
```

Sau đó mỗi project dùng một trong 3 cách dưới đây.

### Cách A: Copy thủ công

Dễ nhất, phù hợp khi ít project hoặc muốn kiểm soát thủ công.

```bash
cp -r claude-toolkit/toolkit/.claude your-project/
cp claude-toolkit/toolkit/templates/CLAUDE.md your-project/CLAUDE.md
```

### Cách B: Git submodule

Ổn nếu đã quen Git submodule và muốn pin version toolkit theo từng project.

```bash
git submodule add https://github.com/loc/claude-toolkit .claude-toolkit
```

Sau đó copy hoặc symlink từ `.claude-toolkit/toolkit/.claude` sang `.claude` của project.

### Cách C: Install script

Thực dụng nhất cho team: pull repo toolkit rồi chạy script install vào project cần dùng.

Linux/macOS/Git Bash:

```bash
/path/to/claude-toolkit/toolkit/install.sh /path/to/your-project
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\claude-toolkit\toolkit\install.ps1 -TargetDir C:\path\to\your-project
```

Nếu không truyền target directory, script sẽ cài vào thư mục hiện tại.

## Cài đặt trên Linux/macOS/Git Bash

Từ project đích:

```bash
/path/to/loc-ai-dev-kit/toolkit/install.sh
```

Hoặc chỉ định project đích:

```bash
/path/to/loc-ai-dev-kit/toolkit/install.sh /path/to/your-project
```

Script sẽ:

1. Tạo `.claude/` nếu chưa có.
2. Copy `.claude/commands`, `.claude/skills`, `.claude/agents`.
3. Tạo `CLAUDE.md` từ `templates/CLAUDE.md` nếu project chưa có file này.
4. Không ghi đè `CLAUDE.md` hiện có.

## Cài đặt trên Windows PowerShell

Từ project đích:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\loc-ai-dev-kit\toolkit\install.ps1
```

Hoặc chỉ định project đích:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\loc-ai-dev-kit\toolkit\install.ps1 -TargetDir C:\path\to\your-project
```

## Dùng template theo stack

Sau khi install, có thể đổi template thủ công nếu cần:

Spring:

```bash
cp toolkit/templates/CLAUDE.spring.md your-project/CLAUDE.md
```

Node:

```bash
cp toolkit/templates/CLAUDE.node.md your-project/CLAUDE.md
```

Trên PowerShell:

```powershell
Copy-Item toolkit\templates\CLAUDE.spring.md your-project\CLAUDE.md
Copy-Item toolkit\templates\CLAUDE.node.md your-project\CLAUDE.md
```

## Gợi ý workflow

1. Cập nhật commands/skills/agents trong repo toolkit.
2. Commit và tag version, ví dụ `v0.1.0`.
3. Ở từng project, pull version mới hoặc update submodule.
4. Chạy lại install script để đồng bộ `.claude`.
5. Giữ `CLAUDE.md` riêng cho từng project vì file này thường chứa context đặc thù.
