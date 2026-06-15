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
