///|
/// 当前语言，有效值为 "zh" 或 "en"。
let current_lang : Ref[String] = { val: "en" }

///|
/// 已加载的翻译表缓存，language -> (key -> value)。
let translations : Ref[Map[String, Map[String, String]]] = {
  val: Map::default(),
}

///|
/// 英文翻译表，直接嵌入二进制，避免运行时依赖外部 JSON 文件。
fn load_en_translations() -> Map[String, String] {
  let map = Map::default()
  map.set("tool.description.be-read", "Read file content with line numbers.")
  map.set(
    "tool.description.be-replace", "Replace a precise line range in a file.",
  )
  map.set("tool.description.be-insert", "Insert content after a specific line.")
  map.set("tool.description.be-delete", "Delete a line range from a file.")
  map.set("tool.description.be-write", "Write raw content to file(s).")
  map.set(
    "tool.description.be-func-range", "Find the enclosing function or brace block for a given line.",
  )
  map.set(
    "tool.description.be-tag-range", "Find the enclosing XML/HTML/Vue tag pair for a given line.",
  )
  map.set(
    "tool.description.be-balance", "Check bracket, brace, parenthesis, tag, and quote balance.",
  )
  map.set(
    "tool.description.be-insert-chip", "Insert content from a file (file://) or chip cache (chip://). Omit from to list all chip IDs.",
  )
  map.set(
    "tool.description.be-trx", "Transaction snapshot status, commit, or rollback.",
  )
  map.set(
    "warning.line_count_changed", "The file line count has changed since the read session was created.",
  )
  map.set("error.InvalidFormat", "Invalid format")
  map.set("error.InvalidArgument", "Invalid argument")
  map.set("error.FileNotFound", "File not found")
  map.set("error.NotARegularFile", "Not a regular file")
  map.set("error.PathError", "Path error")
  map.set("error.ReadError", "Read error")
  map.set("error.WriteError", "Write error")
  map.set("error.IOError", "IO error")
  map.set("error.UnknownTool", "Unknown tool")
  map.set("cli.help.usage", "Usage: better-edit-tools-mcp [command] [options]")
  map.set("cli.help.version", "Show version information")
  map.set("cli.help.global_flags", "Global flags")
  map.set("cli.command.read", "Read file content")
  map.set("cli.command.replace", "Replace file content")
  map.set("cli.command.insert", "Insert file content")
  map.set("cli.command.delete", "Delete file content")
  map.set("cli.command.write", "Write file content")
  map.set("cli.command.balance", "Check balance")
  map.set("cli.command.func-range", "Find function range")
  map.set("cli.command.tag-range", "Find tag range")
  map
}

///|
/// 中文翻译表，直接嵌入二进制，避免运行时依赖外部 JSON 文件。
fn load_zh_translations() -> Map[String, String] {
  let map = Map::default()
  map.set("tool.description.be-read", "读取文件内容并显示行号。")
  map.set("tool.description.be-replace", "替换文件中精确的行范围。")
  map.set("tool.description.be-insert", "在指定行后插入内容。")
  map.set("tool.description.be-delete", "删除文件中的行范围。")
  map.set("tool.description.be-write", "将原始内容写入文件。")
  map.set(
    "tool.description.be-func-range", "查找给定行所在的函数或花括号块范围。",
  )
  map.set(
    "tool.description.be-tag-range", "查找给定行所在的 XML/HTML/Vue 标签对范围。",
  )
  map.set(
    "tool.description.be-balance", "检查括号、花括号、圆括号、标签和引号的配对。",
  )
  map.set(
    "tool.description.be-insert-chip", "从文件 (file://) 或 chip 缓存 (chip://) 插入内容；省略 from 时列出所有 chip ID。",
  )
  map.set("tool.description.be-trx", "事务快照状态、提交或回滚。")
  map.set(
    "warning.line_count_changed", "文件行数自读取会话创建后已发生变化。",
  )
  map.set("error.InvalidFormat", "格式无效")
  map.set("error.InvalidArgument", "参数无效")
  map.set("error.FileNotFound", "文件不存在")
  map.set("error.NotARegularFile", "不是普通文件")
  map.set("error.PathError", "路径错误")
  map.set("error.ReadError", "读取错误")
  map.set("error.WriteError", "写入错误")
  map.set("error.IOError", "IO 错误")
  map.set("error.UnknownTool", "未知工具")
  map.set("cli.help.usage", "用法：better-edit-tools-mcp [命令] [选项]")
  map.set("cli.help.version", "显示版本信息")
  map.set("cli.help.global_flags", "全局标志")
  map.set("cli.command.read", "读取文件内容")
  map.set("cli.command.replace", "替换文件内容")
  map.set("cli.command.insert", "插入文件内容")
  map.set("cli.command.delete", "删除文件内容")
  map.set("cli.command.write", "写入文件内容")
  map.set("cli.command.balance", "检查配对")
  map.set("cli.command.func-range", "查找函数范围")
  map.set("cli.command.tag-range", "查找标签范围")
  map
}

///|
/// 加载指定语言的翻译表。翻译数据已嵌入二进制，直接返回对应 Map。
fn load_language(lang : String) -> Map[String, String] {
  if lang == "zh" {
    load_zh_translations()
  } else {
    load_en_translations()
  }
}

///|
/// 获取指定语言的翻译表，优先使用缓存。
fn get_translation(lang : String) -> Map[String, String] {
  match translations.val.get(lang) {
    Some(map) => map
    None => {
      let map = load_language(lang)
      translations.val.set(lang, map)
      map
    }
  }
}

///|
/// 设置当前语言。有效值 "zh" 或 "en"，其他值按英文回退。
pub fn set_language(lang : String) -> Unit {
  current_lang.val = if lang == "zh" || lang == "en" { lang } else { "en" }
}

///|
/// 获取当前语言。
pub fn current_language() -> String {
  current_lang.val
}

///|
/// 根据 key 返回翻译文本。`lang` 省略时使用 current_language()。
/// 若对应语言不存在或 key 不存在，先回退到英文，再不存在则返回 key。
pub fn t(key : String, lang? : String) -> String {
  let effective_lang = match lang {
    Some(l) => l
    None => current_lang.val
  }
  let map = get_translation(effective_lang)
  match map.get(key) {
    Some(value) => value
    None => {
      let en_map = get_translation("en")
      match en_map.get(key) {
        Some(value) => value
        None => key
      }
    }
  }
}
