///|
test "detect_line_ending detects LF" {
  assert_eq(@common.detect_line_ending("a\nb\n"), "\n")
}

///|
test "detect_line_ending detects CRLF" {
  assert_eq(@common.detect_line_ending("a\r\nb\r\n"), "\r\n")
}

///|
test "detect_line_ending defaults to LF for no newline" {
  assert_eq(@common.detect_line_ending("abc"), "\n")
}

///|
test "detect_line_ending prefers CRLF when more CRLF" {
  assert_eq(@common.detect_line_ending("a\r\nb\nc\r\n"), "\r\n")
}

///|
test "split_keep_line_ending preserves CRLF" {
  let lines = @common.split_keep_line_ending("a\r\nb\r\nc")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a\r\n")
  assert_eq(lines[1], "b\r\n")
  assert_eq(lines[2], "c")
}

///|
test "split_keep_line_ending preserves LF" {
  let lines = @common.split_keep_line_ending("a\nb\n")
  assert_eq(lines.length(), 2)
  assert_eq(lines[0], "a\n")
  assert_eq(lines[1], "b\n")
}

///|
test "split_keep_line_ending handles empty text" {
  let lines = @common.split_keep_line_ending("")
  assert_eq(lines.length(), 0)
}

///|
test "prepare_content_lines converts to CRLF" {
  let lines = @common.prepare_content_lines("a\nb\nc", "\r\n")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
  assert_eq(lines[2], "c")
}

///|
test "prepare_content_lines handles trailing newline" {
  let lines = @common.prepare_content_lines("a\nb\n", "\n")
  assert_eq(lines.length(), 2)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
}

///|
test "prepare_content_lines normalizes mixed endings" {
  let lines = @common.prepare_content_lines("a\r\nb\rc\n", "\n")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
  assert_eq(lines[2], "c")
}

///|
test "split_lines removes CRLF endings" {
  let lines = @common.split_lines("a\r\nb\r\nc")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
  assert_eq(lines[2], "c")
}

///|
test "split_lines handles empty text" {
  let lines = @common.split_lines("")
  assert_eq(lines.length(), 0)
}
