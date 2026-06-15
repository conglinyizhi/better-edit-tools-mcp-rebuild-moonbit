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
  let target = "/tmp/be-insert-chip-target-002.txt"
  let chip_id = "be-insert-chip-test-002"
  let chip_path = "/tmp/better-edit-tools-chips/" + chip_id
  @fs.write_string_to_file(target, "alpha\nbeta")
  if !@fs.path_exists("/tmp/better-edit-tools-chips") {
    @fs.create_dir("/tmp/better-edit-tools-chips")
  }
  @fs.write_string_to_file(chip_path, "gamma")
  let result = @edit.be_insert_chip(target, line=2, from="chip://" + chip_id)
  json_inspect(result, content="Inserted")
  let text = @fs.read_file_to_string(target)
  inspect(text, content="alpha\nbeta\ngamma")
  @fs.remove_file(target)
  @fs.remove_file(chip_path)
}

///|
test "list chip IDs when from is empty" {
  let chip_dir = "/tmp/better-edit-tools-chips"
  if !@fs.path_exists(chip_dir) {
    @fs.create_dir(chip_dir)
  }
  let id_a = "be-insert-chip-list-a"
  let id_b = "be-insert-chip-list-b"
  let path_a = chip_dir + "/" + id_a
  let path_b = chip_dir + "/" + id_b
  @fs.write_string_to_file(path_a, "a")
  @fs.write_string_to_file(path_b, "b")
  let result = @edit.be_insert_chip(
    "/tmp/be-insert-chip-dummy-target.txt",
    from="",
  )
  json_inspect(result, content=[
    "ChipIds",
    ["be-insert-chip-list-a", "be-insert-chip-list-b"],
  ])
  @fs.remove_file(path_a)
  @fs.remove_file(path_b)
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
