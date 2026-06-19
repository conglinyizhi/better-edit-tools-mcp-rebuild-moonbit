///|
/// 统一的工具错误类型。
/// 所有 be-* 工具都使用此错误类型，方便调用方统一处理。
pub(all) suberror BeError {
  InvalidFormat(String)
  InvalidArgument(String)
  FileNotFound(String)
  NotARegularFile(String)
  PathError(String)
  ReadError(String)
  WriteError(String)
  IOError(String)
}
