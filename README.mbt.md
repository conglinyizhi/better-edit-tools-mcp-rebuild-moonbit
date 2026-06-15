# conglinyizhi/better-edit-tools-mcp

项目要求

实现 MCP 服务器，提供给 agent 若干工具

按实现优先级与依赖关系排序：

## 基础读写（无依赖）

- be-read 通过 /path/to/file.mbt:1-10 的方式选择少量内容进行阅读，同时返回一个 viewed_code_id 可用于后续 be-replace 的行数校验。
- be-write 原始写入工具，直接写入完整文件内容

## 独立检查（无依赖）

- be-balance 检查括号、花括号、方括号、HTML/XML 标签闭合以及引号是否成对。扫描时避开字符串与注释中的干扰符号。verbose 参数控制输出详细程度：
  false（默认）：只输出不匹配项
  true：输出全部匹配对

## 范围检测（可被 be-read 复用）

- be-func-range 定位某一行所属的 {} 块或函数范围。基于花括号计数，兼顾字符串和注释环境，比简单的分隔符查找更适合真实源码。
- be-tag-range 查找某一行所在的 XML/HTML/Vue 标签配对范围。相当于面向标记语言的范围定位工具。

## 基础编辑（依赖读写能力）

- be-insert 在指定行后插入内容，line=0 表示插入到文件开头。服务端也接受 after_line 作为同义参数。增量编辑中最直接的原语，减少对原有内容的扰动。
- be-delete 删除单行、行范围或 JSON 数组指定的多行。范围删除时同时接受 start/end 和 start_line/end_line 两种写法。始终围绕行粒度工作，强调操作的可预测性。

## 依赖型编辑

- be-replace 精确替换指定行范围的内容。支持通过 viewed_code_id 参数关联 be-read 的查询结果，自动校验行数是否一致。传入 old 时会校验当前文件内容是否与旧内容一致，不一致时直接返回错误。服务端也接受 old_text 作为别名。
- be-insert-chip 从文件（file:///绝对路径）或 chip 缓存（chip://{id}）读取内容并插入到指定行。不传 from 时列出所有可用的 chip ID。当 be-write 因 JSON 格式异常失败并将参数保存为 chip 后，可将该内容回放到目标文件中。

## 观察到的边界案例

KimiCode 当所有写文件工具写入一个没有上级目录的文件的时候，需要处理浪费 token 的情况，这个需要单独测试，后续设计工具的时候需要注意
