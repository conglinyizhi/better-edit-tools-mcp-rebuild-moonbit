// 了解更多 moon.mod 配置信息：
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// 添加依赖请运行：
//   moon add moonbitlang/x
//
// 或在 `import` 中手动声明，例如：
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "conglinyizhi/better-edit-tools-mcp"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/conglinyizhi/better-edit-tools-mcp-rebuild-moonbit"

license = "Apache-2.0"

keywords = [ "mcp", "editor", "tools", "agent", "llm", "cli" ]

preferred_target = "wasm-gc"

description = "MoonBit MCP file editing toolkit — atomic writes, function-scope detection, snapshot rollback, and fault-tolerant JSON parsing for AI agent toolchains."

import {
  "moonbitlang/x@0.4.41",
}
