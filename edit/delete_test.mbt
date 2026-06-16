///|
test "delete a single line via lines" {
  let tmp = "/tmp/be-delete-single-line.txt"
  @fs.write_string_to_file(
    tmp, "第一行\n第二行\n第三行\n第四行\n第五行",
  )
  @edit.be_delete(tmp, lines=[2])
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
  @edit.be_delete(tmp, lines=[1, 3, 5])
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
  @edit.be_delete(tmp, start=2, end=4)
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
  @edit.be_delete(tmp, start_line=2, end_line=4)
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
