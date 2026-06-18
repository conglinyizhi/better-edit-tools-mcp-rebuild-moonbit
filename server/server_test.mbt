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

///|
test "list_tools 描述随语言切换" {
  @common.set_language("zh")
  let tools_zh = @server.list_tools()
  assert_eq(tools_zh[0].description, "读取文件内容并显示行号。")
  assert_eq(tools_zh[1].description, "替换文件中精确的行范围。")
  @common.set_language("en")
  let tools_en = @server.list_tools()
  assert_eq(tools_en[0].description, "Read file content with line numbers.")
  assert_eq(tools_en[1].description, "Replace a precise line range in a file.")
}

///|
test "call_tool be-read 返回正确 JSON" {
  let args : Json = { "file": "server/rpc.mbt", "start": 1, "end": 2 }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("be-read 不应失败")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-read 应返回 content 数组")
  }
  assert_eq(content.length(), 1)
  assert_true(content[0] is { "type": String("text"), "text": String(_), .. })
}

///|
test "call_tool be-read brief 省略 content" {
  let args : Json = {
    "file": "server/rpc.mbt",
    "start": 1,
    "end": 2,
    "brief": true,
  }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("be-read 不应失败")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-read 应返回 content 数组")
  }
  assert_eq(content.length(), 1)
  guard content[0] is { "text": String(text), .. } else {
    fail("content[0] 应包含 text")
  }
  let parsed = @json.parse(text) catch {
    _ => {
      fail("brief 响应应为合法 JSON")
      null
    }
  }
  guard parsed is { "viewed_code_id": String(_), "range": range, .. } else {
    fail("brief 响应结构不匹配")
  }
  assert_true(
    range is { "start_line": Number(1, ..), "end_line": Number(2, ..), .. },
  )
}

///|
test "call_tool be-write 成功返回 ok" {
  let tmp = "/tmp/be-server-write-test.txt"
  let args : Json = { "file": tmp, "content": "hello\\nworld" }
  let result = @server.call_tool("be-write", args) catch {
    _ => {
      fail("be-write 不应失败")
      null
    }
  }
  guard result is { "content": Array(content), .. } else {
    fail("be-write 应返回 content 数组")
  }
  assert_eq(content.length(), 1)
  assert_true(
    content[0]
    is { "type": String("text"), "text": String("{\"status\":\"ok\"}"), .. },
  )
}

///|
test "call_tool 错误调用保存 args 到 chip" {
  @common.set_language("en")
  let args : Json = { "file": "/tmp/be-server-missing-file.txt", "start": 1 }
  let result = @server.call_tool("be-read", args) catch {
    _ => {
      fail("call_tool 内部应捕获错误")
      null
    }
  }
  guard result is { "isError": true, "content": Array(content), .. } else {
    fail("错误响应应包含 isError: true")
  }
  assert_eq(content.length(), 1)
  guard content[0] is { "text": String(text), .. } else {
    fail("错误内容应包含 text")
  }
  assert_true(text.contains("chip://"))
  assert_true(text.contains("File not found"))
}
