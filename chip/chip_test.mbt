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
