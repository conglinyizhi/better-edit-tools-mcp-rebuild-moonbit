///|
test "resolve_target_span line single" {
  let tmp = "/tmp/be-target-line-single.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc\n")
  let range = resolve_target_span(tmp, { kind: "line", value: "2" })
  inspect(range.start_line, content="2")
  inspect(range.end_line, content="2")
  inspect(range.content, content="b")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span line range" {
  let tmp = "/tmp/be-target-line-range.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc\nd\n")
  let range = resolve_target_span(tmp, { kind: "line", value: "2-3" })
  inspect(range.start_line, content="2")
  inspect(range.end_line, content="3")
  inspect(range.content, content="b\nc")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span line ALL" {
  let tmp = "/tmp/be-target-line-all.txt"
  @fs.write_string_to_file(tmp, "a\nb\nc")
  let range = resolve_target_span(tmp, { kind: "line", value: "ALL" })
  inspect(range.start_line, content="1")
  inspect(range.end_line, content="3")
  inspect(range.content, content="a\nb\nc")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span function" {
  let tmp = "/tmp/be-target-function.go"
  let content =
    #|package main
    #|
    #|func main() {
    #|  println("hello")
    #|}
  @fs.write_string_to_file(tmp, content)
  let range = resolve_target_span(tmp, { kind: "function", value: "main" })
  inspect(range.start_line, content="3")
  inspect(range.end_line, content="5")
  inspect(range.content, content="func main() {\n  println(\"hello\")\n}")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span marker" {
  let tmp = "/tmp/be-target-marker.txt"
  let content =
    #|first line
    #|TODO: fix this
    #|third line
  @fs.write_string_to_file(tmp, content)
  let range = resolve_target_span(tmp, { kind: "marker", value: "TODO" })
  inspect(range.start_line, content="2")
  inspect(range.end_line, content="2")
  inspect(range.content, content="TODO: fix this")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span tag" {
  let tmp = "/tmp/be-target-tag.html"
  let content =
    #|<div>
    #|  <p>hello</p>
    #|</div>
  @fs.write_string_to_file(tmp, content)
  let range = resolve_target_span(tmp, { kind: "tag", value: "p" })
  inspect(range.start_line, content="2")
  inspect(range.end_line, content="2")
  inspect(range.content, content="  <p>hello</p>")
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span unsupported kind" {
  let tmp = "/tmp/be-target-unsupported.txt"
  @fs.write_string_to_file(tmp, "a\nb")
  try {
    let _ = resolve_target_span(tmp, { kind: "other", value: "x" })
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span function not found" {
  let tmp = "/tmp/be-target-function-missing.go"
  @fs.write_string_to_file(tmp, "package main\n")
  try {
    let _ = resolve_target_span(tmp, { kind: "function", value: "main" })
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span marker not found" {
  let tmp = "/tmp/be-target-marker-missing.txt"
  @fs.write_string_to_file(tmp, "a\nb")
  try {
    let _ = resolve_target_span(tmp, { kind: "marker", value: "TODO" })
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(tmp)
}

///|
test "resolve_target_span tag not found" {
  let tmp = "/tmp/be-target-tag-missing.html"
  @fs.write_string_to_file(tmp, "<div></div>")
  try {
    let _ = resolve_target_span(tmp, { kind: "tag", value: "p" })
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
  @fs.remove_file(tmp)
}
