///|
/// 在 file 的指定行后插入 content。
/// line=0 或 after_line=0 表示插入到文件开头。
/// line 与 after_line 是同义参数，若同时非零且不一致则报错。
/// content 中的字面 `\n` 会替换为真正的换行符。
pub fn be_insert(
  file : String,
  content : String,
  line? : Int = 0,
  after_line? : Int = 0,
) -> Unit raise @error.BeError {
  if line != 0 && after_line != 0 && line != after_line {
    raise @error.BeError::InvalidFormat("line 与 after_line 不一致")
  }
  let target = if line != 0 { line } else { after_line }
  @common.reject_chip_target(file)
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let resolved = @chip.resolve(content)
  let normalized = resolved.replace_all(old="\\n", new="\n")
  let lines = if text.is_empty() {
    []
  } else {
    let arr = text.split("\n").to_array()
    if text.has_suffix("\n") {
      arr.pop() |> ignore
    }
    arr
  }
  let total = lines.length()
  guard target >= 0 && target <= total else {
    raise @error.BeError::InvalidFormat(
      "行号 \{target} 超出范围 0..\{total}",
    )
  }
  let result = []
  for i = 0; i < target; i = i + 1 {
    result.push(lines[i])
  }
  result.push(normalized)
  for i = target; i < total; i = i + 1 {
    result.push(lines[i])
  }
  let output = result.join("\n")
  @write.write_file_atomic(file, output)
}
