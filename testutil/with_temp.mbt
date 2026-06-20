///|
/// 生成唯一临时文件路径，执行 f，无论成败都清理文件。
pub fn[T] with_temp_file(
  base_name~ : String,
  f : (String) -> T raise Error,
) -> T raise Error {
  let suffix = generate_suffix()
  let path = "/tmp/bet-\{base_name}-\{suffix}"
  try {
    let result = f(path)
    cleanup_file(path)
    result
  } catch {
    e => {
      cleanup_file(path)
      raise e
    }
  }
}

///|
let counter : Ref[Int] = { val: 0 }

///|
fn generate_suffix() -> String {
  counter.val = counter.val + 1
  counter.val.to_string()
}

///|
fn cleanup_file(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}
