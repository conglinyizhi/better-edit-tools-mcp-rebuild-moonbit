///|
pub(all) struct BePair {
  kind : String
  open : @common.BeLocation
  close : @common.BeLocation
} derive(Debug, ToJson)

///|
pub extend BePair with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BePair with ToJson::{to_json}

///|
pub(all) struct BeMismatch {
  kind : String
  loc : @common.BeLocation
  reason : String
} derive(Debug, ToJson)

///|
pub extend BeMismatch with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BeMismatch with ToJson::{to_json}

///|
pub(all) struct BeBalanceResult {
  ok : Bool
  pairs : Array[BePair]
  mismatches : Array[BeMismatch]
} derive(Debug, ToJson)

///|
pub extend BeBalanceResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BeBalanceResult with ToJson::{to_json}

///|
priv enum BalanceState {
  Normal
  DoubleString
  SingleString
  LineComment
  BlockComment
  HtmlComment
  InTag
}

///|
priv struct Open {
  kind : String
  name : String
  line : Int
  col : Int
}

///|
fn is_tag_name_start(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == ':'
}

///|
fn balance_is_tag_name_char(c : UInt16) -> Bool {
  is_tag_name_start(c) || (c >= '0' && c <= '9') || c == '-' || c == '.'
}

///|
fn add_mismatch(
  mismatches : Array[BeMismatch],
  kind : String,
  loc : @common.BeLocation,
  reason : String,
) -> Unit {
  mismatches.push({ kind, loc, reason })
}

///|
fn add_pair(
  pairs : Array[BePair],
  kind : String,
  open : Open,
  close : @common.BeLocation,
  verbose : Bool,
) -> Unit {
  if verbose {
    pairs.push({ kind, open: { line: open.line, col: open.col }, close })
  }
}

///|
fn handle_close(
  stack : Array[Open],
  mismatches : Array[BeMismatch],
  pairs : Array[BePair],
  verbose : Bool,
  kind : String,
  loc : @common.BeLocation,
) -> Unit {
  if stack.length() == 0 || stack[stack.length() - 1].kind != kind {
    add_mismatch(mismatches, kind, loc, "unexpected closing \{kind}")
  } else {
    guard stack.pop() is Some(open) else { return }
    add_pair(pairs, kind, open, loc, verbose)
  }
}

///|
/// 检查 file 中的括号、花括号、方括号、HTML/XML 标签以及引号是否成对。
/// verbose=true 时返回全部匹配对；verbose=false（默认）时只返回不匹配项。
pub fn be_balance(
  file : String,
  verbose? : Bool = false,
) -> BeBalanceResult raise @error.BeError {
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  @common.reject_binary(file)
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let pairs : Array[BePair] = []
  let mismatches : Array[BeMismatch] = []
  let stack : Array[Open] = []
  let len = text.length()
  let mut i = 0
  let mut line = 1
  let mut col = 1
  let mut state = BalanceState::Normal
  let mut tag_name = ""
  let mut tag_is_closing = false
  let mut tag_start_line = 0
  let mut tag_start_col = 0
  while i < len {
    let c = text[i]
    match state {
      Normal => {
        if c == '"' {
          stack.push({ kind: "dquote", name: "", line, col })
          state = BalanceState::DoubleString
          i += 1
          col += 1
          continue
        }
        if c == '\'' {
          stack.push({ kind: "squote", name: "", line, col })
          state = BalanceState::SingleString
          i += 1
          col += 1
          continue
        }
        if c == '/' && i + 1 < len {
          let c2 = text[i + 1]
          if c2 == '/' {
            state = BalanceState::LineComment
            i += 2
            col += 2
            continue
          }
          if c2 == '*' {
            state = BalanceState::BlockComment
            i += 2
            col += 2
            continue
          }
        }
        if c == '<' &&
          i + 3 < len &&
          text[i + 1] == '!' &&
          text[i + 2] == '-' &&
          text[i + 3] == '-' {
          state = BalanceState::HtmlComment
          i += 4
          col += 4
          continue
        }
        if c == '<' && i + 1 < len {
          let mut j = i + 1
          let mut closing = false
          if text[j] == '/' {
            closing = true
            j += 1
          }
          if j < len && is_tag_name_start(text[j]) {
            let name_start = j
            while j < len && balance_is_tag_name_char(text[j]) {
              j += 1
            }
            tag_name = text.sub(start=name_start, end=j).to_owned()
            tag_is_closing = closing
            tag_start_line = line
            tag_start_col = col
            let name_len = j - name_start
            col += 1
            if closing {
              col += 1
            }
            col += name_len
            i = j
            state = BalanceState::InTag
            continue
          }
        }
        if c == '(' {
          stack.push({ kind: "paren", name: "", line, col })
        } else if c == ')' {
          handle_close(stack, mismatches, pairs, verbose, "paren", { line, col })
        } else if c == '{' {
          stack.push({ kind: "brace", name: "", line, col })
        } else if c == '}' {
          handle_close(stack, mismatches, pairs, verbose, "brace", { line, col })
        } else if c == '[' {
          stack.push({ kind: "bracket", name: "", line, col })
        } else if c == ']' {
          handle_close(stack, mismatches, pairs, verbose, "bracket", {
            line,
            col,
          })
        }
        if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      }
      DoubleString => {
        if c == '\\' && i + 1 < len {
          i += 2
          col += 2
          continue
        }
        if c == '"' {
          if stack.length() == 0 || stack[stack.length() - 1].kind != "dquote" {
            add_mismatch(
              mismatches,
              "dquote",
              { line, col },
              "unexpected closing quote",
            )
          } else {
            guard stack.pop() is Some(open) else { continue }
            add_pair(pairs, "dquote", open, { line, col }, verbose)
          }
          state = BalanceState::Normal
          i += 1
          col += 1
          continue
        }
        if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      }
      SingleString => {
        if c == '\\' && i + 1 < len {
          i += 2
          col += 2
          continue
        }
        if c == '\'' {
          if stack.length() == 0 || stack[stack.length() - 1].kind != "squote" {
            add_mismatch(
              mismatches,
              "squote",
              { line, col },
              "unexpected closing quote",
            )
          } else {
            guard stack.pop() is Some(open) else { continue }
            add_pair(pairs, "squote", open, { line, col }, verbose)
          }
          state = BalanceState::Normal
          i += 1
          col += 1
          continue
        }
        if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      }
      LineComment =>
        if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
          state = BalanceState::Normal
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
          state = BalanceState::Normal
        } else {
          i += 1
          col += 1
        }
      BlockComment =>
        if c == '*' && i + 1 < len && text[i + 1] == '/' {
          state = BalanceState::Normal
          i += 2
          col += 2
        } else if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      HtmlComment =>
        if c == '-' && i + 2 < len && text[i + 1] == '-' && text[i + 2] == '>' {
          state = BalanceState::Normal
          i += 3
          col += 3
        } else if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      InTag => {
        if c == '/' && i + 1 < len && text[i + 1] == '>' {
          state = BalanceState::Normal
          i += 2
          col += 2
          continue
        }
        if c == '>' {
          if tag_is_closing {
            if stack.length() == 0 || stack[stack.length() - 1].kind != "tag" {
              add_mismatch(
                mismatches,
                "tag",
                { line: tag_start_line, col: tag_start_col },
                "unexpected closing tag </\{tag_name}>",
              )
            } else {
              let top = stack[stack.length() - 1]
              if top.name != tag_name {
                add_mismatch(
                  mismatches,
                  "tag",
                  { line: tag_start_line, col: tag_start_col },
                  "tag mismatch: expected </\{top.name}> but found </\{tag_name}>",
                )
              } else {
                guard stack.pop() is Some(open) else { continue }
                add_pair(pairs, "tag", open, { line, col }, verbose)
              }
            }
          } else {
            stack.push({
              kind: "tag",
              name: tag_name,
              line: tag_start_line,
              col: tag_start_col,
            })
          }
          state = BalanceState::Normal
          i += 1
          col += 1
          continue
        }
        if c == '\r' {
          if i + 1 < len && text[i + 1] == '\n' {
            i += 2
          } else {
            i += 1
          }
          line += 1
          col = 1
        } else if c == '\n' {
          i += 1
          line += 1
          col = 1
        } else {
          i += 1
          col += 1
        }
      }
    }
  }
  match state {
    InTag =>
      if tag_name.length() > 0 && tag_is_closing == false {
        add_mismatch(
          mismatches,
          "tag",
          { line: tag_start_line, col: tag_start_col },
          "unclosed tag <\{tag_name}>",
        )
      }
    _ => ()
  }
  for open in stack {
    add_mismatch(
      mismatches,
      open.kind,
      { line: open.line, col: open.col },
      "unclosed \{open.kind}",
    )
  }
  { ok: mismatches.length() == 0, pairs, mismatches }
}
