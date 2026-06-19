///|
test "save and read chip" {
  let id = @chip.save("hello chip")
  let content = @chip.read(id)
  inspect(content, content="hello chip")
  @chip.remove(id)
}

///|
test "read missing chip raises FileNotFound" {
  try {
    let _ = @chip.read("missing-id")
    (fail("expected FileNotFound error") : Unit)
  } catch {
    @error.BeError::FileNotFound(_) => ()
    _ => (fail("expected FileNotFound error") : Unit)
  }
}

///|
test "list chip ids contains saved ids" {
  let id_a = @chip.save("a")
  let id_b = @chip.save("b")
  let ids = @chip.list()
  guard ids.contains(id_a) && ids.contains(id_b) else {
    fail("expected both chip ids in list")
  }
  @chip.remove(id_a)
  @chip.remove(id_b)
}

///|
test "clear removes saved chip" {
  @chip.clear()
  let id = @chip.save("x")
  guard @chip.list().contains(id) else { fail("expected id after save") }
  @chip.clear()
  guard !@chip.list().contains(id) else {
    fail("expected id removed after clear")
  }
}

///|
test "evict oldest chips when exceeding max count" {
  @chip.clear()
  let ids = []
  for i in 0..<32 {
    ids.push(@chip.save("content-\{i}"))
  }
  let current = @chip.list()
  guard current.length() == 30 else {
    fail(
      "expected 30 chips after eviction, got " + current.length().to_string(),
    )
  }
  guard !current.contains(ids[0]) && !current.contains(ids[1]) else {
    fail("expected oldest two chips evicted")
  }
  guard current.contains(ids[31]) && current.contains(ids[30]) else {
    fail("expected newest chips retained")
  }
  @chip.clear()
}

///|
test "save_chip 保存完整参数并返回 chip id" {
  @chip.clear()
  let args = {
    "file": "/tmp/chip-test-long-args.txt",
    "content": "x".repeat(60),
  }
  let id = @chip.save_chip("be-write", args, "Write error")
  assert_true(id.length() > 0)
  let record = @chip.get_chip(id)
  assert_eq(record.tool, "be-write")
  assert_eq(record.err_msg, "Write error")
  assert_true(record.args.get("content") is Some(_))
  @chip.remove(id)
}

///|
test "save_chip 对短参数不保存" {
  let args = { "x": "1" }
  let id = @chip.save_chip("be-read", args, "Error")
  assert_eq(id, "")
}

///|
test "get_chip 对缺失 id 抛出 FileNotFound" {
  try {
    let _ = @chip.get_chip("missing-chip-id-xyz")
    fail("expected FileNotFound")
  } catch {
    @error.BeError::FileNotFound(_) => ()
    _ => fail("expected FileNotFound")
  }
}

///|
test "chip_queue_info 返回 count 与 capacity" {
  @chip.clear()
  let args = { "content": "x".repeat(60) }
  let _ = @chip.save_chip("be-write", args, "err")
  let info = @chip.chip_queue_info()
  assert_eq(info.capacity, 30)
  assert_true(info.count >= 1)
  @chip.clear()
}
