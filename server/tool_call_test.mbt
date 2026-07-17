///|
test "call_tool be-write 成功返回 ok" {
  let tmp = "/tmp/be-server-write-test.txt"
  let args : Json = { "file": tmp, "content": "hello\\nworld" }
  let result = @server.call_tool("be-write", args) catch {
    _ => {
      fail("be-write should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-write should return content array")
  }
  assert_eq(content.length(), 1)
  assert_true(
    content[0]
    is { "type": String("text"), "text": String("{\"status\":\"ok\"}"), .. },
  )
}

///|
test "call_tool be-replace 成功返回 EditResult" {
  let tmp = "/tmp/be-server-replace-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let args : Json = { "file": tmp, "start": 2, "end": 2, "content": "NEW" }
  let result = @server.call_tool("be-replace", args) catch {
    _ => {
      fail("be-replace should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-replace should return content array")
  }
  assert_eq(content.length(), 1)
  assert_true(content[0] is { "type": String("text"), "text": String(_), .. })
  @fs.remove_file(tmp)
}

///|
test "call_tool be-delete 成功返回 EditResult" {
  let tmp = "/tmp/be-server-delete-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\nthird\n")
  let args : Json = { "file": tmp, "start": 2, "end": 2 }
  let result = @server.call_tool("be-delete", args) catch {
    _ => {
      fail("be-delete should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-delete should return content array")
  }
  assert_eq(content.length(), 1)
  @fs.remove_file(tmp)
}

///|
test "call_tool be-insert 成功返回 EditResult" {
  let tmp = "/tmp/be-server-insert-test.txt"
  @fs.write_string_to_file(tmp, "first\nsecond\n")
  let args : Json = { "file": tmp, "after_line": 1, "content": "middle" }
  let result = @server.call_tool("be-insert", args) catch {
    _ => {
      fail("be-insert should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-insert should return content array")
  }
  assert_eq(content.length(), 1)
  @fs.remove_file(tmp)
}

///|
test "call_tool be-balance 成功返回结果" {
  let tmp = "/tmp/be-server-balance-test.txt"
  @fs.write_string_to_file(tmp, "( { [ ] } )")
  let args : Json = { "file": tmp }
  let result = @server.call_tool("be-balance", args) catch {
    _ => {
      fail("be-balance should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-balance should return content array")
  }
  assert_eq(content.length(), 1)
  @fs.remove_file(tmp)
}

///|
test "call_tool be-func-range 成功返回结果" {
  let tmp = "/tmp/be-server-func-test.go"
  @fs.write_string_to_file(tmp, "func main() {\n  println(1)\n}\n")
  let args : Json = { "file": tmp, "line": 1 }
  let result = @server.call_tool("be-func-range", args) catch {
    _ => {
      fail("be-func-range should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-func-range should return content array")
  }
  assert_eq(content.length(), 1)
  @fs.remove_file(tmp)
}

///|
test "call_tool be-tag-range 成功返回结果" {
  let tmp = "/tmp/be-server-tag-test.html"
  @fs.write_string_to_file(tmp, "<div><p>hi</p></div>\n")
  let args : Json = { "file": tmp, "line": 1 }
  let result = @server.call_tool("be-tag-range", args) catch {
    _ => {
      fail("be-tag-range should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-tag-range should return content array")
  }
  assert_eq(content.length(), 1)
  @fs.remove_file(tmp)
}

///|
test "call_tool be-trx status 返回队列统计" {
  let _ = @snapshot.commit_snapshots()
  let args : Json = { "action": "status" }
  let result = @server.call_tool("be-trx", args) catch {
    _ => {
      fail("be-trx status should not fail")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-trx should return content array")
  }
  assert_eq(content.length(), 1)
}

///|
test "call_tool be-read target function 按函数名解析范围" {
  let tmp = "/tmp/be-server-target-function.go"
  let content =
    #|package main
    #|
    #|func main() {
    #|  println("hello")
    #|}
  @fs.write_string_to_file(tmp, content)
  let args : Json = {
    "file": tmp,
    "target": { "kind": "function", "value": "main" },
    "brief": true,
  }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("be-read function target should not fail")
      null
    }
  }
  guard result is { "content": Array(items), .. } else {
    fail("be-read should return content array")
  }
  guard items[0] is { "type": String("text"), "text": String(text), .. } else {
    fail("be-read should return text content")
  }
  assert_true(text.contains("\"start_line\":3"))
  assert_true(text.contains("\"end_line\":5"))
  @fs.remove_file(tmp)
}

///|
test "call_tool be-read target marker 按标记串解析范围" {
  let tmp = "/tmp/be-server-target-marker.txt"
  @fs.write_string_to_file(tmp, "first line\nTODO: fix this\nthird line\n")
  let args : Json = {
    "file": tmp,
    "target": { "kind": "marker", "value": "TODO" },
    "brief": true,
  }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("be-read marker target should not fail")
      null
    }
  }
  guard result is { "content": Array(items), .. } else {
    fail("be-read should return content array")
  }
  guard items[0] is { "type": String("text"), "text": String(text), .. } else {
    fail("be-read should return text content")
  }
  assert_true(text.contains("\"start_line\":2"))
  assert_true(text.contains("\"end_line\":2"))
  @fs.remove_file(tmp)
}

///|
test "call_tool be-read target tag 按标签名解析范围" {
  let tmp = "/tmp/be-server-target-tag.html"
  @fs.write_string_to_file(tmp, "<div>\n  <p>hello</p>\n</div>\n")
  let args : Json = {
    "file": tmp,
    "target": { "kind": "tag", "value": "p" },
    "brief": true,
  }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("be-read tag target should not fail")
      null
    }
  }
  guard result is { "content": Array(items), .. } else {
    fail("be-read should return content array")
  }
  guard items[0] is { "type": String("text"), "text": String(text), .. } else {
    fail("be-read should return text content")
  }
  assert_true(text.contains("\"start_line\":2"))
  assert_true(text.contains("\"end_line\":2"))
  @fs.remove_file(tmp)
}

///|
test "call_tool be-delete target function 删除函数体" {
  let tmp = "/tmp/be-server-target-delete.go"
  let content =
    #|package main
    #|
    #|func helper() {
    #|  println(1)
    #|}
    #|
    #|func main() {}
  @fs.write_string_to_file(tmp, content)
  let args : Json = {
    "file": tmp,
    "target": { "kind": "function", "value": "helper" },
  }
  let result = @server.call_tool("be-delete", args) catch {
    _ => {
      fail("be-delete function target should not fail")
      null
    }
  }
  guard result is { "content": Array(_), .. } else {
    fail("be-delete should return content array")
  }
  let after = @fs.read_file_to_string(tmp)
  assert_true(!after.contains("func helper"))
  assert_true(after.contains("func main"))
  @fs.remove_file(tmp)
}

///|
test "call_tool be-read 非法 target kind 返回 isError" {
  let tmp = "/tmp/be-server-target-badkind.txt"
  @fs.write_string_to_file(tmp, "a\nb\n")
  let args : Json = { "file": tmp, "target": { "kind": "other", "value": "x" } }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("call_tool should convert BeError to isError response")
      null
    }
  }
  guard result is { "isError": true, "content": Array(content), .. } else {
    fail("unknown target kind should return isError: true")
  }
  guard content[0] is { "type": String("text"), "text": String(text), .. } else {
    fail("error response should contain text")
  }
  assert_true(text.contains("other") || text.contains("不支持"))
  @fs.remove_file(tmp)
}
