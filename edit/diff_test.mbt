///|
test "be_replace format=diff returns unified diff" {
  let tmp = "/tmp/be-replace-diff-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_replace(tmp, 2, 2, "NEW", format="diff", preview=true)
  assert_eq(result.status, "preview")
  assert_true(result.diff.contains("@@ -2,1 +2,1 @@"))
  assert_true(result.diff.contains("- second"))
  assert_true(result.diff.contains("+ NEW"))
  @fs.remove_file(tmp)
}

///|
test "be_replace brief=true omits diff" {
  let tmp = "/tmp/be-replace-brief-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_replace(
    tmp,
    2,
    2,
    "NEW",
    format="diff",
    preview=true,
    brief=true,
  )
  assert_eq(result.diff, "")
  @fs.remove_file(tmp)
}

///|
test "be_replace reports balance problem" {
  let tmp = "/tmp/be-replace-balance-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_replace(tmp, 2, 2, "(", preview=true)
  assert_true(result.balance.contains("unclosed"))
  @fs.remove_file(tmp)
}

///|
test "be_insert format=diff returns insertion diff" {
  let tmp = "/tmp/be-insert-diff-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\n")
  let result = @edit.be_insert(
    tmp,
    "middle",
    line=1,
    format="diff",
    preview=true,
  )
  assert_eq(result.status, "preview")
  assert_true(result.diff.contains("@@ -2,0 +2,1 @@"))
  assert_true(result.diff.contains("+ middle"))
  @fs.remove_file(tmp)
}

///|
test "be_delete format=diff returns deletion diff" {
  let tmp = "/tmp/be-delete-diff-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let result = @edit.be_delete(tmp, start=2, end=2, format="diff", preview=true)
  assert_eq(result.status, "preview")
  assert_true(result.diff.contains("@@ -2,1 +2,0 @@"))
  assert_true(result.diff.contains("- second"))
  @fs.remove_file(tmp)
}
