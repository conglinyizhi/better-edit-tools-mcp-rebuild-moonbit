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
test "list and clear chips" {
  let id_a = @chip.save("a")
  let id_b = @chip.save("b")
  let ids = @chip.list()
  inspect(ids.length(), content="2")
  guard ids.contains(id_a) && ids.contains(id_b) else {
    fail("expected both chip ids in list")
  }
  @chip.clear()
  inspect(@chip.list().length(), content="0")
}
