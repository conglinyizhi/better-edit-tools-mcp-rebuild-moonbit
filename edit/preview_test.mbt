///|
test "be_replace preview 不写入文件" {
  let tmp = "/tmp/be-replace-preview.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_replace(tmp, 2, 2, "NEW", preview=true)
  assert_eq(result.status, "preview")
  assert_eq(result.removed, 1)
  assert_eq(result.added, 1)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="first\nsecond\nthird\n")
  @fs.remove_file(tmp)
}

///|
test "be_replace preview 生成 diff" {
  let tmp = "/tmp/be-replace-preview-diff.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_replace(tmp, 2, 2, "NEW", format="diff", preview=true)
  assert_true(result.diff.contains("@@ -2,1 +2,1 @@"))
  assert_true(result.diff.contains("- second"))
  assert_true(result.diff.contains("+ NEW"))
  @fs.remove_file(tmp)
}

///|
test "be_replace preview 返回 warnings" {
  let tmp = "/tmp/be-replace-preview-warn.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\n")
  let result = @edit.be_replace(tmp, 2, 2, "NEW  ", preview=true)
  assert_true(result.warnings.length() > 0)
  @fs.remove_file(tmp)
}

///|
test "be_replace viewed_code_id 校验返回警告" {
  let tmp = "/tmp/be-replace-preview-id.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc\n")
  let id = @session.create_session(tmp, 1, 2)
  @fs.write_string_to_file(tmp, "a\nb\nc\nd\n")
  let result = @edit.be_replace(tmp, 2, 2, "X", viewed_code_id=id, preview=true)
  assert_true(result.warnings.length() > 0)
  @fs.remove_file(tmp)
}

///|
test "be_replace old 校验失败" {
  let tmp = "/tmp/be-replace-old-fail.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc\n")
  try {
    let _ = @edit.be_replace(tmp, 2, 2, "X", old="wrong")
    (fail("expected InvalidFormat") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat") : Unit)
  } noraise {
    _ => (fail("expected error") : Unit)
  }
  @fs.remove_file(tmp)
}

///|
test "be_insert preview 不写入文件" {
  let tmp = "/tmp/be-insert-preview.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\n")
  let result = @edit.be_insert(tmp, "middle", line=1, preview=true)
  assert_eq(result.status, "preview")
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="first\nsecond\n")
  @fs.remove_file(tmp)
}

///|
test "be_delete preview 不写入文件" {
  let tmp = "/tmp/be-delete-preview.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_delete(tmp, start=2, end=2, preview=true)
  assert_eq(result.status, "preview")
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="first\nsecond\nthird\n")
  @fs.remove_file(tmp)
}
