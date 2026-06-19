///|
/// 扫描内容中的潜在问题：tab、行尾空白、文件末无换行。
/// 返回警告字符串数组。
pub fn scan_content_warnings(content : String) -> Array[String] {
  let warnings : Array[String] = []
  let lines = split_lines(content)
  let mut trailing = false
  let mut tab_lines = 0
  let mut non_empty = 0
  for line in lines {
    if line.length() > 0 {
      let last = line[line.length() - 1]
      if last == ' ' || last == '\t' {
        trailing = true
      }
      if line.trim().length() > 0 {
        non_empty += 1
        if line.contains("\t") {
          tab_lines += 1
        }
      }
    }
  }
  if trailing {
    warnings.push("content contains trailing whitespace...")
  }
  if tab_lines > 0 && non_empty > 0 && tab_lines * 2 <= non_empty {
    warnings.push("content contains tabs; prefer spaces for indentation")
  }
  if content.length() > 0 && !content.has_suffix("\n") {
    warnings.push("no newline at end of file")
  }
  warnings
}
