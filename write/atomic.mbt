///|
let atomic_rand : Ref[@random.Rand?] = { val: None }

///|
fn get_atomic_rand() -> @random.Rand {
  match atomic_rand.val {
    Some(r) => r
    None => {
      let seed = generate_atomic_seed()
      let r = @random.Rand::chacha8(seed~)
      atomic_rand.val = Some(r)
      r
    }
  }
}

///|
fn generate_atomic_seed() -> Bytes {
  let time_str = @env.now().to_string()
  let bytes = []
  for i in 0..<32 {
    bytes.push(time_str[i % time_str.length()].to_int().to_byte())
  }
  Bytes::from_array(bytes)
}

///|
fn bytes_to_hex(bytes : Array[Byte]) -> String {
  let chars = []
  for b in bytes {
    let hex = b.to_int().to_string(radix=16)
    let padded = if hex.length() < 2 { "0" + hex } else { hex }
    chars.push(padded)
  }
  chars.join("")
}

///|
fn make_temp_path(file : String) -> String {
  let r = get_atomic_rand()
  let bytes = []
  for _ in 0..<4 {
    bytes.push(r.uint(limit=256).to_byte())
  }
  "\{file}.tmp.\{bytes_to_hex(bytes)}"
}

///|
fn parent_dir(path : String) -> String {
  match path.rev_find("/") {
    Some(idx) => if idx == 0 { "/" } else { path[:idx].to_owned() }
    None => "."
  }
}

///|
fn cleanup_temp(tmp : String) -> Unit {
  if @fs.path_exists(tmp) {
    @fs.remove_file(tmp) catch {
      _ => ()
    }
  }
}

///|
/// 将 content 原子写入 file：先写入临时文件，再重命名，最后 fsync 父目录。
pub fn write_file_atomic(
  file : String,
  content : String,
) -> Unit raise @error.BeError {
  let tmp = make_temp_path(file)
  try {
    @fs.write_string_to_file(tmp, content) catch {
      IOError(msg) => {
        cleanup_temp(tmp)
        raise @error.BeError::WriteError(msg)
      }
    }
    fsync_file(tmp)
    rename_atomic(tmp, file)
    fsync_dir(parent_dir(file))
  } catch {
    e => {
      cleanup_temp(tmp)
      raise e
    }
  }
  cleanup_temp(tmp)
}

///|
fn find_original(
  file : String,
  originals : Array[(String, String?)],
) -> String? {
  for pair in originals {
    let (f, content) = pair
    if f == file {
      return content
    }
  }
  None
}

///|
fn rollback(
  committed : Array[String],
  originals : Array[(String, String?)],
) -> Array[String] {
  let failures : Array[String] = []
  for file in committed {
    match find_original(file, originals) {
      Some(content) =>
        write_file_atomic(file, content) catch {
          @error.BeError::WriteError(msg) => failures.push("\{file}: \{msg}")
          _ => failures.push("\{file}: rollback failed")
        }
      None =>
        @fs.remove_file(file) catch {
          IOError(msg) => failures.push("\{file}: \{msg}")
        }
    }
  }
  failures
}

///|
/// 原子写入多个文件。若中途失败，回滚所有已提交文件到原始内容。
pub fn write_files_atomic(
  files : Array[(String, String)],
) -> Unit raise @error.BeError {
  let originals : Array[(String, String?)] = []
  for pair in files {
    let (file, _) = pair
    let original = if @fs.path_exists(file) {
      Some(@fs.read_file_to_string(file)) catch {
        IOError(msg) =>
          raise @error.BeError::WriteError(
            "无法读取 \{file} 的原始内容：\{msg}",
          )
      }
    } else {
      None
    }
    originals.push((file, original))
  }
  let committed : Array[String] = []
  let mut failed_file = ""
  let mut failed_reason = ""
  for pair in files {
    let (file, content) = pair
    try {
      write_file_atomic(file, content)
      committed.push(file)
    } catch {
      @error.BeError::WriteError(msg) => {
        failed_file = file
        failed_reason = msg
        break
      }
      _ => {
        failed_file = file
        failed_reason = "unknown error"
        break
      }
    }
  }
  if failed_file != "" {
    let rollback_failures = rollback(committed, originals)
    let detail = if rollback_failures.is_empty() {
      ""
    } else {
      "；回滚失败：" + rollback_failures.join(", ")
    }
    raise @error.BeError::WriteError(
      "写入 \{failed_file} 失败：\{failed_reason}\{detail}",
    )
  }
}
