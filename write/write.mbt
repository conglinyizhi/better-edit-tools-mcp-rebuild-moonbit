///|
/// be-write 结果。
pub(all) struct WriteResult {
  degraded : Bool
  files : Array[String]
  results : Array[String]
  warnings : Array[String]
} derive(Debug, ToJson)

///|
pub extend WriteResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend WriteResult with ToJson::{to_json}

///|
/// 从 markdown 代码块提取内容。
/// 支持 ``` 与 ~~~ 围栏，返回第一个代码块内的文本。
fn extract_markdown_code(content : String) -> String {
  let fences = ["```", "~~~"]
  for fence in fences {
    let start = find_from(content, fence, 0)
    if start is Some(start_idx) {
      let after_fence = start_idx + fence.length()
      let newline = find_from(content, "\n", after_fence)
      let content_start = match newline {
        Some(nl) => nl + 1
        None => after_fence
      }
      let end = find_from(content, fence, content_start)
      if end is Some(end_idx) {
        return content.sub(start=content_start, end=end_idx).to_owned()
      }
    }
  }
  content
}

///|
/// 从指定位置开始查找子串。
fn find_from(text : String, pat : String, start : Int) -> Int? {
  if start >= text.length() {
    return None
  }
  let sub = text.sub(start~, end=text.length())
  match sub.find(pat) {
    Some(idx) => Some(start + idx)
    None => None
  }
}

///|
/// 从 JSON 对象中提取字符串字段。
fn json_string(obj : Json, key : String) -> String {
  match obj {
    Object(map) =>
      match map.get(key) {
        Some(String(s)) => s
        _ => ""
      }
    _ => ""
  }
}

///|
/// 尝试标准 JSON 解析输入，返回 (files, extract, success)。
fn parse_write_json(input : String) -> (Array[(String, String)], Bool, Bool) {
  let files : Array[(String, String)] = []
  let json = @json.parse(input) catch { _ => return (files, false, false) }
  match json {
    Object(map) => {
      let extract = match map.get("extract") {
        Some(True) => true
        Some(String(s)) => s == "true" || s == "1"
        _ => false
      }
      match map.get("files") {
        Some(Array(arr)) =>
          for item in arr {
            let file = json_string(item, "file")
            let content = json_string(item, "content")
            if file != "" {
              files.push((file, content))
            }
          }
        _ => {
          let file = json_string(json, "file")
          let content = json_string(json, "content")
          if file != "" {
            files.push((file, content))
          }
        }
      }
      (files, extract, true)
    }
    Array(arr) => {
      for item in arr {
        let file = json_string(item, "file")
        let content = json_string(item, "content")
        if file != "" {
          files.push((file, content))
        }
      }
      (files, false, true)
    }
    _ => (files, false, false)
  }
}

///|
/// 字符级降级解析，支持带未转义换行的类 JSON/键值对输入。
fn parse_spec_raw(input : String) -> (Array[(String, String)], Bool) {
  let files : Array[(String, String)] = []
  let extract_ref : Ref[Bool] = { val: false }
  let contents : Array[String] = []
  let len = input.length()
  let mut i = 0

  fn is_ws(c : UInt16) -> Bool {
    let code = c.to_int()
    code == ' '.to_int() ||
    code == '\t'.to_int() ||
    code == '\n'.to_int() ||
    code == '\r'.to_int()
  }

  fn is_key_char(c : UInt16) -> Bool {
    let code = c.to_int()
    (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
    (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
    (code >= '0'.to_int() && code <= '9'.to_int()) ||
    code == '_'.to_int() ||
    code == '-'.to_int()
  }

  fn skip_ws() -> Unit {
    while i < len && is_ws(input[i]) {
      i += 1
    }
  }

  fn read_key() -> String? {
    skip_ws()
    if i >= len || !is_key_char(input[i]) {
      return None
    }
    let start = i
    while i < len && is_key_char(input[i]) {
      i += 1
    }
    Some(input.sub(start~, end=i).to_owned())
  }

  fn char_to_string(c : UInt16) -> String {
    let ch = c.to_int().unsafe_to_char()
    String::make(1, ch)
  }

  fn read_string(quote : UInt16) -> String {
    let mut sb = ""
    while i < len {
      let c = input[i]
      if c == '\\'.to_int().to_uint16() && i + 1 < len {
        let next = input[i + 1]
        match next.to_int() {
          'n' => sb += "\n"
          't' => sb += "\t"
          'r' => sb += "\r"
          _ => sb += char_to_string(next)
        }
        i += 2
      } else if c == quote {
        i += 1
        break
      } else {
        sb += char_to_string(c)
        i += 1
      }
    }
    sb
  }

  fn read_unquoted_value() -> String {
    skip_ws()
    let start = i
    while i < len {
      let c = input[i]
      if is_ws(c) ||
        c == ','.to_int().to_uint16() ||
        c == '}'.to_int().to_uint16() ||
        c == ']'.to_int().to_uint16() {
        break
      }
      i += 1
    }
    input.sub(start~, end=i).to_owned()
  }

  fn read_value() -> String {
    skip_ws()
    if i >= len {
      return ""
    }
    let c = input[i]
    if c == '"'.to_int().to_uint16() || c == '\''.to_int().to_uint16() {
      i += 1
      return read_string(c)
    }
    read_unquoted_value()
  }

  fn read_separator() -> Unit {
    skip_ws()
    if i < len &&
      (
        input[i] == ':'.to_int().to_uint16() ||
        input[i] == '='.to_int().to_uint16()
      ) {
      i += 1
    }
  }

  while i < len {
    skip_ws()
    if i >= len {
      break
    }
    let mut key = ""
    let c = input[i]
    if c == '"'.to_int().to_uint16() || c == '\''.to_int().to_uint16() {
      // 引号包围的键
      let quote = c
      i += 1
      key = read_string(quote)
      skip_ws()
      if i < len &&
        (
          input[i] == ':'.to_int().to_uint16() ||
          input[i] == '='.to_int().to_uint16()
        ) {
        i += 1
      } else {
        // 不是键，跳过其值
        continue
      }
    } else if is_key_char(c) {
      let key_opt = read_key()
      if key_opt is None {
        i += 1
        continue
      }
      key = key_opt.unwrap()
      read_separator()
    } else {
      i += 1
      continue
    }
    let value = read_value()
    match key {
      "file" => if value != "" { files.push((value, "")) }
      "content" => contents.push(value)
      "extract" =>
        if value.to_lower() == "true" || value == "1" {
          extract_ref.val = true
        }
      _ => ()
    }
  }

  // 将 content 与 file 按顺序配对。
  for idx = 0; idx < files.length() && idx < contents.length(); idx = idx + 1 {
    let (f, _) = files[idx]
    files[idx] = (f, contents[idx])
  }
  if files.is_empty() && contents.length() > 0 {
    files.push(("", contents[0]))
  }

  (files, extract_ref.val)
}

///|
/// 解析 be-write 输入，返回待写入文件列表与 extract 标志。
fn parse_write_input(input : String) -> (Array[(String, String)], Bool, Bool) {
  let (files, extract, ok) = parse_write_json(input)
  if ok {
    return (files, extract, false)
  }
  let (raw_files, raw_extract) = parse_spec_raw(input)
  (raw_files, raw_extract, true)
}

///|
/// 写入文件。支持单文件与多文件 JSON 输入。
/// 当输入看起来像 JSON 对象/数组时先尝试标准解析，失败时降级到字符级状态机。
pub fn be_write(input : String) -> WriteResult raise @error.BeError {
  let (files, extract, degraded) = parse_write_input(input)
  let warnings : Array[String] = []
  let results : Array[String] = []
  let file_list : Array[String] = []
  for pair in files {
    let (file, content) = pair
    if file == "" {
      warnings.push("missing file in write request")
      results.push("error: missing file")
      continue
    }
    @common.reject_chip_target(file)
    let original_bytes = if @fs.path_exists(file) {
      Some(
        @fs.read_file_to_bytes(file) catch {
          IOError(msg) => raise @error.BeError::ReadError(msg)
        },
      )
    } else {
      None
    }
    let original_content = match original_bytes {
      Some(_) =>
        @fs.read_file_to_string(file) catch {
          IOError(msg) => raise @error.BeError::WriteError(msg)
        }
      None => ""
    }
    let is_regular = if @fs.path_exists(file) {
      @fs.is_file(file) catch {
        IOError(msg) => raise @error.BeError::ReadError(msg)
      }
    } else {
      true
    }
    guard is_regular else { raise @error.BeError::NotARegularFile(file) }
    @common.reject_binary(file)
    let (_, _) = @snapshot.push_snapshot(file, original_content)
    let resolved = @chip.resolve(content)
    let extracted = if extract {
      extract_markdown_code(resolved)
    } else {
      resolved
    }
    let normalized = extracted.replace_all(old="\\n", new="\n")
    let line_ending = match original_bytes {
      Some(bytes) => @common.detect_line_ending_from_bytes(bytes)
      None => "\n"
    }
    let prepared = @common.prepare_content_lines(normalized, line_ending)
    let output = prepared.join(line_ending)
    try {
      write_file_atomic(file, output)
      results.push("ok")
    } catch {
      @error.BeError::WriteError(msg) => {
        let chip_id = @chip.save(normalized)
        results.push("chip://" + chip_id + " 写入失败：" + msg)
        warnings.push("failed to write " + file + ": " + msg)
      }
      e => raise e
    }
    file_list.push(file)
  }
  { degraded, files: file_list, results, warnings }
}

///|
/// 向后兼容的单文件写入包装。
/// 返回空字符串表示成功；失败时返回 chip://{id} 写入失败信息。
pub fn be_write_single(
  file : String,
  content : String,
) -> String raise @error.BeError {
  let input : Json = { "file": file, "content": content }
  let result = be_write(input.stringify())
  for r in result.results {
    if r != "ok" {
      return r
    }
  }
  ""
}
