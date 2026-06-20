///|
test "delete a single line via lines" {
  let tmp = "/tmp/be-delete-single-line.txt"
  @fs.write_string_to_file(
    tmp, "第一行\n第二行\n第三行\n第四行\n第五行",
  )
  let _ = @edit.be_delete(tmp, lines=[2])
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n第三行\n第四行\n第五行")
  @fs.remove_file(tmp)
}

///|
test "delete multiple lines via lines" {
  let tmp = "/tmp/be-delete-multiple-lines.txt"
  @fs.write_string_to_file(
    tmp, "第一行\n第二行\n第三行\n第四行\n第五行",
  )
  let _ = @edit.be_delete(tmp, lines=[1, 3, 5])
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第二行\n第四行")
  @fs.remove_file(tmp)
}

///|
test "delete a range via start/end" {
  let tmp = "/tmp/be-delete-range-start-end.txt"
  @fs.write_string_to_file(
    tmp, "第一行\n第二行\n第三行\n第四行\n第五行",
  )
  let _ = @edit.be_delete(tmp, start=2, end=4)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n第五行")
  @fs.remove_file(tmp)
}

///|
test "delete a range via start_line/end_line" {
  let tmp = "/tmp/be-delete-range-start-line-end-line.txt"
  @fs.write_string_to_file(
    tmp, "第一行\n第二行\n第三行\n第四行\n第五行",
  )
  let _ = @edit.be_delete(tmp, start_line=2, end_line=4)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n第五行")
  @fs.remove_file(tmp)
}

///|
test "error when both lines and range are given" {
  let tmp = "/tmp/be-delete-both-lines-and-range.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  try @edit.be_delete(tmp, lines=[1], start=2) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
  @fs.remove_file(tmp)
}

///|
test "error on out-of-range line" {
  let tmp = "/tmp/be-delete-out-of-range.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  try @edit.be_delete(tmp, lines=[5]) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
  @fs.remove_file(tmp)
}

///|
test "file not found" {
  try @edit.be_delete("/tmp/be-delete-missing-file.txt", start=1, end=2) catch {
    @error.BeError::FileNotFound(_) => ()
    _ => fail("expected FileNotFound error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "be_delete 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @edit.be_delete("chip://some-id", lines=[1])
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}

///|
test "be_delete 删除 function target 不吞噬相邻大括号" {
  @testutil.with_temp_file(base_name="delete-func", tmp => {
    let content =
      #|package main
      #|
      #|func first() {
      #|  return 1
      #|}
      #|
      #|func second() {
      #|  return 2
      #|}
      #|
      #|func third() {
      #|  return 3
      #|}
    @fs.write_string_to_file(tmp, content)
    let span = @read.resolve_target_span(tmp, @read.BeTarget::{
      kind: "function",
      value: "second",
    })
    let _ = @edit.be_delete(tmp, start=span.start_line, end=span.end_line)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("func first() {"))
    assert_true(text.contains("func third() {"))
    assert_false(text.contains("func second() {"))
  })
}

///|
test "be_delete 保存 chip 引用" {
  @testutil.with_temp_file(base_name="delete-chip", tmp => {
    @fs.write_string_to_file(tmp, "line1\nline2\nline3")
    let result = @edit.be_delete(tmp, start=2, end=2)
    let has_chip = result.warnings.iter().any(fn(w) { w.contains("chip://") })
    assert_true(has_chip)
    assert_eq(@fs.read_file_to_string(tmp), "line1\nline3")
  })
}
