///|
test "initialize 返回协议版本、服务器信息与能力" {
  let lines = ["{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}"]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response
    is { "jsonrpc": String("2.0"), "id": Number(1, ..), "result": result, .. } else {
    fail("initialize 响应结构不匹配")
  }
  guard result
    is {
      "protocolVersion": String("2024-11-05"),
      "serverInfo": { "name": String("better-edit-tools-mcp"), .. },
      "capabilities": { "tools": { "listChanged": false, .. }, .. },
      ..
    } else {
    fail("initialize 结果字段不匹配")
  }
}

///|
test "notifications/initialized 不返回响应" {
  let lines = ["{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(_s : String) -> Unit {
    outputs.push(_s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 0)
}

///|
test "非法 JSON 返回 Parse error" {
  let lines = ["{not json}"]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response
    is {
      "jsonrpc": String("2.0"),
      "error": { "code": Number(-32700, ..), .. },
      ..
    } else {
    fail("Parse error 响应结构不匹配")
  }
}

///|
test "未知方法返回 Method not found" {
  let lines = ["{\"jsonrpc\":\"2.0\",\"id\":\"req-1\",\"method\":\"unknown\"}"]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response
    is {
      "jsonrpc": String("2.0"),
      "id": String("req-1"),
      "error": { "code": Number(-32601, ..), .. },
      ..
    } else {
    fail("Method not found 响应结构不匹配")
  }
}

///|
test "tools/list 返回 9-10 个工具定义" {
  let lines = ["{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}"]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response
    is { "jsonrpc": String("2.0"), "id": Number(2, ..), "result": result, .. } else {
    fail("tools/list 响应结构不匹配")
  }
  guard result is { "tools": Array(tools), .. } else {
    fail("tools/list 结果缺少 tools 数组")
  }
  assert_true(tools.length() >= 9 && tools.length() <= 10)
  assert_true(tools[0] is { "name": String("be-read"), .. })
}

///|
test "tools/call be-read 成功返回 content" {
  let req = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"be-read\",\"arguments\":{\"file\":\"server/rpc.mbt\",\"start\":1,\"end\":2}}}"
  let lines = [req]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response
    is { "jsonrpc": String("2.0"), "id": Number(3, ..), "result": result, .. } else {
    fail("tools/call 响应结构不匹配")
  }
  guard result is { "content": Array(content), .. } else {
    fail("tools/call 结果缺少 content 数组")
  }
  assert_eq(content.length(), 1)
  assert_true(content[0] is { "type": String("text"), "text": String(_), .. })
}

///|
test "tools/call 未知工具返回 isError" {
  let req = "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"unknown-tool\",\"arguments\":{}}}"
  let lines = [req]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response is { "result": result, .. } else {
    fail("tools/call 响应缺少 result")
  }
  guard result is { "isError": true, "content": Array(_), .. } else {
    fail("未知工具应返回 isError: true")
  }
}

///|
test "tools/call 参数错误返回 isError" {
  let req = "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"be-read\",\"arguments\":{\"file\":\"/tmp/be-server-missing-file.txt\",\"start\":1}}}"
  let lines = [req]
  let mut idx = 0
  let outputs : Array[String] = []
  fn read_line() -> String {
    if idx < lines.length() {
      let line = lines[idx]
      idx = idx + 1
      line
    } else {
      ""
    }
  }
  fn write_line(s : String) -> Unit {
    outputs.push(s)
  }
  @server.serve(read_line, write_line)
  assert_eq(outputs.length(), 1)
  let response = @json.parse(outputs[0]) catch {
    _ => {
      fail("响应不是合法 JSON")
      null
    }
  }
  guard response is { "result": result, .. } else {
    fail("tools/call 响应缺少 result")
  }
  guard result is { "isError": true, "content": Array(_), .. } else {
    fail("参数错误应返回 isError: true")
  }
}
