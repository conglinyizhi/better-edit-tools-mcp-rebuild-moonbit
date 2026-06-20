///|
test "create_session 返回 UUID 风格的 id" {
  let tmp = "/tmp/session-uuid-test.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let id = @session.create_session(tmp, 1, 2)
  assert_true(id.length() > 10)
  assert_true(id.contains("-"))
  @fs.remove_file(tmp)
}

///|
test "两次创建会话得到不同 id" {
  let tmp = "/tmp/session-unique-test.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let id1 = @session.create_session(tmp, 1, 2)
  let id2 = @session.create_session(tmp, 1, 2)
  assert_true(id1 != id2)
  @fs.remove_file(tmp)
}

///|
test "session_from_cache 能找到已创建的会话" {
  let tmp = "/tmp/session-cache-test.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let id = @session.create_session(tmp, 1, 3)
  let (session, warning) = @session.session_from_cache(id)
  assert_true(session is Some(_))
  assert_eq(warning, "")
  guard session is Some(s) else { return () }
  assert_eq(s.path, tmp)
  assert_eq(s.start_line, 1)
  assert_eq(s.end_line, 3)
  assert_eq(s.line_count, 3)
  @fs.remove_file(tmp)
}

///|
test "session_from_cache 对缺失 id 返回 None" {
  let (session, warning) = @session.session_from_cache("missing-id-12345")
  assert_true(session is None)
  assert_eq(warning, "")
}

///|
test "文件行数变化后 session_from_cache 返回警告" {
  let tmp = "/tmp/session-line-count-test.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let id = @session.create_session(tmp, 1, 3)
  @fs.write_string_to_file(tmp, "a\nb")
  let (session, warning) = @session.session_from_cache(id)
  assert_true(session is Some(_))
  assert_true(warning.length() > 0)
  @fs.remove_file(tmp)
}

///|
test "session_from_cache 对底层文件被删除返回警告" {
  let tmp = "/tmp/session-deleted-test.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let id = @session.create_session(tmp, 1, 3)
  @fs.remove_file(tmp)
  let (session, warning) = @session.session_from_cache(id)
  assert_true(session is Some(_))
  assert_true(warning.length() > 0)
}
