///|
pub(all) enum BeInsertChipResult {
  Inserted
  ChipIds(Array[String])
} derive(Debug, ToJson)

///|
let chip_dir : String = "/tmp/better-edit-tools-chips"

///|
fn ensure_chip_dir() -> Unit raise @error.BeError {
  if !@fs.path_exists(chip_dir) {
    @fs.create_dir(chip_dir) catch {
      IOError(msg) => raise @error.BeError::WriteError(msg)
    }
  }
}

///|
fn list_chip_ids() -> Array[String] raise @error.BeError {
  ensure_chip_dir()
  let entries = @fs.read_dir(chip_dir) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let ids = []
  for entry in entries {
    let path = chip_dir + "/" + entry
    let is_regular = @fs.is_file(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
    if is_regular {
      ids.push(entry)
    }
  }
  ids.sort()
  ids
}

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
    let path = chip_dir + "/" + id
    guard @fs.path_exists(path) else {
      raise @error.BeError::FileNotFound(path)
    }
    @fs.read_file_to_string(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
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
  if from == "" {
    return ChipIds(list_chip_ids())
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
  @fs.write_string_to_file(file, result.join("\n")) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
  Inserted
}
