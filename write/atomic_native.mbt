///|
#borrow(from, to)
extern "c" fn be_atomic_rename(from : Bytes, to : Bytes) -> Int = "be_atomic_rename"

///|
#borrow(path)
extern "c" fn be_atomic_fsync_file(path : Bytes) -> Int = "be_atomic_fsync_file"

///|
#borrow(path)
extern "c" fn be_atomic_fsync_dir(path : Bytes) -> Int = "be_atomic_fsync_dir"

///|
fn string_to_utf8_bytes(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for char in s {
    let code = char.to_uint()
    if code < 0x80 {
      arr.push(code.to_byte())
    } else if code < 0x800 {
      arr.push((((code >> 6) & 0x1F) | 0xC0).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    } else if code < 0x10000 {
      arr.push((((code >> 12) & 0x0F) | 0xE0).to_byte())
      arr.push((((code >> 6) & 0x3F) | 0x80).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    } else {
      arr.push((((code >> 18) & 0x07) | 0xF0).to_byte())
      arr.push((((code >> 12) & 0x3F) | 0x80).to_byte())
      arr.push((((code >> 6) & 0x3F) | 0x80).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    }
  }
  arr.push(b'\x00')
  Bytes::from_array(arr)
}

///|
fn rename_atomic(from : String, to : String) -> Unit raise @error.BeError {
  let rc = be_atomic_rename(
    string_to_utf8_bytes(from),
    string_to_utf8_bytes(to),
  )
  if rc != 0 {
    raise @error.BeError::WriteError(
      "重命名失败：\{from} -> \{to} (errno=\{rc})",
    )
  }
}

///|
fn fsync_file(path : String) -> Unit raise @error.BeError {
  let rc = be_atomic_fsync_file(string_to_utf8_bytes(path))
  if rc != 0 {
    raise @error.BeError::WriteError(
      "fsync 文件失败：\{path} (errno=\{rc})",
    )
  }
}

///|
fn fsync_dir(path : String) -> Unit {
  if path.is_empty() {
    return
  }
  let rc = be_atomic_fsync_dir(string_to_utf8_bytes(path))
  if rc != 0 {
    // 父目录 fsync 为尽力而为，平台不支持时忽略
    ()
  }
}
