///|
/// 将 content 完整写入 file 指定的路径。
/// content 中的字面 `\n` 会被替换为真正的换行符。
/// 如果 content 以 `chip://` 开头，则从对应 chip 读取内容并写入。
/// 写入失败时，将内容保存到 chip 并返回 `chip://{id} 写入失败：{error}`，
/// 其中 `chip://{id}` 可直接作为后续调用的 content 参数。
pub fn be_write(file : String, content : String) -> String raise @error.BeError {
  @common.reject_chip_target(file)
  let resolved = @chip.resolve(content)
  let normalized = resolved.replace_all(old="\\n", new="\n")
  write_file_atomic(file, normalized) catch {
    @error.BeError::WriteError(msg) =>
      return "chip://" + @chip.save(normalized) + " 写入失败：" + msg
    e => raise e
  }
  ""
}
