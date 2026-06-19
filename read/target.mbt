///|
/// be-read 的目标描述。
pub(all) struct BeTarget {
  kind : String
  value : String
} derive(Debug, ToJson)

///|
/// 根据 target 解析文件中的目标范围。
/// kind 支持："line" | "function" | "marker" | "tag"。
pub fn resolve_target_span(
  file : String,
  target : BeTarget,
) -> @common.BeRange raise @error.BeError {
  match target.kind {
    "line" => resolve_line_span(file, target.value)
    "function" => resolve_function_span(file, target.value)
    "marker" => resolve_marker_span(file, target.value)
    "tag" => resolve_tag_span(file, target.value)
    _ =>
      raise @error.BeError::InvalidFormat(
        "不支持的 target kind：\{target.kind}",
      )
  }
}

///|
fn resolve_line_span(
  file : String,
  value : String,
) -> @common.BeRange raise @error.BeError {
  let (_, start, end) = @common.parse_file_range("x:" + value)
  let lines = read_file_lines(file)
  let total = lines.length()
  let effective_start = if start < 1 {
    1
  } else if start > total {
    total
  } else {
    start
  }
  let effective_end = if end < 1 || end > total { total } else { end }
  guard effective_start >= 1 && effective_end >= effective_start else {
    raise @error.BeError::InvalidFormat(
      "行范围 \{effective_start}-\{effective_end} 无效，文件总行数为 \{total}",
    )
  }
  let selected = []
  for i in (effective_start - 1)..<effective_end {
    selected.push(lines[i])
  }
  {
    start_line: effective_start,
    end_line: effective_end,
    content: selected.join("\n"),
  }
}

///|
fn resolve_marker_span(
  file : String,
  value : String,
) -> @common.BeRange raise @error.BeError {
  let lines = read_file_lines(file)
  for i = 0; i < lines.length(); i = i + 1 {
    if lines[i].contains(value) {
      let line = i + 1
      return { start_line: line, end_line: line, content: lines[i] }
    }
  }
  raise @error.BeError::InvalidFormat("未找到包含标记 \{value} 的行")
}

///|
fn resolve_function_span(
  file : String,
  value : String,
) -> @common.BeRange raise @error.BeError {
  let matches = find_matching_lines(file, value)
  guard matches.length() > 0 else {
    raise @error.BeError::InvalidFormat("未找到函数名 \{value}")
  }
  for line in matches {
    let result = Some(@check.be_func_range(file, line)) catch {
      @error.BeError::InvalidFormat(_) => None
      e => raise e
    }
    if result is Some(range) {
      return range
    }
  }
  raise @error.BeError::InvalidFormat(
    "未找到函数名 \{value} 所在的函数块",
  )
}

///|
fn resolve_tag_span(
  file : String,
  value : String,
) -> @common.BeRange raise @error.BeError {
  let matches = find_matching_lines(file, value)
  guard matches.length() > 0 else {
    raise @error.BeError::InvalidFormat("未找到标签名 \{value}")
  }
  for line in matches {
    let result = Some(@check.be_tag_range(file, line)) catch {
      @error.BeError::InvalidFormat(_) => None
      e => raise e
    }
    if result is Some(tag_result) {
      return tag_result.range
    }
  }
  raise @error.BeError::InvalidFormat(
    "未找到标签名 \{value} 所在的标签对",
  )
}

///|
fn find_matching_lines(
  file : String,
  value : String,
) -> Array[Int] raise @error.BeError {
  let lines = read_file_lines(file)
  let matches = []
  for i = 0; i < lines.length(); i = i + 1 {
    if lines[i].contains(value) {
      matches.push(i + 1)
    }
  }
  matches
}

///|
fn read_file_lines(file : String) -> Array[String] raise @error.BeError {
  @common.reject_chip_target(file)
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  @common.reject_binary(file)
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  text
  .split("\n")
  .to_array()
  .map(fn(s) { s.to_owned().replace(old="\r", new="") })
}
