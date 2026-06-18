///|
/// 从 Json 对象中读取字符串字段。
fn get_string(args : Json, key : String, default? : String = "") -> String {
  match args {
    Object(map) =>
      match map.get(key) {
        Some(String(s)) => s
        _ => default
      }
    _ => default
  }
}

///|
/// 从 Json 对象中读取整数字段。
fn get_int(args : Json, key : String, default? : Int = 0) -> Int {
  match args {
    Object(map) =>
      match map.get(key) {
        Some(Number(n, ..)) =>
          @strconv.from_str(n.to_string()) catch {
            _ => default
          }
        Some(String(s)) => @strconv.from_str(s) catch { _ => default }
        _ => default
      }
    _ => default
  }
}

///|
/// 从 Json 对象中读取布尔字段。
fn get_bool(args : Json, key : String, default? : Bool = false) -> Bool {
  match args {
    Object(map) =>
      match map.get(key) {
        Some(True) => true
        Some(False) => false
        _ => default
      }
    _ => default
  }
}

///|
/// 将文本包装为 MCP tools/call 响应内容格式。
fn make_text_response(text : String) -> Json {
  { "content": [{ "type": "text", "text": text }] }
}

///|
/// 将 BeError 转换为可读的错误消息。
fn error_message(err : @error.BeError) -> String {
  match err {
    @error.BeError::InvalidFormat(msg) => "InvalidFormat: " + msg
    @error.BeError::FileNotFound(msg) => "FileNotFound: " + msg
    @error.BeError::NotARegularFile(msg) => "NotARegularFile: " + msg
    @error.BeError::ReadError(msg) => "ReadError: " + msg
    @error.BeError::WriteError(msg) => "WriteError: " + msg
  }
}

///|
/// 解析 be-insert-chip 的 to 参数，格式为 file:///absolute/path:line_number。
fn parse_insert_chip_target(to : String) -> (String, Int) raise @error.BeError {
  guard to.has_prefix("file:///") else {
    raise @error.BeError::InvalidFormat(
      "to format should be file:///absolute/path:line_number",
    )
  }
  let rest = to[8:].to_owned()
  let colon = rest.rev_find(":")
  guard colon is Some(idx) else {
    raise @error.BeError::InvalidFormat(
      "to format should be file:///absolute/path:line_number",
    )
  }
  let file = rest.sub(start=0, end=idx).to_owned()
  let line_str = rest.sub(start=idx + 1, end=rest.length()).to_owned()
  let line = @strconv.from_str(line_str) catch {
    _ =>
      raise @error.BeError::InvalidFormat(
        "line number must be integer: " + line_str,
      )
  }
  (file, line)
}

///|
/// 根据工具名和参数调用对应的 be_* 函数，返回 MCP tools/call 响应内容。
pub fn call_tool(name : String, args : Json) -> Json raise @error.BeError {
  match name {
    "be-read" => {
      let file = get_string(args, "file")
      let start = get_int(args, "start")
      let input = if start > 0 {
        let end = get_string(args, "end")
        if end != "" && end != "auto" {
          "\{file}:\{start}-\{end}"
        } else {
          "\{file}:\{start}"
        }
      } else {
        file
      }
      let result = @read.be_read(input)
      make_text_response(result.to_json().stringify())
    }
    "be-replace" => {
      let file = get_string(args, "file")
      let start = get_int(args, "start")
      let end = get_int(args, "end")
      let content = get_string(args, "content")
      let viewed_code_id = get_string(args, "viewed_code_id")
      let old = get_string(args, "old")
      let old_text = get_string(args, "old_text")
      @edit.be_replace(
        file,
        start,
        end,
        content,
        viewed_code_id~,
        old~,
        old_text~,
      )
      make_text_response("{\"status\":\"ok\"}")
    }
    "be-insert" => {
      let file = get_string(args, "file")
      let after_line = get_int(args, "after_line")
      let content = get_string(args, "content")
      @edit.be_insert(file, content, after_line~)
      make_text_response("{\"status\":\"ok\"}")
    }
    "be-delete" => {
      let file = get_string(args, "file")
      let start = get_int(args, "start")
      let end = get_int(args, "end")
      @edit.be_delete(file, start~, end~)
      make_text_response("{\"status\":\"ok\"}")
    }
    "be-write" => {
      let file = get_string(args, "file")
      let content = get_string(args, "content")
      let msg = @write.be_write(file, content)
      if msg.is_empty() {
        make_text_response("{\"status\":\"ok\"}")
      } else {
        raise @error.BeError::WriteError(msg)
      }
    }
    "be-func-range" => {
      let file = get_string(args, "file")
      let line = get_int(args, "line")
      let result = @check.be_func_range(file, line)
      make_text_response(result.to_json().stringify())
    }
    "be-tag-range" => {
      let file = get_string(args, "file")
      let line = get_int(args, "line")
      let result = @check.be_tag_range(file, line)
      make_text_response(result.to_json().stringify())
    }
    "be-balance" => {
      let file = get_string(args, "file")
      let verbose = get_bool(args, "verbose")
      let result = @check.be_balance(file, verbose~)
      make_text_response(result.to_json().stringify())
    }
    "be-insert-chip" => {
      let from = get_string(args, "from")
      let to = get_string(args, "to")
      if from == "" && to == "" {
        let result = @edit.be_insert_chip("", from="")
        make_text_response(result.to_json().stringify())
      } else {
        let (file, line) = parse_insert_chip_target(to)
        let result = @edit.be_insert_chip(file, line~, from~)
        make_text_response(result.to_json().stringify())
      }
    }
    "be-trx-commit" => make_text_response("not implemented")
    _ => raise @error.BeError::InvalidFormat("unknown tool: " + name)
  }
}
