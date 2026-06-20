# better-edit-tools-mcp MoonBit 移植剩余工作清单

> 调查基准：
>
> - 原 Go 实现：`/home/clyzhi/disk/ai_workspace/better-edit-tools-mcp`
> - 当前 MoonBit 移植：`/home/clyzhi/disk/ai_workspace/better-edit-tools-mcp-rebuild-moonbit`
> - 当前状态：`moon test` 通过 **273** 个测试，MCP 服务器骨架、核心工具、session/snapshot/chip、i18n、降级写入、diff/preview 等已补齐。

## 2026-06-20 更新：Go 回归/边界测试补全

- 新增 `testutil` 包，提供 `with_temp_file` 用于真实 `/tmp` 临时文件 + 异常清理。
- 修复/补齐行为：负 `end` 语义、`be_delete` 保存 chip、`snapshot` 满队列 warning、function target 定义优先/CDATA 跳过。
- 迁移并新增边界测试覆盖 `read/write/edit/check/chip/snapshot/session/common/target` 等包。
- 当前所有测试通过：`moon test` 273 passed / 0 failed；已执行 `moon fmt && moon info`。

## 1. 项目目标与现状

### 1.1 最终目标

把原 Go 项目完整移植到 MoonBit，提供：

1. 一个可通过 `stdio` 与 MCP 客户端通信的 MCP 服务器。
2. 一个可直接运行的命令行工具（子命令 `read`/`replace`/`insert`/`delete`/`write`/`balance`/`func-range`/`tag-range`）。
3. 与原实现行为一致的核心工具：`be-read`、`be-replace`、`be-insert`、`be-delete`、`be-write`、`be-balance`、`be-func-range`、`be-tag-range`、`be-insert-chip`、`be-trx`。
4. 本地化（中/英）、原子写入、session 校验、快照回滚、chip 缓存、diff 输出、内容警告等辅助能力。

### 1.2 已移植内容

| 包         | 已实现文件             | 说明                                                                                |
| ---------- | ---------------------- | ----------------------------------------------------------------------------------- |
| `common`   | `common/common.mbt`    | `BeRange`、`BeLocation`、`compute_viewed_code_id`、`reject_chip_target`             |
| `error`    | `error/error.mbt`      | `BeError`（5 个变体）                                                               |
| `read`     | `read/read.mbt`        | `be_read`：支持 `path`、`path:start-end`、`path:start~end`、`path:line`             |
| `write`    | `write/write.mbt`      | `be_write`：单文件写入，支持 `chip://` 与字面 `\n` 转换                             |
| `edit`     | `edit/replace.mbt`     | `be_replace`：范围替换、`viewed_code_id` 校验、`old`/`old_text` 校验                |
| `edit`     | `edit/insert.mbt`      | `be_insert`：`line`/`after_line` 别名                                               |
| `edit`     | `edit/delete.mbt`      | `be_delete`：`lines` 数组或 `start`/`end`/`start_line`/`end_line` 范围              |
| `edit`     | `edit/insert_chip.mbt` | `be_insert_chip`：从 `file:///` 或 `chip://` 插入，支持列出 chip ID                 |
| `chip`     | `chip/chip.mbt`        | chip 缓存（`save`/`read`/`resolve`/`list`/`remove`/`clear`），上限 30，持久化到磁盘 |
| `check`    | `check/balance.mbt`    | `be_balance`：括号/引号/HTML 标签配对检查，`verbose` 模式                           |
| `check`    | `check/func_range.mbt` | `be_func_range`：基于 `{}` 的范围检测                                               |
| `check`    | `check/tag_range.mbt`  | `be_tag_range`：XML/HTML/Vue 标签配对范围                                           |
| `cmd/main` | `cmd/main/main.mbt`    | 占位入口，仅打印名称                                                                |

### 1.3 已知的重大缺口

- 没有 MCP 服务器/JSON-RPC 实现。
- 没有真正的 CLI 子命令解析。
- 没有 `target` 解析（`line`/`function`/`marker`/`tag`）。
- 没有文件路径行号后缀解析（`file.go:10`、`:5-15`、`:ALL`、Windows 盘符、`file://`）。
- 写入不是原子写入（无临时文件+重命名+fsync）。
- 没有 session 缓存（`viewed_code_id` 只是当前内容哈希，没有 TTL）。
- 没有快照/事务系统（`be-trx`）。
- 没有 diff 输出格式、preview 模式、内容警告。
- 没有二进制文件检测。
- 没有多文件写入与降级 JSON 解析。
- 缺少本地化 i18n。

---

## 2. 缺失功能详细清单（按优先级）

### [Done] P0 — MCP 服务器与 CLI 入口

这些是当前项目**完全无法作为 MCP 工具使用**的阻塞项。

#### [Done] 任务 2.1 实现 JSON-RPC / MCP 协议层

- **目标**：在 MoonBit 中实现一个读取 `stdin` 每行 JSON、输出 JSON-RPC 2.0 响应的 MCP 服务器骨架。
- **参考**：`internal/server/server.go`（原实现）。
- **需新增/修改**：
  - `server/server.mbt`：定义 `RpcRequest`、`RpcResponse`、`RpcError`、读取循环、`initialize`、`notifications/initialized`、`tools/list`、`tools/call` 分发。
  - `server/moon.pkg`：依赖 `read`/`write`/`edit`/`check`/`chip`/`error`/`common`。
- **验收标准**：
  - 向进程发送 `{"jsonrpc":"2.0","id":1,"method":"initialize"}` 能返回符合 MCP 协议的 `serverInfo` 与 `capabilities`。
  - 发送 `{"jsonrpc":"2.0","id":2,"method":"tools/list"}` 能返回 9–10 个工具的定义。
  - 工具调用出错时返回 `isError: true`。

#### [Done] 任务 2.2 实现工具调用路由与参数绑定

- **目标**：把 MCP 客户端发过来的参数映射到现有的 `be_*` 函数。
- **参考**：`internal/server/server.go` 中 `callTool` 的 `switch name` 分支。
- **需新增/修改**：
  - `server/handler.mbt`：对 `be-read`、`be-replace`、`be-insert`、`be-delete`、`be-write`、`be-func-range`、`be-tag-range`、`be-balance`、`be-insert-chip`、`be-trx` 做参数解析与调用。
  - 错误分支需要调用 `chip.SaveChip`（或等效函数）保存失败参数。
- **验收标准**：
  - 每个工具都能通过 MCP JSON 调用并返回与 Go 版本结构一致的 JSON。
  - `be-write` 失败后自动生成 `chip://{id}`。

#### [Done] 任务 2.3 实现命令行参数解析与子命令

- **目标**：`moon run cmd/main -- <command> [options]` 能执行单次操作并退出；无子命令时启动 MCP 服务器。
- **参考**：`internal/app/cli.go`、`internal/app/tool.go`。
- **需新增/修改**：
  - `cmd/main/main.mbt`：替换占位代码，解析 `--lang`、`--no-prefix`、`--version`、`--help`。
  - `cmd/main/cli.mbt`：解析子命令 `read`/`replace`/`insert`/`delete`/`write`/`balance`/`func-range`/`tag-range` 及其参数（`--file`、`-s`、`-e`、`-c`、`--old`、`--preview`、`--brief`、`--output` 等）。
- **验收标准**：
  - `./better-edit-tools read --file README.md --start 1 --end 10` 可运行。
  - `./better-edit-tools --lang zh` 以中文描述启动 MCP 服务器。

#### [Done] 任务 2.4 实现本地化（i18n）

- **目标**：工具描述与错误信息支持 `zh`/`en`。
- **参考**：`internal/server/i18n/*.json`、`internal/app/lang.go`。
- **需新增/修改**：
  - `i18n/zh.json` 与 `i18n/en.json`：工具名、描述、错误提示。
  - `common/i18n.mbt` 或 `server/i18n.mbt`：根据 `--lang` 或 `LANG` 环境变量返回对应字符串，缺省回退英文。
- **验收标准**：
  - `--lang zh` 时 `tools/list` 返回中文 `description`。
  - 找不到 key 时回退英文，不崩溃。

---

### [Done] P0 — 核心行为补齐

#### 任务 2.5 实现文件路径+行号后缀解析（已完成）

- **目标**：统一解析 `path/to/file.go:10`、`file.go:5-15`、`file.go:ALL`，兼容 Windows 盘符与 `file://` 协议。
- **参考**：`pkg/betools/parse_file_range.go`。
- **需新增/修改**：
  - `common/parse_file_range.mbt`：
    - `pub fn parse_file_range(String) -> (String, Int, Int) raise BeError`
    - `pub fn has_file_range(String) -> Bool`
  - 处理 `C:\path:10`、`:ALL`、负数行号、URL authority 中的冒号。
- **验收标准**：
  - `parse_file_range("src/main.go:5-10")` 返回 `("src/main.go", 5, 10)`。
  - `parse_file_range("C:\\foo.txt:3")` 返回 `("C:\\foo.txt", 3, 3)`。
  - `:ALL` 返回 `(-1, -1)`。

#### 任务 2.6 实现 `target` 解析（`be-read` 增强）（已完成）

- **目标**：`be-read` 支持 `target: { kind, value }`，根据行号/函数名/标记/tag 自动解析范围。
- **参考**：`pkg/betools/target.go`、`internal/server/server.go` 中 `be-read` 分支。
- **需新增/修改**：
  - `read/target.mbt`：
    - `pub(all) struct BeTarget { kind : String, value : String }`
    - `pub fn resolve_target_span(String, BeTarget) -> @common.BeRange raise BeError`
  - `read/read.mbt`：扩展 `be_read` 签名，支持 `target?` 参数。
- **支持的 kind**：
  - `line`：指定行号。
  - `function`：通过函数名定义行调用 `be_func_range`。
  - `marker`：搜索包含指定字符串的行。
  - `tag`：通过标签名调用 `be_tag_range`。
- **验收标准**：
  - `be_read("src/main.go", target={kind:"function", value:"main"})` 返回 `main` 函数的范围。

#### 任务 2.7 实现原子写入（已完成）

- **目标**：所有写操作通过临时文件 + 重命名 + fsync 完成，进程崩溃不损坏原文件；多文件写入支持事务回滚。
- **参考**：`pkg/betools/core.go`（`writeFileAtomic`、`writeFilesAtomic`、`rollbackCommitted`、`cleanupPlans`）。
- **需新增/修改**：
  - `write/atomic.mbt`：
    - `fn write_file_atomic(String, String) -> Unit raise BeError`
    - `fn write_files_atomic(Array[(String, String)]) -> Unit raise BeError`
  - 替换 `write/write.mbt`、`edit/*.mbt` 中直接调用 `@fs.write_string_to_file` 的地方。
- **验收标准**：
  - 写入成功后目标文件内容完整，临时文件已清理。
  - 多文件写入中途失败时，已提交文件能回滚到原始内容。

---

### [Done] P1 — Session、Snapshot、Chip 增强

#### 任务 2.8 实现 Session 缓存（已完成）

- **目标**：`be-read` 返回真正的 `viewed_code_id`（UUID），并在 `be-replace` 中校验行数是否变化。
- **参考**：`pkg/betools/session.go`、`internal/server/server.go` 中 `Read` 调用。
- **需新增/修改**：
  - `session/session.mbt`：
    - `pub fn create_session(String, Int, Int) -> String`
    - `pub fn session_from_cache(String) -> (ReadSession?, String)`（返回 session 与警告）
    - 24 小时 TTL、后台清理协程/定时器。
  - `read/read.mbt`：返回 `viewed_code_id` 时调用 `create_session`。
  - `edit/replace.mbt`：若传入 `viewed_code_id`，调用 `session_from_cache` 并附加警告。
- **验收标准**：
  - 两次读取同一范围得到不同 UUID。
  - 文件行数变化后使用旧 ID 替换返回非致命警告。

#### 任务 2.9 实现快照与事务（`be-trx`）（已完成）

- **目标**：每次编辑自动把修改前完整文件内容加入快照队列，支持 `commit`/`rollback`/`status`。
- **参考**：`pkg/betools/snapshot.go`、`internal/server/server.go` 中 `be-trx` 分支。
- **需新增/修改**：
  - `snapshot/snapshot.mbt`：
    - `pub fn push_snapshot(SnapshotRecord) -> (String, String)`
    - `pub fn commit_snapshots() -> Int`
    - `pub fn rollback_snapshots(Int) -> (Int, Array[BeError])`
    - `pub fn list_snapshots() -> Array[SnapshotRecord]`
    - `pub fn snapshot_queue_stats() -> QueueStats`
  - 持久化目录：`$XDG_CACHE_HOME/better-edit-tools-mcp/snapshots/<workspace-id>`。
  - 容量限制：最多 30 条、磁盘总量 100MB。
- **验收标准**：
  - 连续编辑三次后 `be-trx action=status` 显示 used=3。
  - `be-trx action=rollback step=1` 恢复到最后一次编辑前的文件内容。
  - `be-trx action=commit` 清空队列并删除持久化文件。

#### 任务 2.10 增强 Chip 系统（已完成）

- **目标**：失败工具调用保存完整参数（不仅是内容），`be-insert-chip` 能回放 chip 参数。
- **参考**：`pkg/betools/chip.go`、`internal/server/server.go` 中 `be-insert-chip` 分支。
- **需新增/修改**：
  - `chip/chip.mbt`：
    - 新增 `pub fn save_chip(tool : String, args : Map[String, String], err_msg : String) -> String`（ args 长度 > 50 才保存）。
    - 新增 `pub fn get_chip(String) -> ChipRecord`。
    - 新增 `pub fn chip_queue_info() -> ChipQueueInfo`。
    - 调整磁盘格式为 JSON（`chip-{id}.json`），包含 `tool`、`args`、`err_msg`、`created_at`。
  - `server/handler.mbt`：工具调用出错时调用 `save_chip`。
  - `edit/insert_chip.mbt`：支持从 chip 记录中重构内容并插入。
- **验收标准**：
  - `be-write` 因参数错误失败后，能列出对应 chip ID。
  - `be-insert-chip from=chip://{id} to=file:///x:5` 可回放。

---

### [Done] P1 — 工具输出与体验

#### 任务 2.11 统一编辑结果类型与 diff 输出（已完成）

- **目标**：`be-replace`/`be-insert`/`be-delete` 返回结构化结果，支持 `format=plain|diff`、`preview`、`brief`、内容警告、括号快速检查。
- **参考**：`pkg/betools/types.go`、`pkg/betools/ops.go`、`pkg/betools/diff.go`。
- **需新增/修改**：
  - `edit/result.mbt`：
    - `pub(all) struct EditResult { status, file, removed, added, total, diff, balance, affected, preview, brief, warnings, event_id, queue_full }`
  - `edit/diff.mbt`：
    - `fn build_diff(Array[String], Array[String], Int, String) -> String`
    - `fn quick_balance_check(String) -> String`
  - `edit/replace.mbt`、`edit/insert.mbt`、`edit/delete.mbt`：返回 `EditResult`。
- **验收标准**：
  - `format=diff` 输出 `@@ -l,n +l,n @@` 风格 diff。
  - `preview=true` 不写入文件但返回 diff。
  - `brief=true` 省略 diff。

#### 任务 2.12 实现内容警告（已完成）

- **目标**：写入/替换/插入/删除后检查 tab、行尾空白、文件末换行，并返回警告。
- **参考**：`pkg/betools/core.go` 中 `scanContentWarnings`、`isTabDominant`。
- **需新增/修改**：
  - `common/warnings.mbt`：`pub fn scan_content_warnings(String) -> Array[String]`。
- **验收标准**：
  - 写入带行尾空格的内容返回 `"content contains trailing whitespace..."`。
  - Makefile/Go 等以 tab 为主的文件不触发 tab 警告。

#### 任务 2.13 二进制文件检测（已完成）

- **目标**：`be-read` 等读取前拒绝二进制文件。
- **参考**：`pkg/betools/core.go` 中 `rejectBinary`、`isBinarySample`。
- **需新增/修改**：
  - `common/binary.mbt`：`pub fn reject_binary(String) -> Unit raise BeError`。
  - `read/read.mbt`、`edit/*.mbt`、`check/*.mbt` 调用它。
- **验收标准**：
  - 读取 PNG/ELF 等文件返回 `BeError::ReadError("... appears to be a binary file")`。

---

### P2 — 边界、测试与工程化

#### 任务 2.14 行尾符与空行处理（已完成）

- **目标**：正确处理 CRLF、保留原文件换行风格、最后一行无换行等情况。
- **参考**：`pkg/betools/core.go` 中 `detectLineEnding`、`splitKeepLineEnding`、`prepareContentLines`。
- **需新增/修改**：
  - `common/lines.mbt`：`detect_line_ending`、`split_keep_line_ending`、`prepare_content_lines`。
  - 替换各工具中直接 `text.split("\n")` 的实现。
- **验收标准**：
  - CRLF 文件写入后仍为 CRLF。
  - 空文件 `be_read` 返回 0 行且不崩溃。

#### 任务 2.15 实现多文件写入与降级 JSON 解析（已完成）

- **目标**：`be-write` 支持 `{"files":[{"file":"...","content":"..."}]}`，并在 JSON 异常时降级解析。
- **参考**：`pkg/betools/write.go`。
- **需新增/修改**：
  - `write/write.mbt`：
    - 将输入视为 JSON，先尝试标准解析；失败时调用字符级状态机 `parse_spec_raw`。
    - 支持 `extract` 标志，自动从 markdown 代码块提取内容。
  - 返回 `WriteResult`（包含 `degraded`、`files`、`results`、`warnings`）。
- **验收标准**：
  - 多文件 JSON 写入两个文件均成功。
  - 带未转义换行的 JSON 仍能通过降级解析写入。

#### 任务 2.16 统一错误变体（已完成）

- **目标**：扩展 `BeError`，使其能表达参数错误、路径相关错误、读写错误等。
- **参考**：`pkg/betools/error.go`。
- **需新增/修改**：
  - `error/error.mbt`：
    - 保留现有变体，新增 `InvalidArgument(String)`、`PathError(String)`、`IOError(String)` 等（按需）。
- **验收标准**：
  - 所有工具均返回 `BeError`，MCP 层统一转为 `isError: true`。

#### 任务 2.17 补全测试（已完成）

- **目标**：覆盖原 Go 项目的核心测试场景。
- **参考**：原项目 `pkg/betools/*_test.go`、`pkg/fs/*_test.go`、`internal/server/server_test.go`。
- **需新增/修改**：
  - `read/read_test.mbt`：路径解析、target 解析、二进制拒绝、CRLF、空文件。
  - `write/write_test.mbt`：多文件写入、降级解析、`extract`。
  - `edit/*_test.mbt`：preview、diff、warnings、viewed_code_id 校验、old 校验。
  - `snapshot/snapshot_test.mbt`：push/commit/rollback、容量限制、持久化。
  - `chip/chip_test.mbt`：`save_chip`、`get_chip`、跨进程恢复。
  - `server/server_test.mbt`：JSON-RPC 调用每个工具。
- **验收标准**：
  - `moon test` 测试数至少翻倍（原 Go 项目约 30+ 测试文件）。
  - 新增测试全部通过。

#### 任务 2.18 CI / 发布脚本（已完成）

- **目标**：与原项目一样提供 GitHub Actions 与安装脚本。
- **参考**：`.github/workflows/build.yml`、`.github/workflows/docs.yml`、`scripts/install.sh`、`.github/script/*.go`。
- **需新增/修改**：
  - `.github/workflows/build.yml`：运行 `moon test`、`moon fmt`、`moon info`、构建产物。
  - `scripts/install.sh`：下载 MoonBit 构建产物或平台二进制。
- **验收标准**：
  - PR 自动跑测试。
  - Release 能生成可下载产物。

---

## 3. 架构建议

### 3.1 推荐新增包结构

```
better-edit-tools-mcp/
├── cmd/main/          # CLI / MCP server 入口
├── server/            # MCP JSON-RPC 服务与工具路由
├── i18n/              # zh.json / en.json
├── chip/              # chip 缓存（已存在，需增强）
├── session/           # viewed_code_id 缓存
├── snapshot/          # 编辑快照与事务
├── fs/                # 文件系统抽象（OS + Mem）
├── common/            # 公共类型、路径解析、警告、二进制检测
├── read/              # be-read（已存在，需增强 target）
├── write/             # be-write（已存在，需增强多文件/降级）
├── edit/              # be-replace/insert/delete/insert-chip
├── check/             # be-balance/func-range/tag-range
└── error/             # BeError
```

### 3.2 执行顺序建议

1. **先实现 `common/parse_file_range.mbt` 与 `fs` 抽象**，因为很多工具依赖它。
2. **补齐 `write/atomic.mbt`**，让现有工具先具备原子写入。
3. **实现 `server` 骨架 + `cmd/main`**，使项目能作为 MCP 服务器启动（此时功能简单也够用）。
4. **逐个增强工具输出**（diff、preview、warnings）。
5. **实现 `session` 与 `snapshot`**，提供 `be-trx`。
6. **增强 `chip`** 与失败参数保存。
7. **补测试、README、CI**。

---

## 4. 风险与待决策事项

| 问题                                                          | 影响                     | 建议                                                                                                 |
| ------------------------------------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------- |
| MoonBit 当前目标为 `wasm-gc`，如何作为独立 CLI/MCP 进程运行？ | 阻塞发布                 | 调研 `moon run` 执行方式；若 wasm-gc 需外部 runtime，考虑改为 JS 目标用 Node 启动，或打包为 npm 包。 |
| 是否需要引入第三方 JSON-RPC/MCP 库？                          | 影响 `server` 实现复杂度 | MoonBit 生态若暂无成熟 MCP 库，建议先手写轻量 JSON-RPC；后续可替换。                                 |
| `be-write` 降级解析是否值得完整移植？                         | 工作量大                 | 是，这是原项目核心卖点之一（挽回 JSON 转义错误）。                                                   |
| 快照持久化是否跨平台？                                        | 影响测试                 | 优先保证 Linux/macOS，Windows 路径用 `@filepath` 处理。                                              |
| `viewed_code_id` 是否沿用当前哈希方案？                       | 影响 session 语义        | 建议改为 UUID + session 缓存，与 Go 版行为一致；或保留哈希作为校验 token，同时建立 session。         |

---

## 5. 验证命令

```bash
# 格式化与信息
cd /home/clyzhi/disk/ai_workspace/better-edit-tools-mcp-rebuild-moonbit
moon fmt
moon info

# 测试
moon test

# 运行入口（当前仅为占位）
moon run cmd/main

# 覆盖率（可选）
moon coverage analyze > uncovered.log
```

---

## 6. 快速对照表：原 Go 文件 → 建议 MoonBit 文件

| 原文件                            | 当前对应/建议文件                                                                  | 状态                            |
| --------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------- |
| `cmd/better-edit-tools/main.go`   | `cmd/main/main.mbt`                                                                | ❌ 占位                         |
| `internal/server/server.go`       | `server/server.mbt`、`server/handler.mbt`                                          | ❌ 未实现                       |
| `internal/app/cli.go`             | `cmd/main/cli.mbt`                                                                 | ❌ 未实现                       |
| `internal/app/tool.go`            | `cmd/main/cli.mbt`                                                                 | ❌ 未实现                       |
| `internal/app/lang.go`            | `common/i18n.mbt` + `i18n/*.json`                                                  | ❌ 未实现                       |
| `pkg/betools/core.go`             | `write/atomic.mbt`、`common/lines.mbt`、`common/warnings.mbt`、`common/binary.mbt` | ⚠️ 部分缺失                     |
| `pkg/betools/ops.go`              | `edit/*.mbt`                                                                       | ⚠️ 缺少 diff/preview/warnings   |
| `pkg/betools/write.go`            | `write/write.mbt`                                                                  | ⚠️ 缺少多文件/降级/result       |
| `pkg/betools/session.go`          | `session/session.mbt`                                                              | ❌ 未实现                       |
| `pkg/betools/snapshot.go`         | `snapshot/snapshot.mbt`                                                            | ❌ 未实现                       |
| `pkg/betools/chip.go`             | `chip/chip.mbt`                                                                    | ⚠️ 缺少 save_chip/get_chip/JSON |
| `pkg/betools/parse_file_range.go` | `common/parse_file_range.mbt`                                                      | ❌ 未实现                       |
| `pkg/betools/target.go`           | `read/target.mbt`                                                                  | ❌ 未实现                       |
| `pkg/betools/diff.go`             | `edit/diff.mbt`                                                                    | ❌ 未实现                       |
| `pkg/betools/balance.go`          | `check/balance.mbt`                                                                | ⚠️ 基本功能已有，格式差异       |
| `pkg/betools/func_range.go`       | `check/func_range.mbt`                                                             | ⚠️ 基本功能已有                 |
| `pkg/betools/tag_range.go`        | `check/tag_range.mbt`                                                              | ⚠️ 基本功能已有                 |
| `pkg/fs/*.go`                     | `fs/*.mbt`                                                                         | ❌ 未抽象                       |
| `pkg/betools/types.go`            | `common/common.mbt`、`edit/result.mbt`                                             | ⚠️ 部分缺失                     |

---

## 7. 可复用性设计（让核心逻辑能被其他包调用）

当前项目里的 `be_*` 函数虽然都是 `pub`，但它们是**面向 MCP/CLI 工具端点**设计的：直接读真实文件、直接写真实文件、逻辑和 I/O 混在一起。其他 MoonBit 包虽然可以 `import` 并调用，却很难做单元测试、替换存储后端或只借用其中一部分能力。

建议把每个工具拆成 **“纯逻辑函数 + I/O 入口”**，并引入统一的 `Config` / `FileSystem` 抽象。

### 7.1 拆分纯逻辑与 I/O

以 `edit/replace.mbt` 为例，应新增纯函数：

```moonbit
/// 对行数组做范围替换，不涉及文件 I/O
pub fn replace_lines(
  lines : Array[String],
  start_line : Int,
  end_line : Int,
  new_lines : Array[String]
) -> Array[String] { ... }
```

`be_replace` 则负责：读文件 → 调 `replace_lines` → 原子写回 → 返回 `EditResult`。

同理需要：

- `edit/insert.mbt`：`insert_lines(lines, after, new_lines) -> Array[String]`
- `edit/delete.mbt`：`delete_line_indices(lines, indices) -> Array[String]`
- `check/func_range.mbt`：`scan_blocks(lines) -> Array[Block]`
- `check/balance.mbt`：`scan_balance_text(text) -> BeBalanceResult`
- `common/lines.mbt`：`detect_line_ending`、`split_keep_line_ending`、`join_lines`

### 7.2 引入文件系统抽象 + 真实临时目录测试

新增 `fs` 包，定义 trait：

```moonbit
// fs/fs.mbt
pub trait FileSystem {
  read_file_to_string(String) -> String!IOError
  write_string_to_file(String, String) -> Unit!IOError
  path_exists(String) -> Bool
  is_file(String) -> Bool!IOError
  create_dir(String) -> Unit!IOError
  remove_file(String) -> Unit!IOError
  read_dir(String) -> Array[String]!IOError
  rename(String, String) -> Unit!IOError
}

/// 默认实现，基于 @fs
pub type OSFileSystem
```

所有 `be_*` 函数签名增加可选参数：

```moonbit
pub fn be_replace(
  file : String,
  start_line : Int,
  end_line : Int,
  content : String,
  fs? : FileSystem = OSFileSystem::new()
) -> Unit raise BeError
```

**测试策略：不用内存文件系统，改为真实临时目录 + `with_temp_dir` helper。**

MoonBit 没有 `finally` / `defer`，因此必须手动用 `try/catch` 包装：

```moonbit
// common/test_helper.mbt（测试专用）
fn with_temp_dir[T](f : (String) -> T raise) -> T raise {
  let dir = make_temp_dir()
  try {
    let result = f(dir)
    cleanup_dir(dir)
    result
  } catch {
    e => {
      // 测试已失败，清理失败不应覆盖原错误
      try { cleanup_dir(dir) } catch { _ => () }
      raise e
    }
  }
}

fn make_temp_dir() -> String { ... }
fn cleanup_dir(String) -> Unit { ... }
```

测试使用方式：

```moonbit
test "be_read returns FileNotFound for missing file" {
  let result = try? @common.with_temp_dir(fn(dir) {
    let path = dir + "/not-exist.mbt"
    @read.be_read(path) // 期望抛 FileNotFound
  })
  assert_true(result is Err(@error.BeError::FileNotFound(_)))
}
```

这样：

- 测试走的是真实 `@fs` 路径，能完整捕获错误链路；
- 成功或失败都会清理临时目录；
- 目录名带随机后缀，避免并发冲突。

### 7.3 统一 Config

用 `Config` 结构替代散落在各函数里的可选参数，方便后续扩展：

```moonbit
// common/config.mbt
pub(all) struct Config {
  fs : FileSystem
  lang : String
  no_prefix : Bool
  snapshot_enabled : Bool
  chip_dir : String?
  snapshot_dir : String?
}

pub fn default_config() -> Config { ... }
```

高层工具入口使用：

```moonbit
pub fn be_replace(
  file : String,
  start_line : Int,
  end_line : Int,
  content : String,
  config? : Config = default_config()
) -> ReplaceResult raise BeError
```

### 7.4 保持 `be_*` 作为高层入口

不要删除现有 `be_read` / `be_replace` / `be_insert` / `be_delete` / `be_write` / `be_balance` / `be_func_range` / `be_tag_range`，它们对 MCP server 和 CLI 正好够用。只需在它们下面再垫一层可复用的库函数。

### 7.5 新增/修改文件清单

| 目标         | 新增/修改文件                                                   | 说明                                            |
| ------------ | --------------------------------------------------------------- | ----------------------------------------------- |
| 文件系统抽象 | `fs/fs.mbt`、`fs/os_fs.mbt`                                     | trait + 默认 OS 实现                            |
| 统一配置     | `common/config.mbt`                                             | `Config` 与 `default_config`                    |
| 行处理工具   | `common/lines.mbt`                                              | 行尾符检测、切分、合并                          |
| 测试辅助     | `common/test_helper.mbt`                                        | `with_temp_dir`、`make_temp_dir`、`cleanup_dir` |
| 纯逻辑替换   | `edit/replace.mbt`                                              | 新增 `replace_lines`                            |
| 纯逻辑插入   | `edit/insert.mbt`                                               | 新增 `insert_lines`                             |
| 纯逻辑删除   | `edit/delete.mbt`                                               | 新增 `delete_line_indices`                      |
| 纯逻辑范围   | `check/func_range.mbt`                                          | 新增 `scan_blocks`                              |
| 纯逻辑平衡   | `check/balance.mbt`                                             | 新增 `scan_balance_text`                        |
| 修改入口签名 | `read/read.mbt`、`write/write.mbt`、`edit/*.mbt`、`check/*.mbt` | 增加 `fs?` 或 `config?` 参数                    |

### 7.6 对外复用示例

```moonbit
import {
  "conglinyizhi/better-edit-tools-mcp/edit",
}

fn my_tool(lines : Array[String]) -> Array[String] {
  // 只借用纯逻辑，不操作文件
  @edit.replace_lines(lines, 2, 4, ["fn new() {}", ""])
}
```

这样项目才能同时是：

- **一个可运行的 MCP 服务器 / CLI**；
- **一个可被其他 MoonBit 项目引用的编辑工具库**。

---

_清单生成时间：2026-06-17。后续每完成一项，应在此文件对应条目打勾，并更新 `.mbti` 与 README。_
