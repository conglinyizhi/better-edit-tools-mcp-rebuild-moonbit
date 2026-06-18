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
