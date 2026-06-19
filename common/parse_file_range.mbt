///|
/// 解析形如 `path/to/file.go:10`、`file.go:5-15`、`file.go:ALL` 的输入。
/// 返回 `(path, start_line, end_line)`。
/// `:ALL` 返回 `(path, -1, -1)`；单行返回 `(path, line, line)`。
/// 不带范围后缀时返回 `(input, -1, -1)`。
pub fn parse_file_range(
  input : String,
) -> (String, Int, Int) raise @error.BeError {
  let colon = input.rev_find(":")
  let (path, suffix) = match colon {
    Some(idx) =>
      (
        input.sub(start=0, end=idx).to_owned(),
        input.sub(start=idx + 1, end=input.length()).to_owned(),
      )
    None => (input, "")
  }
  match suffix {
    "" => (input, -1, -1)
    "ALL" => (path, -1, -1)
    _ =>
      // 尝试单行
      match try_parse_int(suffix) {
        Some(n) =>
          if n >= 1 {
            (path, n, n)
          } else {
            raise @error.BeError::InvalidFormat(
              "行号必须为正整数，当前为：\{suffix}",
            )
          }
        None => {
          // 尝试范围
          let sep = match suffix.find("-") {
            Some(idx) => Some(('-', idx))
            None =>
              match suffix.find("~") {
                Some(idx) => Some(('~', idx))
                None => None
              }
          }
          match sep {
            Some((_, idx)) => {
              let start_str = suffix.sub(start=0, end=idx).to_owned()
              let end_str = suffix
                .sub(start=idx + 1, end=suffix.length())
                .to_owned()
              let start = try_parse_int(start_str)
              let end = try_parse_int(end_str)
              match (start, end) {
                (Some(s), Some(e)) =>
                  if s >= 1 && e >= 1 {
                    (path, s, e)
                  } else {
                    raise @error.BeError::InvalidFormat(
                      "行号必须为正整数，当前为：\{suffix}",
                    )
                  }
                _ =>
                  raise @error.BeError::InvalidFormat(
                    "行号必须是整数，当前为：\{suffix}",
                  )
              }
            }
            None => (input, -1, -1)
          }
        }
      }
  }
}

///|
/// 尝试将字符串解析为整数，失败返回 None。
fn try_parse_int(s : String) -> Int? {
  Some(@strconv.from_str(s) catch { _ => return None })
}

///|
/// 判断输入是否包含文件范围后缀（即是否包含非路径部分的行号标记）。
pub fn has_file_range(input : String) -> Bool {
  try {
    let (path, start, end) = parse_file_range(input)
    path != input || start != -1 || end != -1
  } catch {
    _ => true
  }
}
