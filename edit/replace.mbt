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
  format? : String = "plain",
  preview? : Bool = false,
  brief? : Bool = false,
) -> EditResult raise @error.BeError {
  // 验证文件并读取内容
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
  let line_ending = @common.detect_file_line_ending(file)

  // 验证行范围
  let lines = @common.split_lines(text)
  let total = lines.length()
  guard start_line >= 1 && end_line >= start_line && end_line <= total else {
    raise @error.BeError::InvalidFormat(
      "行范围必须满足 1 <= start <= end <= total，当前为：\{start_line}-\{end_line}，文件总行数：\{total}",
    )
  }

  // 构建当前范围内容
  let selected = []
  for i in (start_line - 1)..<end_line {
    selected.push(lines[i])
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

  // 规范化新内容
  let resolved = @chip.resolve(content)
  let normalized = resolved.replace_all(old="\\n", new="\n")
  let new_lines : Array[String] = @common.prepare_content_lines(
    normalized, line_ending,
  )

  // 构造编辑后内容
  let result_lines = []
  for i in 0..<(start_line - 1) {
    result_lines.push(lines[i])
  }
  for line in new_lines {
    result_lines.push(line)
  }
  for i in end_line..<total {
    result_lines.push(lines[i])
  }
  let new_content = result_lines.join(line_ending)
  let new_total = result_lines.length()

  // 受影响行号
  let affected = []
  for i = start_line; i <= end_line; i = i + 1 {
    affected.push(i)
  }

  // diff 与 balance
  let diff_str = if !brief && format == "diff" {
    build_diff(selected, new_lines, start_line, file)
  } else {
    ""
  }
  let balance = quick_balance_check(new_content)

  // 预览模式不写入文件
  if preview {
    warnings.append(@common.scan_content_warnings(new_content))
    return {
      status: "preview",
      file,
      removed: selected.length(),
      added: new_lines.length(),
      total: new_total,
      diff: diff_str,
      balance,
      affected,
      preview: true,
      brief,
      warnings,
      event_id: new_event_id(),
      queue_full: false,
    }
  }

  // 写入前加入快照队列
  let (event_id, queue_warning) = @snapshot.push_snapshot(file, text)
  let queue_full = queue_warning.length() > 0

  // 原子写入
  @write.write_file_atomic(file, new_content)

  // 内容警告
  warnings.append(@common.scan_content_warnings(new_content))

  {
    status: "ok",
    file,
    removed: selected.length(),
    added: new_lines.length(),
    total: new_total,
    diff: diff_str,
    balance,
    affected,
    preview: false,
    brief,
    warnings,
    event_id,
    queue_full,
  }
}
