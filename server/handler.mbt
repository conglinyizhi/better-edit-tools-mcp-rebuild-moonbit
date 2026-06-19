///|
/// 将工具调用的 Json 参数转换为字符串映射。
fn json_to_string_map(args : Json) -> Map[String, String] {
  let result = Map::default()
  match args {
    Object(map) =>
      map.each(fn(k, v) {
        match v {
          String(s) => result.set(k, s)
          _ => result.set(k, v.stringify())
        }
      })
    _ => ()
  }
  result
}

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
/// 从 Json 对象中读取对象字段。
fn get_object(args : Json, key : String) -> Json {
  match args {
    Object(map) =>
      match map.get(key) {
        Some(obj) => obj
        _ => {}
      }
    _ => {}
  }
}

///|
/// 判断 Json 是否为空对象或不是对象。
fn is_empty_object(j : Json) -> Bool {
  match j {
    Object(map) => map.length() == 0
    _ => true
  }
}

///|
/// 从 Json 对象中读取数组字段。
fn get_array(args : Json, key : String) -> Array[Json] {
  match args {
    Object(map) =>
      match map.get(key) {
        Some(Array(arr)) => arr
        _ => []
      }
    _ => []
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
    @error.BeError::InvalidFormat(msg) =>
      @common.t("error.InvalidFormat") + ": " + msg
    @error.BeError::FileNotFound(msg) =>
      @common.t("error.FileNotFound") + ": " + msg
    @error.BeError::NotARegularFile(msg) =>
      @common.t("error.NotARegularFile") + ": " + msg
    @error.BeError::ReadError(msg) => @common.t("error.ReadError") + ": " + msg
    @error.BeError::WriteError(msg) =>
      @common.t("error.WriteError") + ": " + msg
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
/// 解析 target 对象为行范围。
fn parse_target(
  file : String,
  target : Json,
) -> (Int, Int) raise @error.BeError {
  let kind = get_string(target, "kind")
  let value = get_string(target, "value")
  guard kind != "" else {
    raise @error.BeError::InvalidFormat("target.kind is required")
  }
  guard value != "" else {
    raise @error.BeError::InvalidFormat("target.value is required")
  }
  match kind {
    "line" => {
      let dash = value.find("-")
      match dash {
        Some(idx) => {
          let start = @strconv.from_str(value.sub(start=0, end=idx)) catch {
            _ =>
              raise @error.BeError::InvalidFormat(
                "target line start must be integer: " + value,
              )
          }
          let end = @strconv.from_str(
            value.sub(start=idx + 1, end=value.length()),
          ) catch {
            _ =>
              raise @error.BeError::InvalidFormat(
                "target line end must be integer: " + value,
              )
          }
          guard start >= 1 && end >= start else {
            raise @error.BeError::InvalidFormat(
              "target line range must satisfy 1 <= start <= end: " + value,
            )
          }
          (start, end)
        }
        None => {
          let line = @strconv.from_str(value) catch {
            _ =>
              raise @error.BeError::InvalidFormat(
                "target line must be integer: " + value,
              )
          }
          guard line >= 1 else {
            raise @error.BeError::InvalidFormat(
              "target line must be positive: " + value,
            )
          }
          (line, line)
        }
      }
    }
    "function" => {
      let line = @strconv.from_str(value) catch {
        _ =>
          raise @error.BeError::InvalidFormat(
            "target function line must be integer: " + value,
          )
      }
      let range = @check.be_func_range(file, line)
      (range.start_line, range.end_line)
    }
    "tag" => {
      let line = @strconv.from_str(value) catch {
        _ =>
          raise @error.BeError::InvalidFormat(
            "target tag line must be integer: " + value,
          )
      }
      let result = @check.be_tag_range(file, line)
      (result.range.start_line, result.range.end_line)
    }
    "marker" =>
      raise @error.BeError::InvalidFormat("marker target not supported")
    _ => raise @error.BeError::InvalidFormat("unknown target kind: " + kind)
  }
}

///|
/// 根据工具名和参数调用对应的 be_* 函数，返回 MCP tools/call 响应内容。
pub fn call_tool(name : String, args : Json) -> Json raise @error.BeError {
  try {
    match name {
      "be-read" => {
        let file = get_string(args, "file")
        @common.reject_chip_target(file)
        let target = get_object(args, "target")
        let (start_line, end_line) = if !is_empty_object(target) {
          parse_target(file, target)
        } else {
          let s = get_int(args, "start")
          let e_int = get_int(args, "end")
          let e_str = get_string(args, "end")
          let e = if e_int > 0 {
            e_int
          } else if e_str != "" && e_str != "auto" {
            @strconv.from_str(e_str) catch {
              _ => 0
            }
          } else {
            0
          }
          (s, e)
        }
        let input = if start_line > 0 {
          if end_line > 0 && end_line >= start_line {
            "\{file}:\{start_line}-\{end_line}"
          } else {
            "\{file}:\{start_line}"
          }
        } else {
          file
        }
        let result = @read.be_read(input)
        let brief = get_bool(args, "brief")
        if brief {
          let json : Json = {
            "viewed_code_id": result.viewed_code_id,
            "range": {
              "start_line": result.range.start_line,
              "end_line": result.range.end_line,
            },
          }
          make_text_response(json.stringify())
        } else {
          make_text_response(result.to_json().stringify())
        }
      }
      "be-replace" => {
        let file = get_string(args, "file")
        @common.reject_chip_target(file)
        let target = get_object(args, "target")
        let (start_line, end_line) = if !is_empty_object(target) {
          parse_target(file, target)
        } else {
          (get_int(args, "start"), get_int(args, "end"))
        }
        let content = get_string(args, "content")
        let format = get_string(args, "format", default="plain")
        let preview = get_bool(args, "preview")
        let brief = get_bool(args, "brief")
        let viewed_code_id = get_string(args, "viewed_code_id")
        let old = get_string(args, "old")
        let old_text = get_string(args, "old_text")
        let replace_result = @edit.be_replace(
          file,
          start_line,
          end_line,
          content,
          viewed_code_id~,
          old~,
          old_text~,
          format~,
          preview~,
          brief~,
        )
        let json : Json = if brief {
          {
            "status": replace_result.status,
            "file": file,
            "removed": replace_result.removed,
            "added": replace_result.added,
            "total": replace_result.total,
            "affected": replace_result.affected,
            "balance": replace_result.balance,
            "warnings": replace_result.warnings,
            "event_id": replace_result.event_id,
            "queue_full": replace_result.queue_full,
          }
        } else {
          {
            "status": replace_result.status,
            "file": file,
            "removed": replace_result.removed,
            "added": replace_result.added,
            "total": replace_result.total,
            "diff": replace_result.diff,
            "affected": replace_result.affected,
            "balance": replace_result.balance,
            "warnings": replace_result.warnings,
            "event_id": replace_result.event_id,
            "queue_full": replace_result.queue_full,
            "preview": replace_result.preview,
            "brief": replace_result.brief,
          }
        }
        make_text_response(json.stringify())
      }
      "be-insert" => {
        let file = get_string(args, "file")
        @common.reject_chip_target(file)
        let target = get_object(args, "target")
        let after_line = if !is_empty_object(target) {
          let (_, end) = parse_target(file, target)
          end
        } else {
          get_int(args, "after_line")
        }
        let content = get_string(args, "content")
        let format = get_string(args, "format", default="plain")
        let preview = get_bool(args, "preview")
        let brief = get_bool(args, "brief")
        let insert_result = @edit.be_insert(
          file,
          content,
          after_line~,
          format~,
          preview~,
          brief~,
        )
        let json : Json = if brief {
          {
            "status": insert_result.status,
            "file": file,
            "removed": insert_result.removed,
            "added": insert_result.added,
            "total": insert_result.total,
            "affected": insert_result.affected,
            "balance": insert_result.balance,
            "warnings": insert_result.warnings,
            "event_id": insert_result.event_id,
            "queue_full": insert_result.queue_full,
          }
        } else {
          {
            "status": insert_result.status,
            "file": file,
            "removed": insert_result.removed,
            "added": insert_result.added,
            "total": insert_result.total,
            "diff": insert_result.diff,
            "affected": insert_result.affected,
            "balance": insert_result.balance,
            "warnings": insert_result.warnings,
            "event_id": insert_result.event_id,
            "queue_full": insert_result.queue_full,
            "preview": insert_result.preview,
            "brief": insert_result.brief,
          }
        }
        make_text_response(json.stringify())
      }
      "be-delete" => {
        let file = get_string(args, "file")
        @common.reject_chip_target(file)
        let target = get_object(args, "target")
        let (start_line, end_line) = if !is_empty_object(target) {
          parse_target(file, target)
        } else {
          (get_int(args, "start"), get_int(args, "end"))
        }
        let format = get_string(args, "format", default="plain")
        let preview = get_bool(args, "preview")
        let brief = get_bool(args, "brief")
        let delete_result = @edit.be_delete(
          file,
          start_line~,
          end_line~,
          format~,
          preview~,
          brief~,
        )
        let json : Json = if brief {
          {
            "status": delete_result.status,
            "file": file,
            "removed": delete_result.removed,
            "added": delete_result.added,
            "total": delete_result.total,
            "affected": delete_result.affected,
            "balance": delete_result.balance,
            "warnings": delete_result.warnings,
            "event_id": delete_result.event_id,
            "queue_full": delete_result.queue_full,
          }
        } else {
          {
            "status": delete_result.status,
            "file": file,
            "removed": delete_result.removed,
            "added": delete_result.added,
            "total": delete_result.total,
            "diff": delete_result.diff,
            "affected": delete_result.affected,
            "balance": delete_result.balance,
            "warnings": delete_result.warnings,
            "event_id": delete_result.event_id,
            "queue_full": delete_result.queue_full,
            "preview": delete_result.preview,
            "brief": delete_result.brief,
          }
        }
        make_text_response(json.stringify())
      }
      "be-write" => {
        let file = get_string(args, "file")
        let content = get_string(args, "content")
        let files = get_array(args, "files")
        let preview = get_bool(args, "preview")
        let brief = get_bool(args, "brief")
        if files.length() > 0 {
          if preview {
            let json : Json = { "status": "preview", "files": files.length() }
            make_text_response(json.stringify())
          } else {
            let mut failed = ""
            for f in files {
              let f_file = get_string(f, "file")
              let f_content = get_string(f, "content")
              let msg = @write.be_write(f_file, f_content)
              if !msg.is_empty() && failed.is_empty() {
                failed = msg
              }
            }
            if failed.is_empty() {
              make_text_response("{\"status\":\"ok\"}")
            } else {
              make_text_response(failed)
            }
          }
        } else if preview {
          let json : Json = if brief {
            { "status": "preview", "file": file }
          } else {
            { "status": "preview", "file": file, "content": content }
          }
          make_text_response(json.stringify())
        } else {
          let msg = @write.be_write(file, content)
          if msg.is_empty() {
            make_text_response("{\"status\":\"ok\"}")
          } else {
            make_text_response(msg)
          }
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
      "be-trx" => {
        let action = get_string(args, "action")
        match action {
          "status" => {
            let stats = @snapshot.snapshot_queue_stats()
            make_text_response(stats.to_json().stringify())
          }
          "commit" => {
            let committed = @snapshot.commit_snapshots()
            let json : Json = { "status": "ok", "committed": committed }
            make_text_response(json.stringify())
          }
          "rollback" => {
            let step = get_int(args, "step")
            let step = if step > 0 { step } else { 1 }
            let (restored, errors) = @snapshot.rollback_snapshots(step)
            let json : Json = {
              "status": "ok",
              "restored": restored,
              "errors": errors.map(error_message),
            }
            make_text_response(json.stringify())
          }
          _ =>
            raise @error.BeError::InvalidFormat("unknown trx action: " + action)
        }
      }
      _ => raise @error.BeError::InvalidFormat("unknown tool: " + name)
    }
  } catch {
    err => {
      let args_map = json_to_string_map(args)
      let chip_id = try {
        let id = @chip.save_chip(name, args_map, error_message(err))
        if id.length() > 0 {
          id
        } else {
          @chip.save(args.stringify())
        }
      } catch {
        _ => @chip.save(args.stringify())
      }
      let text = error_message(err) + " (saved to chip://" + chip_id + ")"
      { "isError": true, "content": [{ "type": "text", "text": text }] }
    }
  }
}
