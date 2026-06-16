///|
/// 删除 file 中指定的行。
/// 可通过 lines 传入行号数组；也可通过 start/end 或 start_line/end_line 指定连续范围。
/// 不允许同时指定 lines 和范围，若指定范围则 start/end 与 start_line/end_line 互为别名。
pub fn be_delete(
  file : String,
  lines? : Array[Int] = [],
  start? : Int = 0,
  end? : Int = 0,
  start_line? : Int = 0,
  end_line? : Int = 0,
) -> Unit raise @error.BeError {
  @common.reject_chip_target(file)
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let all_lines = text.split("\n").to_array()
  let total = all_lines.length()
  let mut to_delete : Array[Int] = []
  if lines.length() > 0 {
    if start != 0 || end != 0 || start_line != 0 || end_line != 0 {
      raise @error.BeError::InvalidFormat(
        "不能同时指定 lines 和范围参数",
      )
    }
    to_delete = lines.copy()
    to_delete.sort()
    // 去重
    let deduped : Array[Int] = []
    for i = 0; i < to_delete.length(); i = i + 1 {
      if i == 0 || to_delete[i] != to_delete[i - 1] {
        deduped.push(to_delete[i])
      }
    }
    to_delete.clear()
    to_delete.append(deduped)
    for line in to_delete {
      guard line >= 1 && line <= total else {
        raise @error.BeError::InvalidFormat(
          "行号 \{line} 超出范围 [1, \{total}]",
        )
      }
    }
  } else {
    let s = if start != 0 { start } else { start_line }
    let e = if end != 0 { end } else { end_line }
    if s == 0 && e == 0 {
      raise @error.BeError::InvalidFormat("未指定要删除的行")
    }
    guard s >= 1 && s <= e && e <= total else {
      raise @error.BeError::InvalidFormat(
        "行范围 \{s}-\{e} 无效，文件总行数为 \{total}",
      )
    }
    for i = s; i <= e; i = i + 1 {
      to_delete.push(i)
    }
  }
  let delete_set = Set::from_array(to_delete)
  let remaining : Array[String] = []
  for i = 0; i < all_lines.length(); i = i + 1 {
    let line_no = i + 1
    if !delete_set.contains(line_no) {
      remaining.push(all_lines[i].to_owned())
    }
  }
  let result = remaining.join("\n")
  @fs.write_string_to_file(file, result) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
}
