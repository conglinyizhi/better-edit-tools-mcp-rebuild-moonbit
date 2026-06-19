///|
fn rename_atomic(from : String, to : String) -> Unit raise @error.BeError {
  // Wasm/Wasm-GC 目标下 @fs 未暴露 rename，采用读临时文件再写目标文件的回退方案，
  // 无法保证原子性，但可保持函数语义。
  let content = @fs.read_file_to_string(from) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
  @fs.write_string_to_file(to, content) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
  @fs.remove_file(from) catch {
    _ => ()
  }
}

///|
fn fsync_file(_path : String) -> Unit {
  // Wasm 目标不支持 fsync
  ()
}

///|
fn fsync_dir(_path : String) -> Unit {
  // Wasm 目标不支持 fsync
  ()
}
