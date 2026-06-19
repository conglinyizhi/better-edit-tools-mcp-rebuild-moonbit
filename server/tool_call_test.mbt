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
