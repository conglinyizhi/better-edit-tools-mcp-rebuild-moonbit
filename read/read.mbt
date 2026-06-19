///|
/// be-read 结果
pub(all) struct BeReadResult {
  viewed_code_id : String
  range : @common.BeRange
} derive(Debug, ToJson)

///|
/// 按 "path:start-end"、"path:start~end" 或 "path:line" 格式读取文件。
/// start、end、line 均为 1-based 行号；单独指定行号时只读取该行。
/// 也可直接传 "path" 读取整个文件。
/// 返回内容包括读取范围内的所有行，以及用于后续校验的 viewed_code_id。
/// 若提供 target，则 input 视为纯路径，由 target 解析目标范围。
pub fn be_read(
  input : String,
  target? : BeTarget,
) -> BeReadResult raise @error.BeError {
  match target {
    Some(t) => {
      @common.reject_chip_target(input)
      let range = resolve_target_span(input, t)
      let viewed_code_id = @session.create_session(
        input,
        range.start_line,
        range.end_line,
      )
      { viewed_code_id, range }
    }
    None => {
      let colon = input.rev_find(":")
      let (path, range_opt) = match colon {
        Some(idx) =>
          (
            input.sub(start=0, end=idx).to_owned(),
            Some(input.sub(start=idx + 1, end=input.length()).to_owned()),
          )
        None => (input, None)
      }
      @common.reject_chip_target(path)
      let (start_line, end_line) = match range_opt {
        Some(range) => {
          let sep = match range.find("-") {
            Some(idx) => Some(idx)
            None => range.find("~")
          }
          let (start, end) = match sep {
            Some(idx) => {
              let s = @strconv.from_str(range.sub(start=0, end=idx)) catch {
                _ =>
                  raise @error.BeError::InvalidFormat(
                    "行号必须是整数，当前为：\{range}",
                  )
              }
              let e = @strconv.from_str(
                range.sub(start=idx + 1, end=range.length()),
              ) catch {
                _ =>
                  raise @error.BeError::InvalidFormat(
                    "行号必须是整数，当前为：\{range}",
                  )
              }
              (s, e)
            }
            None => {
              let line = @strconv.from_str(range) catch {
                _ =>
                  raise @error.BeError::InvalidFormat(
                    "行号必须是整数，当前为：\{range}",
                  )
              }
              (line, line)
            }
          }
          guard start >= 1 && end >= start else {
            raise @error.BeError::InvalidFormat(
              "行号必须为正整数且 start <= end，当前为：\{range}",
            )
          }
          (start, end)
        }
        None => (1, -1)
      }
      guard @fs.path_exists(path) else {
        raise @error.BeError::FileNotFound(path)
      }
      let is_regular = @fs.is_file(path) catch {
        IOError(msg) => raise @error.BeError::ReadError(msg)
      }
      guard is_regular else { raise @error.BeError::NotARegularFile(path) }
      @common.reject_binary(path)
      let text = @fs.read_file_to_string(path) catch {
        IOError(msg) => raise @error.BeError::ReadError(msg)
      }
      let lines = @common.split_lines(text)
      let total = lines.length()
      if total == 0 {
        return {
          viewed_code_id: @session.create_session(path, 0, 0),
          range: { start_line: 0, end_line: 0, content: "" },
        }
      }
      let effective_start = if start_line > total { total } else { start_line }
      let effective_end = if range_opt is None ||
        end_line > total ||
        end_line < 1 {
        total
      } else {
        end_line
      }
      guard effective_start >= 1 && effective_end >= effective_start else {
        raise @error.BeError::InvalidFormat(
          "行范围 \{effective_start}-\{effective_end} 无效，文件总行数为 \{total}",
        )
      }
      let selected = []
      for i in (effective_start - 1)..<effective_end {
        selected.push(lines[i])
      }
      let content = selected.join("\n")
      let viewed_code_id = @session.create_session(
        path, effective_start, effective_end,
      )
      {
        viewed_code_id,
        range: { start_line: effective_start, end_line: effective_end, content },
      }
    }
  }
}
