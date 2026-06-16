///|
/// 表示文件中的一个行范围（1-based，包含首尾）及其内容。
pub(all) struct BeRange {
  start_line : Int
  end_line : Int
  content : String
} derive(Debug, ToJson)

///|
/// 表示文件中的一个位置（1-based 行号/列号）。
pub(all) struct BeLocation {
  line : Int
  col : Int
} derive(Debug, ToJson)

///|
/// 计算 be-read 返回的 viewed_code_id，供 be-replace 校验使用。
pub fn compute_viewed_code_id(
  path : String,
  start_line : Int,
  end_line : Int,
  content : String,
) -> String {
  "\{path}:\{start_line}-\{end_line}:\{content.hash()}".hash().to_string()
}

///|
/// 校验 file 参数不是 chip://{id}。chip 只能作为内容来源，不能作为目标文件。
pub fn reject_chip_target(file : String) -> Unit raise @error.BeError {
  if file.has_prefix("chip://") {
    raise @error.BeError::InvalidFormat("file 参数不能是 chip://{id}")
  }
}
