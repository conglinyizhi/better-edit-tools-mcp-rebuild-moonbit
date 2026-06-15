///|
/// `be_func_range` 结果
pub(all) struct BeFuncRangeResult {
  start_line : Int
  end_line : Int
  content : String
} derive(Debug, Show, ToJson)

///|
priv struct Block {
  start : Int
  end : Int
}

///|
priv enum State {
  Normal
  LineComment
  BlockComment
  DQString
  SQString
} derive(Eq)

///|
/// 定位 file 第 line 行（1-based）所在的 {} 块范围。
/// 返回该块的起止行号及内容。
pub fn be_func_range(
  file : String,
  line : Int,
) -> BeFuncRangeResult raise @error.BeError {
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let raw_lines = text.split("\n").to_array()
  let total = raw_lines.length()
  guard line >= 1 && line <= total else {
    raise @error.BeError::InvalidFormat(
      "行号必须在 1 到 \{total} 之间，当前为：\{line}",
    )
  }
  let blocks = scan_blocks(raw_lines)
  let mut chosen : Block? = None
  for b in blocks {
    if b.start <= line && line <= b.end {
      match chosen {
        Some(cur) => if b.start > cur.start { chosen = Some(b) }
        None => chosen = Some(b)
      }
    }
  }
  guard chosen is Some(b) else {
    raise @error.BeError::InvalidFormat("第 \{line} 行不在任何 {} 块内")
  }
  let content_lines = []
  for i in (b.start - 1)..<b.end {
    content_lines.push(raw_lines[i].to_owned().replace(old="\r", new=""))
  }
  { start_line: b.start, end_line: b.end, content: content_lines.join("\n") }
}

///|
fn scan_blocks(lines : Array[StringView]) -> Array[Block] {
  let blocks : Array[Block] = []
  let stack : Array[Int] = []
  let mut state = State::Normal
  for i = 0; i < lines.length(); i = i + 1 {
    let chars = lines[i].to_owned().to_array()
    let mut j = 0
    while j < chars.length() {
      let c = chars[j]
      match state {
        Normal => {
          if c == '/' && j + 1 < chars.length() {
            let next = chars[j + 1]
            if next == '/' {
              state = State::LineComment
              break
            } else if next == '*' {
              state = State::BlockComment
              j = j + 2
              continue
            }
          }
          if c == '"' {
            state = State::DQString
            j = j + 1
            continue
          }
          if c == '\'' {
            state = State::SQString
            j = j + 1
            continue
          }
          if c == '{' {
            stack.push(i + 1)
          } else if c == '}' {
            if stack.length() > 0 {
              let start = stack.pop().unwrap()
              blocks.push({ start, end: i + 1 })
            }
          }
          j = j + 1
        }
        LineComment => break
        BlockComment => {
          if c == '*' && j + 1 < chars.length() && chars[j + 1] == '/' {
            state = State::Normal
            j = j + 2
            continue
          }
          j = j + 1
        }
        DQString => {
          if c == '\\' && j + 1 < chars.length() {
            j = j + 2
            continue
          }
          if c == '"' {
            state = State::Normal
            j = j + 1
            continue
          }
          j = j + 1
        }
        SQString => {
          if c == '\\' && j + 1 < chars.length() {
            j = j + 2
            continue
          }
          if c == '\'' {
            state = State::Normal
            j = j + 1
            continue
          }
          j = j + 1
        }
      }
    }
    if state == State::LineComment {
      state = State::Normal
    }
  }
  blocks
}
