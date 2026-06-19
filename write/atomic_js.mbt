///|
extern "js" fn be_atomic_rename_js(from : String, to : String) -> Int =
  #| function(from, to) {
  #|   var fs = require('fs');
  #|   try {
  #|     fs.renameSync(from, to);
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.beAtomicError = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn be_atomic_fsync_file_js(path : String) -> Int =
  #| function(path) {
  #|   var fs = require('fs');
  #|   try {
  #|     var fd = fs.openSync(path, 'r');
  #|     fs.fsyncSync(fd);
  #|     fs.closeSync(fd);
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.beAtomicError = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn be_atomic_fsync_dir_js(path : String) -> Int =
  #| function(path) {
  #|   var fs = require('fs');
  #|   try {
  #|     var fd = fs.openSync(path, 'r');
  #|     fs.fsyncSync(fd);
  #|     fs.closeSync(fd);
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.beAtomicError = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn be_atomic_get_error_js() -> String =
  #| function() {
  #|   return globalThis.beAtomicError || '';
  #| }

///|
fn rename_atomic(from : String, to : String) -> Unit raise @error.BeError {
  let rc = be_atomic_rename_js(from, to)
  if rc != 0 {
    raise @error.BeError::WriteError(
      "重命名失败：\{from} -> \{to}：\{be_atomic_get_error_js()}",
    )
  }
}

///|
fn fsync_file(path : String) -> Unit raise @error.BeError {
  let rc = be_atomic_fsync_file_js(path)
  if rc != 0 {
    raise @error.BeError::WriteError(
      "fsync 文件失败：\{path}：\{be_atomic_get_error_js()}",
    )
  }
}

///|
fn fsync_dir(path : String) -> Unit {
  if path.is_empty() {
    return
  }
  let rc = be_atomic_fsync_dir_js(path)
  if rc != 0 {
    // 父目录 fsync 为尽力而为
    ()
  }
}
