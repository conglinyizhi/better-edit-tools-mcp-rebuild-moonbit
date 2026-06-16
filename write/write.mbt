///|
fn parse_chip_id(s : String) -> String? {
  guard s.has_prefix("chip://") else { return None }
  let rest = s[7:].to_owned()
  match rest.find(" ") {
    Some(idx) => Some(rest[:idx].to_owned())
    None => Some(rest)
  }
}

///|
/// 将 content 完整写入 file 指定的路径。
/// content 中的字面 `\n` 会被替换为真正的换行符。
/// 如果 content 以 `chip://` 开头，则从对应 chip 读取内容并写入。
/// 写入失败时，将内容保存到 chip 并返回 `chip://{id} 写入失败：{error}`，
/// 其中 `chip://{id}` 可直接作为后续调用的 content 参数。
pub fn be_write(file : String, content : String) -> String raise @error.BeError {
  match parse_chip_id(content) {
    Some(chip_id) => {
      let chip_content = @chip.read(chip_id)
      @fs.write_string_to_file(file, chip_content) catch {
        IOError(msg) => raise @error.BeError::WriteError(msg)
      }
      return ""
    }
    None => ()
  }
  let normalized = content.replace_all(old="\\n", new="\n")
  @fs.write_string_to_file(file, normalized) catch {
    IOError(msg) =>
      return "chip://" + @chip.save(normalized) + " 写入失败：" + msg
  }
  ""
}
