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
