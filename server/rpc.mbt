///|
/// JSON-RPC 请求。
pub(all) struct RpcRequest {
  jsonrpc : String
  id : Json?
  method : String
  params : Json?
} derive(ToJson)

///|
/// JSON-RPC 响应。
pub(all) struct RpcResponse {
  jsonrpc : String
  id : Json?
  result : Json?
  error : RpcError?
} derive(ToJson)

///|
/// JSON-RPC 错误对象。
pub(all) struct RpcError {
  code : Int
  message : String
} derive(ToJson)

///|
/// 从标准输入读取一行，直到换行符或 EOF。
fn read_stdin_line() -> String {
  let chars = []
  while true {
    let c = getchar()
    if c == -1 || c == '\n' {
      break
    }
    chars.push(c.unsafe_to_char())
  }
  String::from_array(chars)
}

///|
/// 解析 JSON 对象中的 JSON-RPC 请求字段。
fn parse_request(json : Json) -> RpcRequest? {
  guard json is { "jsonrpc": String(jsonrpc), "method": String(method), .. } else {
    return None
  }
  let id = match json {
    { "id": id_json, .. } => Some(id_json)
    _ => None
  }
  let params = match json {
    { "params": params_json, .. } => Some(params_json)
    _ => None
  }
  Some({ jsonrpc, id, method, params })
}

///|
/// 构造成功的 JSON-RPC 响应。
fn make_response(id : Json?, result : Json) -> RpcResponse {
  { jsonrpc: "2.0", id, result: Some(result), error: None }
}

///|
/// 构造失败的 JSON-RPC 响应。
fn make_error(id : Json?, code : Int, message : String) -> RpcResponse {
  { jsonrpc: "2.0", id, result: None, error: Some({ code, message }) }
}

///|
/// MCP 服务器主循环。
pub fn serve(
  read_line : () -> String,
  write_line : (String) -> Unit,
) -> Unit raise @error.BeError {
  while true {
    let line = read_line()
    if line.is_empty() {
      break
    }
    let trimmed = line.trim()
    if trimmed.is_empty() {
      continue
    }
    let request_json_opt = Some(@json.parse(trimmed)) catch {
      _ => {
        let resp = make_error(None, -32700, "Parse error")
        write_line(resp.to_json().stringify())
        None
      }
    }
    guard request_json_opt is Some(request_json) else { continue }
    let request = match parse_request(request_json) {
      Some(req) => req
      None => {
        let id = match request_json {
          { "id": id_json, .. } => Some(id_json)
          _ => None
        }
        let resp = make_error(id, -32600, "Invalid Request")
        write_line(resp.to_json().stringify())
        continue
      }
    }
    match request.method {
      "initialize" => {
        let result : Json = {
          "protocolVersion": "2024-11-05",
          "serverInfo": { "name": "better-edit-tools-mcp", "version": "0.1.0" },
          "capabilities": { "tools": { "listChanged": false } },
        }
        let resp = make_response(request.id, result)
        write_line(resp.to_json().stringify())
      }
      "notifications/initialized" =>
        // 通知无需响应
        continue
      "tools/list" => {
        let result : Json = { "tools": [] }
        let resp = make_response(request.id, result)
        write_line(resp.to_json().stringify())
      }
      "tools/call" => {
        let resp = make_error(request.id, -32601, "Method not found")
        write_line(resp.to_json().stringify())
      }
      _ => {
        let resp = make_error(request.id, -32601, "Method not found")
        write_line(resp.to_json().stringify())
      }
    }
  }
}

///|
/// 启动 MCP 服务器，从 stdin 读取并写入 stdout。
pub fn run() -> Unit raise @error.BeError {
  serve(read_stdin_line, println)
}
