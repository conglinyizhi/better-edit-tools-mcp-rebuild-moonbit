///|
/// 读取文件样本，若判断为二进制文件则抛出 ReadError。
pub fn reject_binary(path : String) -> Unit raise @error.BeError {
  if !@fs.path_exists(path) {
    return
  }
  let bytes = @fs.read_file_to_bytes(path) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let sample_len = if bytes.length() > 512 { 512 } else { bytes.length() }
  if sample_len == 0 {
    return
  }
  let mut null_count = 0
  let mut unprintable = 0
  for i in 0..<sample_len {
    let b = bytes[i].to_int()
    if b == 0 {
      null_count += 1
    } else if b < 32 && b != 9 && b != 10 && b != 13 {
      unprintable += 1
    }
  }
  if null_count > 0 || unprintable * 5 > sample_len * 2 {
    raise @error.BeError::ReadError("\{path} appears to be a binary file")
  }
}
