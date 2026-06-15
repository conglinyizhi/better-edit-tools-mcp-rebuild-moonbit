///|
/// 精确替换 file 中 [start_line, end_line] 范围的内容。
/// 传入 viewed_code_id 时会与当前范围计算出的 id 校验；
/// 传入 old 或 old_text 时会校验当前范围内容是否一致。
pub fn be_replace(
  file : String,
  start_line : Int,
  end_line : Int,
  content : String,
  viewed_code_id? : String = "",
  old? : String = "",
  old_text? : String = "",
) -> Unit raise @error.BeError {
  // 验证文件并读取内容
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }

  // 验证行范围
  let lines = text.split("\n").to_array()
  let total = lines.length()
  guard start_line >= 1 && end_line >= start_line && end_line <= total else {
    raise @error.BeError::InvalidFormat(
      "行范围必须满足 1 <= start <= end <= total，当前为：\{start_line}-\{end_line}，文件总行数：\{total}",
    )
  }

  // 构建当前范围内容
  let selected = []
  for i in (start_line - 1)..<end_line {
    selected.push(lines[i].to_owned().replace(old="\r", new=""))
  }
  let current_content = selected.join("\n")

  // 校验 viewed_code_id
  let expected_id = @common.compute_viewed_code_id(
    file, start_line, end_line, current_content,
  )
  if viewed_code_id.length() > 0 && viewed_code_id != expected_id {
    raise @error.BeError::InvalidFormat(
      "viewed_code_id 不匹配，期望：\{expected_id}，实际：\{viewed_code_id}",
    )
  }

  // 校验 old / old_text
  let expected_old = if old.length() > 0 { old } else { old_text }
  if expected_old.length() > 0 && expected_old != current_content {
    raise @error.BeError::InvalidFormat(
      "old / old_text 与当前范围内容不匹配",
    )
  }

  // 规范化新内容并替换范围
  let normalized = content.replace_all(old="\\n", new="\n")
  let new_lines = normalized.split("\n").to_array()
  let result = []
  for i in 0..<(start_line - 1) {
    result.push(lines[i].to_owned())
  }
  for line in new_lines {
    result.push(line.to_owned())
  }
  for i in end_line..<total {
    result.push(lines[i].to_owned())
  }
  @fs.write_string_to_file(file, result.join("\n")) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
}
