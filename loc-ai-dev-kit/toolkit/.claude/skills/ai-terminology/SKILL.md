---
description: Tổng hợp thuật ngữ AI trending 2024-2025 cho developer
---

# 🧠 Thuật Ngữ AI Trending — Dành Cho Developer

## 1. Nền tảng cơ bản

| Thuật ngữ | Giải thích dễ hiểu | Ví dụ |
|-----------|-------------------|-------|
| **LLM** (Large Language Model) | Model AI được train trên text khổng lồ, hiểu & sinh text | GPT-4, Gemini, Claude, Llama |
| **Token** | Đơn vị nhỏ nhất LLM xử lý (~0.75 từ tiếng Anh) | "Hello world" ≈ 2 tokens |
| **Context Window** | Số token tối đa LLM nhớ được trong 1 lần chat | GPT-4: 128K, Gemini: 1M |
| **Temperature** | Điều chỉnh "sáng tạo" của AI (0=chính xác, 1=random) | Code gen → 0.2, viết văn → 0.8 |
| **Inference** | Quá trình chạy model để sinh kết quả (≠ training) | Gửi prompt → nhận response |
| **Fine-tuning** | Train thêm model có sẵn trên data riêng | Fine-tune GPT cho ngành y tế |

## 2. Prompt Engineering

| Thuật ngữ | Giải thích | Khi nào dùng |
|-----------|-----------|-------------|
| **System Prompt** | Hướng dẫn "nhân cách" cho AI trước khi chat | "Bạn là senior Java developer..." |
| **Few-shot** | Cho AI vài ví dụ mẫu để học theo | Cho 3 ví dụ input→output |
| **Zero-shot** | Yêu cầu AI làm mà không cần ví dụ | "Dịch sang tiếng Việt:" |
| **Chain-of-Thought (CoT)** | Bắt AI giải thích từng bước trước khi trả lời | "Hãy suy nghĩ step by step..." |
| **Prompt Chaining** | Nối nhiều prompt liên tiếp, output 1 → input 2 | Phân tích → Plan → Code → Test |

## 3. RAG & Embeddings (Quan trọng nhất cho dev!)

| Thuật ngữ | Giải thích | Ví dụ thực tế |
|-----------|-----------|--------------|
| **RAG** (Retrieval-Augmented Generation) | Tìm docs liên quan → đưa vào context → AI trả lời | Chat hỏi đáp về codebase |
| **Embedding** | Chuyển text → vector số (mảng 1536 số) | "Java" → [0.12, -0.34, ...] |
| **Vector Database** | DB lưu embeddings, tìm kiếm theo nghĩa | Pinecone, Chroma, Weaviate, pgvector |
| **Chunking** | Chia docs lớn thành mảnh nhỏ để embed | Chia file 1000 dòng → 20 chunks |
| **Semantic Search** | Tìm kiếm theo *ý nghĩa*, không phải keyword | "lỗi đăng nhập" tìm thấy "auth failure" |
| **Reranking** | Sắp xếp lại kết quả search cho chính xác hơn | Cohere Rerank, cross-encoder |

```
┌─────────────────── RAG Pipeline ───────────────────┐
│                                                     │
│  📄 Docs → [Chunk] → [Embed] → 🗄️ Vector DB       │
│                                                     │
│  ❓ Query → [Embed] → [Search DB] → Top K docs     │
│                         ↓                           │
│                  [LLM + Context] → 💬 Answer        │
└─────────────────────────────────────────────────────┘
```

## 4. AI Agents (Trending nhất 2025!)

| Thuật ngữ | Giải thích | Framework |
|-----------|-----------|-----------|
| **Agent** | AI tự quyết định dùng tool nào, gọi API nào | LangGraph, CrewAI |
| **Tool Calling** | AI gọi function/API — như AI biết dùng code | `search_db()`, `send_email()` |
| **Function Calling** | LLM output JSON để gọi function cụ thể | OpenAI Function Calling |
| **Multi-Agent** | Nhiều agent phối hợp, mỗi agent 1 vai trò | Agent Plan + Agent Code + Agent Test |
| **ReAct** | Reasoning + Acting: suy nghĩ → hành động → quan sát | "Tôi cần search DB... OK tìm thấy..." |
| **MCP** (Model Context Protocol) | Chuẩn kết nối AI với tools/data bên ngoài | Firebase MCP, GitHub MCP |
| **Agentic Workflow** | Flow tự động có nhiều bước AI quyết định | Code review → Fix → Test → Deploy |

```
┌──────────── Multi-Agent Architecture ────────────┐
│                                                   │
│   🧑‍💼 Planner Agent                               │
│     ↓ plan                                        │
│   👨‍💻 Coder Agent  ←→  🔧 Tools (DB, API, Git)    │
│     ↓ code                                        │
│   🧪 Tester Agent                                 │
│     ↓ results                                     │
│   📝 Reporter Agent                               │
└───────────────────────────────────────────────────┘
```

## 5. Frameworks phổ biến

| Framework | Ngôn ngữ | Dùng để | Độ khó |
|-----------|----------|---------|--------|
| **LangChain** | Python/JS | Xây pipeline AI, RAG, chatbot | ⭐⭐⭐ |
| **LangGraph** | Python | Agent workflow dạng graph | ⭐⭐⭐⭐ |
| **CrewAI** | Python | Multi-agent dễ dùng | ⭐⭐ |
| **LlamaIndex** | Python | RAG pipeline, index data | ⭐⭐⭐ |
| **Haystack** | Python | Search & RAG | ⭐⭐⭐ |
| **AutoGen** | Python | Multi-agent (Microsoft) | ⭐⭐⭐ |
| **Semantic Kernel** | C#/Python | AI cho .NET/Enterprise | ⭐⭐⭐ |
| **Spring AI** | Java | AI cho Spring Boot! | ⭐⭐ |
| **Vercel AI SDK** | JS/TS | AI cho web frontend | ⭐⭐ |

## 6. Model & Infra

| Thuật ngữ | Giải thích |
|-----------|-----------|
| **Open-source Model** | Model mở, chạy local: Llama 3, Mistral, Gemma |
| **Ollama** | Tool chạy LLM trên máy local (như Docker cho AI) |
| **vLLM** | Engine serve model nhanh, tối ưu throughput |
| **Quantization** (GGUF, GPTQ) | Nén model nhỏ hơn để chạy trên GPU yếu |
| **LoRA / QLoRA** | Fine-tune nhẹ, chỉ train thêm 1% params |
| **Mixture of Experts (MoE)** | Model lớn nhưng mỗi lần chỉ active 1 phần |
| **Multimodal** | Model hiểu cả text + hình + video + audio |
| **Grounding** | AI trả lời dựa trên facts, giảm hallucination |
| **Hallucination** | AI bịa thông tin nhưng nghe rất thuyết phục 😅 |

## 7. Áp dụng cho Java Developer

```
Bạn không cần học hết — focus vào:

1️⃣ RAG + Embeddings     → Chat với codebase/docs
2️⃣ Tool Calling          → AI gọi service của bạn
3️⃣ Spring AI             → Tích hợp AI vào Spring Boot
4️⃣ MCP                   → Kết nối AI với tools
5️⃣ Agentic Workflow      → Tự động hoá dev process
```
