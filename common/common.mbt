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
