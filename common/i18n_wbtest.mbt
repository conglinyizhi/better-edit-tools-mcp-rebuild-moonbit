///|
/// 验证 try_load 对存在路径返回翻译表。
test "try_load returns Some for valid i18n file" {
  let map = try_load("./i18n/en.json")
  assert_true(map is Some(_))
  let m = map.unwrap()
  assert_true(
    m.get("cli.help.usage")
    is Some("Usage: better-edit-tools-mcp [command] [options]"),
  )
}

///|
/// 验证 try_load 对不存在路径返回 None。
test "try_load returns None for missing file" {
  let map = try_load("./no-such-i18n-dir/en.json")
  assert_true(map is None)
}
