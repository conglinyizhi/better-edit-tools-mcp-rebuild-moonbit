///|
/// be-replace 的返回结果，包含非致命警告。
pub(all) struct BeReplaceResult {
  warnings : Array[String]
} derive(Debug, ToJson)

///|
/// 精确替换 file 中 [start_line, end_line] 范围的内容。
/// 传入 viewed_code_id 时会校验会话中的文件行数是否变化；
/// 传入 old 或 old_text 时会校验当前范围内容是否一致。
pub fn be_replace(
  file : String,
  start_line : Int,
  end_line : Int,
  content : String,
  viewed_code_id? : String = "",
  old? : String = "",
  old_text? : String = "",
) -> BeReplaceResult raise @error.BeError {
  // 验证文件并读取内容
  @common.reject_chip_target(file)
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

  // 校验 viewed_code_id 对应的会话，仅收集非致命警告
  let warnings : Array[String] = []
  if viewed_code_id.length() > 0 {
    let (_, warning) = @session.session_from_cache(viewed_code_id)
    if warning.length() > 0 {
      warnings.push(warning)
    }
  }

  // 校验 old / old_text
  let expected_old = if old.length() > 0 { old } else { old_text }
  if expected_old.length() > 0 && expected_old != current_content {
    raise @error.BeError::InvalidFormat(
      "old / old_text 与当前范围内容不匹配",
    )
  }

  // 写入前加入快照队列
  let (_, _) = @snapshot.push_snapshot(file, text)

  // 规范化新内容并替换范围
  let resolved = @chip.resolve(content)
  let normalized = resolved.replace_all(old="\\n", new="\n")
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
  @write.write_file_atomic(file, result.join("\n"))
  { warnings, }
}
