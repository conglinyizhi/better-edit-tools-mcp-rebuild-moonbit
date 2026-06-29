# better-edit-tools-mcp (MoonBit)

<div align="right">
  <a href="README.zh.md">中文</a> | <a href="README.md">English</a>
</div>

> 基于 MoonBit 的高性能 MCP（模型上下文协议）文件编辑工具包——原子写入、函数范围检测、快照回滚、容错 JSON 解析。
>
> 移植自同名 Go 项目 [better-edit-tools-mcp](https://github.com/conglinyizhi/better-edit-tools-mcp)（MIT License），使用 MoonBit 重写，面向 AI agent 工具链。
>
> 实验性项目：工具名称、参数和行为可能随设计演进调整。不要将特定工具名硬编码到 prompt 中；推荐基于能力的动态工具选择。
>
> 工具描述支持中英双语，通过 `--lang <zh|en>` 启动时切换，省略时回退到 `LANG` 环境变量。

## 安装

### 方式一：从 mooncakes.io 添加依赖

```bash
moon add conglinyizhi/better-edit-tools-mcp
```

### 方式二：从源码构建

```bash
git clone https://github.com/conglinyizhi/better-edit-tools-mcp-rebuild-moonbit.git
cd better-edit-tools-mcp-rebuild-moonbit
moon build --target native
```

### 方式三：直接运行

```bash
moon run --target native cmd/main -- --help
```

## 快速开始

### 作为 MCP 服务器运行

无参数启动即为 MCP 服务器，通过 stdin/stdout 的 JSON-RPC 与 MCP 客户端（如 Claude Desktop）通信：

```bash
moon run --target native cmd/main
```

使用中文工具描述：

```bash
moon run --target native cmd/main -- --lang zh
```

### 作为命令行工具使用

```bash
# 读取文件
moon run --target native cmd/main -- read --file src/main.mbt --start 1 --end 10

# 查找函数范围
moon run --target native cmd/main -- func-range --file src/main.mbt --start 15

# 检查括号配对
moon run --target native cmd/main -- balance --file src/main.mbt

# 替换内容
moon run --target native cmd/main -- replace --file src/main.mbt --start 3 --end 5 -c "new content"

# 插入内容（after_line=0 插入到文件开头）
moon run --target native cmd/main -- insert --file src/main.mbt --start 0 -c "// header comment"

# 删除行
moon run --target native cmd/main -- delete --file src/main.mbt --start 10 --end 12

# 写入文件
moon run --target native cmd/main -- write --file /tmp/out.txt -c "hello world"
```

## 工具列表

### `be-read`

只读源码检查工具。按行号读取文件内容，返回带行号的文本和 `viewed_code_id`（可传给 `be-replace` 做行数校验）。支持 `file:start-end` 格式和 `target`（`line`/`function`/`marker`/`tag`）自动解析。

——精确阅读你需要的范围，无需猜测外围函数边界。

### `be-replace`

精确的行范围替换。接受 `viewed_code_id` 参数校验行数一致性。传入 `old` 时先验证当前内容再写入，不一致则返回错误。

——最小的移动，最小的意外。

### `be-insert`

在指定行后插入内容。`after_line=0` 表示插入到文件开头。增量编辑中最直接的原语。

——精准插入，不触碰文件其他部分。

### `be-delete`

按行范围或 target 描述符删除。始终以行为粒度操作，结果可预测。

——可预测的行级删除。

### `be-write`

原始文件写入工具，支持单文件和多文件。当标准 JSON 解析失败时自动触发降级解析路径，拯救 AI 生成的含转义错误的 JSON。内容中的字面 `\n` 自动转换为真实换行。

——即便 JSON 封装损坏，仍尝试挽救载荷内容。

### `be-func-range`

定位指定行所在的 `{}` 块或函数范围。基于花括号计数，兼容字符串和注释环境。

——找到真正的函数边界，而非仅凭原始花括号猜测。

### `be-tag-range`

定位指定行所在的 XML/HTML/Vue 标签配对范围。面向标记语言的范围定位工具。

——找到编辑的真正边界——外围标签。

### `be-balance`

结构性语法检查：括号、花括号、圆括号、HTML/XML 标签闭合和引号配对。`verbose` 参数控制输出粒度：

- `false`（默认）：仅输出不匹配项
- `true`：输出所有匹配对

——在文件混合代码、标记和字符串时，尽早捕获结构性错误。

### `be-insert-chip`

从文件（`file:///absolute/path`）或 chip 缓存（`chip://{id}`）读取内容并插入指定行。省略 `from` 时列出所有可用 chip ID。当 `be-write` 因 JSON 格式错误失败并保存参数为 chip 后，可通过此工具回放。

——恢复失败操作，或从文件注入内容到精确位置。

### `be-trx`

事务快照管理。每次编辑自动保存修改前的文件快照（最多 30 条）。支持：

- `action=status`：查看当前快照队列
- `action=rollback step=N`：回滚最近 N 个快照
- `action=commit`：清空快照队列

——编辑出错了？一键回滚。

## 设计亮点

- **原子写入**：所有文件修改经过"临时文件 → 重命名 → fsync"周期，进程崩溃不损坏文件
- **isError 信号**：错误正确报告 `isError: true`（符合 MCP 规范）
- **容错 JSON 解析**：AI 生成内容常含反引号、`${}` 或未转义引号；`be-write` 自动回退到字符级提取
- **会话状态桥接**：`be-read` 返回 `viewed_code_id`，`be-replace` 可用其校验行数一致性
- **中英双语**：`--lang zh` 切换工具描述，参数名和行为不变
- **MoonBit 原生**：编译为原生二进制，零外部运行时依赖

## 作为库使用

核心工具逻辑以包的形式暴露，可在其他 MoonBit 项目中使用：

```mbt
import {
  "conglinyizhi/better-edit-tools-mcp/read",
  "conglinyizhi/better-edit-tools-mcp/edit",
  "conglinyizhi/better-edit-tools-mcp/check",
}

fn main {
  // 读取文件
  let result = @read.be_read("src/main.mbt", start=1, end=10)

  // 纯逻辑操作（不涉及文件 I/O）
  let new_lines = @edit.replace_lines(original_lines, 3, 5, ["new", "content"])
}
```

## 项目结构

```
better-edit-tools-mcp-rebuild-moonbit/
├── cmd/main/          # CLI / MCP 服务器入口
├── server/            # MCP JSON-RPC 服务器与工具路由
├── read/              # be-read 与 target 解析
├── write/             # be-write（原子写入、多文件、降级解析）
├── edit/              # be-replace / insert / delete / insert-chip / diff
├── check/             # be-balance / func-range / tag-range
├── chip/              # chip 缓存（失败参数保存与恢复）
├── snapshot/          # 编辑快照与事务（be-trx）
├── session/           # viewed_code_id 会话缓存
├── common/            # 公共类型、i18n、行处理、警告、二进制检测
├── error/             # BeError 错误类型
└── testutil/          # 测试辅助（临时文件/目录）
```

## 参考项目

本项目移植自 Go 语言实现的 [better-edit-tools-mcp](https://github.com/conglinyizhi/better-edit-tools-mcp)，原项目采用 MIT 许可证。MoonBit 移植版采用 Apache 2.0 许可证。

## 许可证

Apache License 2.0 — 详见 [LICENSE](./LICENSE)。
