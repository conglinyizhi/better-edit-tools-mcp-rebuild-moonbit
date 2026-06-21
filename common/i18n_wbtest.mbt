///|
test "default language is en" {
  set_language("en")
  assert_eq(current_language(), "en")
  assert_eq(
    t("tool.description.be-read"),
    "Read file content with line numbers.",
  )
}

///|
/// 验证切换到中文后返回中文翻译。
test "switch to zh" {
  set_language("zh")
  assert_eq(current_language(), "zh")
  assert_eq(
    t("tool.description.be-read"),
    "读取文件内容并显示行号。",
  )
  set_language("en")
}

///|
/// 验证非法语言回退到英文。
test "invalid language falls back to en" {
  set_language("fr")
  assert_eq(current_language(), "en")
  assert_eq(
    t("tool.description.be-read"),
    "Read file content with line numbers.",
  )
  set_language("en")
}

///|
/// 验证显式 lang 参数覆盖当前语言。
test "explicit lang overrides current language" {
  set_language("en")
  assert_eq(
    t("tool.description.be-read", lang="zh"),
    "读取文件内容并显示行号。",
  )
  set_language("zh")
  assert_eq(
    t("tool.description.be-read", lang="en"),
    "Read file content with line numbers.",
  )
  set_language("en")
}

///|
/// 验证缺失 key 先回退英文，再缺失则返回 key。
test "missing key falls back to english then returns key" {
  set_language("zh")
  assert_eq(t("error.UnknownTool"), "未知工具")
  assert_eq(t("not.a.real.key"), "not.a.real.key")
  set_language("en")
}

///|
/// 验证内嵌英文翻译表包含预期 key。
test "embedded english map contains expected keys" {
  let map = load_en_translations()
  assert_true(
    map.get("cli.help.usage")
    is Some("Usage: better-edit-tools-mcp [command] [options]"),
  )
  assert_true(map.get("cli.command.read") is Some("Read file content"))
}

///|
/// 验证内嵌中文翻译表包含预期 key。
test "embedded chinese map contains expected keys" {
  let map = load_zh_translations()
  assert_true(
    map.get("cli.help.usage")
    is Some("用法：better-edit-tools-mcp [命令] [选项]"),
  )
  assert_true(map.get("cli.command.read") is Some("读取文件内容"))
}
