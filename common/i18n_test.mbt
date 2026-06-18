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
test "missing key falls back to english then returns key" {
  set_language("zh")
  assert_eq(t("error.UnknownTool"), "未知工具")
  assert_eq(t("not.a.real.key"), "not.a.real.key")
  set_language("en")
}
