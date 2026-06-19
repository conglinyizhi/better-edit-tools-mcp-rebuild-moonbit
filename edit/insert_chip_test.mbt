///|
test "insert from file:///tmp/..." {
  let target = "/tmp/be-insert-chip-target-001.txt"
  let source = "/tmp/be-insert-chip-source-001.txt"
  @fs.write_string_to_file(target, "第一行\n第二行\n第三行")
  @fs.write_string_to_file(source, "插入行")
  let result = @edit.be_insert_chip(target, line=1, from="file:///" + source)
  json_inspect(result, content="Inserted")
  let text = @fs.read_file_to_string(target)
  inspect(text, content="第一行\n插入行\n第二行\n第三行")
  @fs.remove_file(target)
  @fs.remove_file(source)
}

///|
test "insert from chip://id" {
  @chip.clear()
  let target = "/tmp/be-insert-chip-target-002.txt"
  @fs.write_string_to_file(target, "alpha\nbeta")
  let chip_id = @chip.save("gamma")
  let result = @edit.be_insert_chip(target, line=2, from="chip://" + chip_id)
  json_inspect(result, content="Inserted")
  let text = @fs.read_file_to_string(target)
  inspect(text, content="alpha\nbeta\ngamma")
  @fs.remove_file(target)
  @chip.remove(chip_id)
}

///|
test "list chip IDs when from is empty" {
  @chip.clear()
  let id_a = @chip.save("a")
  let id_b = @chip.save("b")
  let result = @edit.be_insert_chip(
    "/tmp/be-insert-chip-dummy-target.txt",
    from="",
  )
  guard result is ChipIds(ids) else { fail("expected ChipIds") }
  guard ids.contains(id_a) && ids.contains(id_b) else {
    fail("expected both chip ids in list")
  }
}

///|
test "line=0 inserts at beginning" {
  let target = "/tmp/be-insert-chip-target-003.txt"
  let source = "/tmp/be-insert-chip-source-003.txt"
  @fs.write_string_to_file(target, "first\nsecond")
  @fs.write_string_to_file(source, "zero")
  let result = @edit.be_insert_chip(target, line=0, from="file:///" + source)
  json_inspect(result, content="Inserted")
  let text = @fs.read_file_to_string(target)
  inspect(text, content="zero\nfirst\nsecond")
  @fs.remove_file(target)
  @fs.remove_file(source)
}

///|
test "error on missing chip file" {
  let target = "/tmp/be-insert-chip-target-004.txt"
  @fs.write_string_to_file(target, "content")
  try {
    let _ = @edit.be_insert_chip(
      target,
      from="chip://be-insert-chip-missing-xyz",
    )
    (fail("expected FileNotFound error") : Unit)
  } catch {
    @error.BeError::FileNotFound(_) => ()
    _ => (fail("expected FileNotFound error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(target)
}

///|
test "error on invalid from format" {
  let target = "/tmp/be-insert-chip-target-005.txt"
  @fs.write_string_to_file(target, "content")
  try {
    let _ = @edit.be_insert_chip(target, from="invalid-format")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(target)
}

///|
test "file not found for target" {
  try {
    let _ = @edit.be_insert_chip(
      "/tmp/be-insert-chip-missing-target-xyz.txt",
      from="file:///tmp/be-insert-chip-missing-source-xyz.txt",
    )
    (fail("expected FileNotFound error") : Unit)
  } catch {
    @error.BeError::FileNotFound(_) => ()
    _ => (fail("expected FileNotFound error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}

///|

///|
test "insert from chip://id replays full chip record" {
  @chip.clear()
  let target = "/tmp/be-insert-chip-replay-target.txt"
  @fs.write_string_to_file(target, "alpha\nbeta")
  let args = { "file": "/tmp/be-insert-chip-replay.txt", "content": "gamma" }
  let chip_id = @chip.save_chip("be-write", args, "Write failed")
  assert_true(chip_id.length() > 0)
  let result = @edit.be_insert_chip(target, line=2, from="chip://" + chip_id)
  json_inspect(result, content="Inserted")
  let text = @fs.read_file_to_string(target)
  assert_true(text.contains("\"tool\":\"be-write\""))
  assert_true(text.contains("gamma"))
  @fs.remove_file(target)
  @chip.remove(chip_id)
}

///|
test "be_insert_chip 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @edit.be_insert_chip("chip://some-id", from="file:///tmp/x.txt")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}
