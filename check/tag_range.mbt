///|
/// 定位 XML/HTML/Vue 标签配对范围的结果。
pub(all) struct BeTagRangeResult {
  tag : String
  range : @common.BeRange
} derive(Debug, ToJson)

///|
priv struct OpenTag {
  name : String
  start_line : Int
}

///|
fn tag_is_tag_name_char(code : Int) -> Bool {
  (code >= 97 && code <= 122) ||
  (code >= 65 && code <= 90) ||
  (code >= 48 && code <= 57) ||
  code == 45 ||
  code == 58 ||
  code == 95
}

///|
fn starts_with_at(s : String, prefix : String, pos : Int) -> Bool {
  if pos + prefix.length() > s.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if s[pos + i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn find_sub(s : String, pat : String, start : Int) -> Int? {
  if pat.length() == 0 {
    return Some(start)
  }
  let limit = s.length() - pat.length() + 1
  for i in start..<limit {
    let mut j = 0
    while j < pat.length() && s[i + j] == pat[j] {
      j += 1
    }
    if j == pat.length() {
      return Some(i)
    }
  }
  None
}

///|
fn find_tag_end(s : String, start : Int) -> Int? {
  let mut quote : UInt16? = None
  for i in start..<s.length() {
    let c = s[i]
    match quote {
      Some(q) => if c == q { quote = None }
      None =>
        if c == '"' || c == '\'' {
          quote = Some(c)
        } else if c == '>' {
          return Some(i)
        }
    }
  }
  None
}

///|
fn parse_tag_name(s : String, start : Int) -> (String, Int)? {
  let n = s.length()
  let mut i = start
  while i < n && tag_is_tag_name_char(s[i].to_int()) {
    i += 1
  }
  if i == start {
    None
  } else {
    Some((s.sub(start~, end=i).to_owned(), i))
  }
}

///|
fn is_self_closing(s : String, name_end : Int, tag_end : Int) -> Bool {
  let mut i = tag_end - 1
  while i > name_end {
    let c = s[i]
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      i -= 1
      continue
    }
    break
  }
  i >= name_end && s[i] == '/'
}

///|
/// 定位 file 第 line 行（1-based）所在的 XML/HTML/Vue 标签配对范围。
/// 返回该标签对的起止行号、标签名及内容。
pub fn be_tag_range(
  file : String,
  line : Int,
) -> BeTagRangeResult raise @error.BeError {
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  @common.reject_binary(file)
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let normalized = text
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let lines = @common.split_lines(text)
  let total = lines.length()
  guard line >= 1 && line <= total else {
    raise @error.BeError::InvalidFormat(
      "行号 \{line} 不在 1..\{total} 范围内",
    )
  }
  let n = normalized.length()
  let line_of_pos = Array::new(capacity=n + 1)
  let mut cur = 1
  for i in 0..<n {
    line_of_pos.push(cur)
    if normalized[i] == '\n' {
      cur += 1
    }
  }
  line_of_pos.push(cur)
  let mut pos = 0
  let stack : Array[OpenTag] = []
  let mut best : (Int, Int, String)? = None
  while pos < n {
    if normalized[pos] != '<' {
      pos += 1
      continue
    }
    if pos + 1 >= n {
      pos += 1
      continue
    }
    if starts_with_at(normalized, "<!--", pos) {
      let end = find_sub(normalized, "-->", pos + 4)
      match end {
        Some(e) => {
          pos = e + 3
          continue
        }
        None =>
          raise @error.BeError::InvalidFormat("未闭合的 HTML/XML 注释")
      }
    }
    if normalized[pos + 1] == '!' {
      let end = find_tag_end(normalized, pos + 2)
      match end {
        Some(e) => {
          pos = e + 1
          continue
        }
        None =>
          raise @error.BeError::InvalidFormat("未闭合的 DOCTYPE/声明")
      }
    }
    if normalized[pos + 1] == '/' {
      let end = find_tag_end(normalized, pos + 2)
      match end {
        Some(e) => {
          let name_result = parse_tag_name(normalized, pos + 2)
          match name_result {
            Some((name, _)) =>
              match stack.pop() {
                Some(top) => {
                  guard top.name == name else {
                    raise @error.BeError::InvalidFormat(
                      "结束标签 </\{name}> 与开始标签 <\{top.name}> 不匹配",
                    )
                  }
                  let start_line = top.start_line
                  let end_line = line_of_pos[e]
                  if line >= start_line && line <= end_line {
                    let width = end_line - start_line
                    let better = match best {
                      None => true
                      Some(b) => width < b.1 - b.0
                    }
                    if better {
                      best = Some((start_line, end_line, name))
                    }
                  }
                  pos = e + 1
                  continue
                }
                None =>
                  raise @error.BeError::InvalidFormat(
                    "多余的结束标签 </\{name}>",
                  )
              }
            None => raise @error.BeError::InvalidFormat("非法结束标签")
          }
        }
        None => raise @error.BeError::InvalidFormat("未闭合的结束标签")
      }
    }
    let name_result = parse_tag_name(normalized, pos + 1)
    match name_result {
      Some((name, name_end)) => {
        let end = find_tag_end(normalized, name_end)
        match end {
          Some(e) => {
            if is_self_closing(normalized, name_end, e) {
              pos = e + 1
              continue
            }
            stack.push({ name, start_line: line_of_pos[pos] })
            pos = e + 1
            continue
          }
          None =>
            raise @error.BeError::InvalidFormat(
              "未闭合的开始标签 <\{name}>",
            )
        }
      }
      None => {
        pos += 1
        continue
      }
    }
  }
  match best {
    Some((start_line, end_line, tag)) => {
      let selected = []
      for i in (start_line - 1)..<end_line {
        selected.push(lines[i])
      }
      { tag, range: { start_line, end_line, content: selected.join("\n") } }
    }
    None =>
      raise @error.BeError::InvalidFormat(
        "第 \{line} 行不在任何非自闭合标签对内",
      )
  }
}
