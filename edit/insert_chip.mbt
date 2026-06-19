///|
pub(all) enum BeInsertChipResult {
  Inserted
  ChipIds(Array[String])
} derive(Debug, ToJson)

///|
fn read_chip_content(from : String) -> String raise @error.BeError {
  if from.has_prefix("file:///") {
    let path = from[8:].to_owned()
    guard @fs.path_exists(path) else {
      raise @error.BeError::FileNotFound(path)
    }
    @fs.read_file_to_string(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
  } else if from.has_prefix("chip://") {
    let id = from[7:].to_owned()
    @chip.read(id)
  } else {
    raise @error.BeError::InvalidFormat(
      "from 格式应为 file:///path 或 chip://id",
    )
  }
}

///|
/// 从 chip 缓存或本地文件读取内容并插入到 file 的指定行后。
/// from 为空时返回所有可用的 chip ID。
/// from 格式：file:///absolute/path 或 chip://{id}
/// line=0 表示插入到文件开头。
pub fn be_insert_chip(
  file : String,
  line? : Int = 0,
  from? : String = "",
) -> BeInsertChipResult raise @error.BeError {
  @common.reject_chip_target(file)
  if from == "" {
    return ChipIds(@chip.list())
  }
  guard @fs.path_exists(file) else { raise @error.BeError::FileNotFound(file) }
  let is_regular = @fs.is_file(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  guard is_regular else { raise @error.BeError::NotARegularFile(file) }
  let content = read_chip_content(from)
  let text = @fs.read_file_to_string(file) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let lines = text.split("\n").to_array()
  let total = lines.length()
  let pos = if line <= 0 { 0 } else if line > total { total } else { line }
  let result = []
  for i in 0..<pos {
    result.push(lines[i].to_owned())
  }
  result.push(content)
  for i in pos..<total {
    result.push(lines[i].to_owned())
  }
  @write.write_file_atomic(file, result.join("\n"))
  Inserted
}
