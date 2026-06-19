///|
/// 检测文本主要使用的换行符，返回 "\n" 或 "\r\n"。
/// 无换行符时默认返回 "\n"。
pub fn detect_line_ending(text : String) -> String {
  let mut crlf = 0
  let mut lf = 0
  let len = text.length()
  let mut i = 0
  while i < len {
    let c = text[i]
    if c == '\r'.to_int().to_uint16() &&
      i + 1 < len &&
      text[i + 1] == '\n'.to_int().to_uint16() {
      crlf += 1
      i += 2
    } else if c == '\n'.to_int().to_uint16() {
      lf += 1
      i += 1
    } else {
      i += 1
    }
  }
  if crlf > lf {
    "\r\n"
  } else {
    "\n"
  }
}

///|
/// 按行分割文本，保留每行末尾的换行符。
/// 空文本返回空数组。
pub fn split_keep_line_ending(text : String) -> Array[String] {
  let lines : Array[String] = []
  let len = text.length()
  if len == 0 {
    return lines
  }
  let mut start = 0
  let mut i = 0
  while i < len {
    let c = text[i]
    if c == '\r'.to_int().to_uint16() &&
      i + 1 < len &&
      text[i + 1] == '\n'.to_int().to_uint16() {
      lines.push(text.sub(start~, end=i + 2).to_owned())
      i += 2
      start = i
    } else if c == '\n'.to_int().to_uint16() {
      lines.push(text.sub(start~, end=i + 1).to_owned())
      i += 1
      start = i
    } else {
      i += 1
    }
  }
  if start < len {
    lines.push(text.sub(start~, end=len).to_owned())
  }
  lines
}

///|
/// 将 content 中的换行符统一替换为指定换行符后，按行分割。
/// 返回不含行尾符的逻辑行数组。
pub fn prepare_content_lines(
  content : String,
  line_ending : String,
) -> Array[String] {
  let normalized = content
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  if normalized.is_empty() {
    return []
  }
  let replaced = normalized.replace_all(old="\n", new=line_ending)
  let parts = split_by(replaced, line_ending)
  if replaced.has_suffix(line_ending) {
    parts.pop() |> ignore
  }
  parts
}

///|
/// 从字节样本检测主要换行符，返回 "\n" 或 "\r\n"。
pub fn detect_line_ending_from_bytes(bytes : Bytes) -> String {
  let mut crlf = 0
  let mut lf = 0
  let len = bytes.length()
  let mut i = 0
  while i < len {
    if bytes[i] == b'\r' && i + 1 < len && bytes[i + 1] == b'\n' {
      crlf += 1
      i += 2
    } else if bytes[i] == b'\n' {
      lf += 1
      i += 1
    } else {
      i += 1
    }
  }
  if crlf > lf {
    "\r\n"
  } else {
    "\n"
  }
}

///|
/// 读取文件并检测其换行符风格，文件不存在时返回 "\n"。
pub fn detect_file_line_ending(path : String) -> String raise @error.BeError {
  if !@fs.path_exists(path) {
    return "\n"
  }
  let bytes = @fs.read_file_to_bytes(path) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  detect_line_ending_from_bytes(bytes)
}

///|
/// 将文本按换行符分割为逻辑行数组（不含行尾符）。
/// 空文本返回空数组。
pub fn split_lines(text : String) -> Array[String] {
  let kept = split_keep_line_ending(text)
  let ending = detect_line_ending(text)
  let ending_len = ending.length()
  kept.map(fn(line) {
    if line.length() >= ending_len && line.has_suffix(ending) {
      line.sub(start=0, end=line.length() - ending_len).to_owned()
    } else {
      line
    }
  })
}

///|
/// 按分隔符分割字符串，返回不含分隔符的片段数组。
fn split_by(text : String, sep : String) -> Array[String] {
  let parts : Array[String] = []
  let sep_len = sep.length()
  if sep_len == 0 {
    parts.push(text)
    return parts
  }
  let len = text.length()
  let mut start = 0
  let mut i = 0
  while i <= len - sep_len {
    let mut matched = true
    for j = 0; j < sep_len; j = j + 1 {
      if text[i + j] != sep[j] {
        matched = false
        break
      }
    }
    if matched {
      parts.push(text.sub(start~, end=i).to_owned())
      i += sep_len
      start = i
    } else {
      i += 1
    }
  }
  parts.push(text.sub(start~, end=len).to_owned())
  parts
}
