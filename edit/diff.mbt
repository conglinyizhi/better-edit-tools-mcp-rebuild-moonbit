///|
/// 根据旧行数组、新行数组、起始行号、文件路径生成统一 diff 字符串。
fn build_diff(
  old_lines : Array[String],
  new_lines : Array[String],
  start_line : Int,
  file : String,
) -> String {
  let parts : Array[String] = []
  parts.push("--- a/\{file}")
  parts.push("+++ b/\{file}")
  parts.push(
    "@@ -\{start_line},\{old_lines.length()} +\{start_line},\{new_lines.length()} @@",
  )
  for line in old_lines {
    parts.push("- \{line}")
  }
  for line in new_lines {
    parts.push("+ \{line}")
  }
  parts.join("\n")
}

///|
fn is_tag_name_char(c : UInt16) -> Bool {
  let code = c.to_int()
  (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
  (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
  (code >= '0'.to_int() && code <= '9'.to_int()) ||
  code == '-'.to_int() ||
  code == ':'.to_int() ||
  code == '_'.to_int()
}

///|
fn advance_pos(
  content : String,
  c : UInt16,
  i : Int,
  line : Int,
  col : Int,
  len : Int,
) -> (Int, Int, Int) {
  if c == '\r'.to_int().to_uint16() {
    if i + 1 < len && content[i + 1] == '\n'.to_int().to_uint16() {
      (i + 2, line + 1, 1)
    } else {
      (i + 1, line + 1, 1)
    }
  } else if c == '\n'.to_int().to_uint16() {
    (i + 1, line + 1, 1)
  } else {
    (i + 1, line, col + 1)
  }
}

///|
/// 对新内容做快速括号/引号/HTML 标签配对检查，返回问题描述或空字符串。
fn quick_balance_check(content : String) -> String {
  let len = content.length()
  let mut i = 0
  let mut line = 1
  let mut col = 1
  let stack : Array[(String, Int, Int, String)] = []
  let mut quote : UInt16? = None
  while i < len {
    let c = content[i]
    if quote is Some(q) {
      if c == '\\'.to_int().to_uint16() && i + 1 < len {
        i += 2
        col += 2
        continue
      }
      if c == q {
        quote = None
      }
      let (ni, nl, nc) = advance_pos(content, c, i, line, col, len)
      i = ni
      line = nl
      col = nc
      continue
    }
    if c == '('.to_int().to_uint16() {
      stack.push(("paren", line, col, ""))
    } else if c == ')'.to_int().to_uint16() {
      match stack.pop() {
        Some((kind, _, _, _)) =>
          if kind != "paren" {
            return "unexpected ) at line \{line}"
          }
        None => return "unexpected ) at line \{line}"
      }
    } else if c == '['.to_int().to_uint16() {
      stack.push(("bracket", line, col, ""))
    } else if c == ']'.to_int().to_uint16() {
      match stack.pop() {
        Some((kind, _, _, _)) =>
          if kind != "bracket" {
            return "unexpected ] at line \{line}"
          }
        None => return "unexpected ] at line \{line}"
      }
    } else if c == '{'.to_int().to_uint16() {
      stack.push(("brace", line, col, ""))
    } else if c == '}'.to_int().to_uint16() {
      match stack.pop() {
        Some((kind, _, _, _)) =>
          if kind != "brace" {
            return "unexpected } at line \{line}"
          }
        None => return "unexpected } at line \{line}"
      }
    } else if c == '"'.to_int().to_uint16() || c == '\''.to_int().to_uint16() {
      quote = Some(c)
    } else if c == '<'.to_int().to_uint16() && i + 1 < len {
      let mut j = i + 1
      let mut closing = false
      if content[j] == '/'.to_int().to_uint16() {
        closing = true
        j += 1
      }
      let name_start = j
      while j < len && is_tag_name_char(content[j]) {
        j += 1
      }
      if j > name_start {
        let name = content.sub(start=name_start, end=j).to_owned()
        let mut k = j
        let mut self_closing = false
        while k < len {
          let ch = content[k]
          if ch == '/'.to_int().to_uint16() &&
            k + 1 < len &&
            content[k + 1] == '>'.to_int().to_uint16() {
            self_closing = true
            k += 2
            break
          }
          if ch == '>'.to_int().to_uint16() {
            k += 1
            break
          }
          k += 1
        }
        if !self_closing && k >= len {
          return "unclosed tag <\{name}>"
        }
        if !self_closing {
          if closing {
            match stack.pop() {
              Some((kind, _, _, top_name)) =>
                if kind != "tag" || top_name != name {
                  return "unexpected closing tag </\{name}> at line \{line}"
                }
              None => return "unexpected closing tag </\{name}> at line \{line}"
            }
          } else {
            stack.push(("tag", line, col, name))
          }
        }
        i = k
        continue
      }
    }
    let (ni, nl, nc) = advance_pos(content, c, i, line, col, len)
    i = ni
    line = nl
    col = nc
  }
  match quote {
    Some(_) => return "unclosed quote at line \{line}"
    None => ()
  }
  if stack.length() > 0 {
    let top = stack[stack.length() - 1]
    return "unclosed \{top.0} at line \{top.1}"
  }
  ""
}
