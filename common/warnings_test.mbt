///|
test "scan_content_warnings detects trailing whitespace" {
  let warnings = @common.scan_content_warnings("hello  \nworld")
  assert_true(warnings.contains("content contains trailing whitespace..."))
}

///|
test "scan_content_warnings detects missing final newline" {
  let warnings = @common.scan_content_warnings("hello\nworld")
  assert_true(warnings.contains("no newline at end of file"))
}

///|
test "scan_content_warnings does not warn for newline-terminated text" {
  let warnings = @common.scan_content_warnings("hello\nworld\n")
  assert_false(warnings.contains("no newline at end of file"))
}

///|
test "scan_content_warnings warns about tabs in space-based files" {
  let warnings = @common.scan_content_warnings("hello\n\tworld\n  x\n")
  assert_true(
    warnings.contains("content contains tabs; prefer spaces for indentation"),
  )
}

///|
test "scan_content_warnings does not warn for tab-dominant files" {
  let warnings = @common.scan_content_warnings("\thello\n\tworld\n")
  assert_false(
    warnings.contains("content contains tabs; prefer spaces for indentation"),
  )
}

///|
test "scan_content_warnings blank lines only do not trigger trailing whitespace" {
  let warnings = @common.scan_content_warnings("\n\n\n")
  assert_false(warnings.contains("trailing whitespace"))
  assert_false(warnings.contains("no newline at end of file"))
}

///|
test "scan_content_warnings blank line with spaces does not false positive" {
  let warnings = @common.scan_content_warnings("hello\n   \nworld\n")
  assert_false(warnings.contains("trailing whitespace"))
}

///|
test "scan_content_warnings empty content has no warnings" {
  let warnings = @common.scan_content_warnings("")
  assert_eq(warnings.length(), 0)
}

///|
test "scan_content_warnings single line without newline reports missing newline" {
  let warnings = @common.scan_content_warnings("hello")
  assert_true(warnings.contains("no newline at end of file"))
}

///|
test "scan_content_warnings multi-line newline-terminated text has no missing newline warning" {
  let warnings = @common.scan_content_warnings("hello\nworld\n")
  assert_false(warnings.contains("no newline at end of file"))
}
