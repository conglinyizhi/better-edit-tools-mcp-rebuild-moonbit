// 库代码的主包文件。
// 将公共 API 和共享辅助函数放在这里。
// 保持代码块小巧专注，便于重构。

///|
/// be-read 错误类型
pub(all) suberror BeReadError {
  InvalidFormat(String)
  FileNotFound(String)
  ReadError(String)
}

///|
/// be-read 结果
pub(all) struct BeReadResult {
  content : String
  viewed_code_id : String
  start_line : Int
  end_line : Int
} derive(Debug)

///|
/// 按 "path:start-end" 格式读取文件指定行范围。
/// start 和 end 均为 1-based 行号。
/// 返回内容包括该范围内的所有行，以及用于后续校验的 viewed_code_id。
pub fn be_read(input : String) -> BeReadResult raise BeReadError {
  let colon = input.rev_find(":")
  guard colon is Some(idx) else {
    raise BeReadError::InvalidFormat(
      "输入格式应为 /path/to/file:1-10，当前为：\{input}",
    )
  }
  let path = input.sub(start=0, end=idx).to_owned()
  let range = input.sub(start=idx + 1, end=input.length()).to_owned()
  let dash = range.find("-")
  guard dash is Some(dash_idx) else {
    raise BeReadError::InvalidFormat(
      "行范围格式应为 start-end，当前为：\{range}",
    )
  }
  let start_line = @strconv.from_str(range.sub(start=0, end=dash_idx)) catch {
    _ =>
      raise BeReadError::InvalidFormat(
        "行号必须是整数，当前为：\{range}",
      )
  }
  let end_line = @strconv.from_str(
    range.sub(start=dash_idx + 1, end=range.length()),
  ) catch {
    _ =>
      raise BeReadError::InvalidFormat(
        "行号必须是整数，当前为：\{range}",
      )
  }
  guard start_line >= 1 && end_line >= start_line else {
    raise BeReadError::InvalidFormat(
      "行号必须为正整数且 start <= end，当前为：\{range}",
    )
  }
  guard @fs.path_exists(path) else { raise BeReadError::FileNotFound(path) }
  let text = @fs.read_file_to_string(path) catch {
    IOError(msg) => raise BeReadError::ReadError(msg)
  }
  let lines = text.split("\n").to_array()
  let total = lines.length()
  guard start_line <= total else {
    raise BeReadError::InvalidFormat(
      "起始行号 \{start_line} 超出文件总行数 \{total}",
    )
  }
  let effective_end = if end_line > total { total } else { end_line }
  let selected = []
  for i in (start_line - 1)..<effective_end {
    selected.push(lines[i].to_owned().replace(old="\r", new=""))
  }
  let content = selected.join("\n")
  let viewed_code_id = "\{path}:\{start_line}-\{effective_end}:\{content.hash()}"
    .hash()
    .to_string()
  { content, viewed_code_id, start_line, end_line: effective_end }
}

///|
/// be-write 错误类型
pub(all) suberror BeWriteError {
  WriteError(String)
}

///|
/// 将 content 完整写入 file 指定的路径。
/// content 中的字面 `\n` 会被替换为真正的换行符。
pub fn be_write(file : String, content : String) -> Unit raise BeWriteError {
  let normalized = content.replace_all(old="\\n", new="\n")
  @fs.write_string_to_file(file, normalized) catch {
    IOError(msg) => raise BeWriteError::WriteError(msg)
  }
}
