///|
let max_chip_count : Int = 30

///|
fn cache_dir() -> String {
  match @env.get_env_var("LOCALAPPDATA") {
    Some(dir) => dir + "/better-edit-tools-mcp/chips"
    None =>
      match @env.get_env_var("HOME") {
        Some(home) =>
          match @env.get_env_var("XDG_CACHE_HOME") {
            Some(xdg) => xdg + "/better-edit-tools-mcp/chips"
            None => home + "/.cache/better-edit-tools-mcp/chips"
          }
        None => "/tmp/better-edit-tools-mcp-chips"
      }
  }
}

///|
fn ensure_cache_dir() -> Unit raise @error.BeError {
  let dir = cache_dir()
  if !@fs.path_exists(dir) {
    ensure_dir_all(dir)
  }
}

///|
fn ensure_dir_all(path : String) -> Unit raise @error.BeError {
  if @fs.path_exists(path) {
    return
  }
  let parts = path.split("/").to_array()
  let mut current = ""
  for i, part in parts {
    let p = part.to_owned()
    if p == "" {
      if i == 0 {
        current = "/"
      }
      continue
    }
    if current == "" {
      current = p
    } else if current == "/" {
      current = "/" + p
    } else {
      current = current + "/" + p
    }
    if !@fs.path_exists(current) {
      @fs.create_dir(current) catch {
        IOError(msg) => raise @error.BeError::WriteError(msg)
      }
    }
  }
}

///|
fn pad_left(s : String, len : Int, char : Char) -> String {
  if s.length() >= len {
    s
  } else {
    String::make(len - s.length(), char) + s
  }
}

///|
fn chip_filename(id : String) -> String {
  chip_counter.val += 1
  let time_seq = pad_left(@env.now().to_string(), 20, '0')
  let count_seq = pad_left(chip_counter.val.to_string(), 10, '0')
  time_seq + "_" + count_seq + "_" + id
}

///|
fn id_from_filename(filename : String) -> String? {
  // filename format: {time_seq}_{count_seq}_{id}
  let first = filename.find("_")
  guard first is Some(first_idx) else { return None }
  let rest = filename.sub(start=first_idx + 1, end=filename.length()).to_owned()
  let second = rest.find("_")
  guard second is Some(second_idx) else { return None }
  Some(rest.sub(start=second_idx + 1, end=rest.length()).to_owned())
}

///|
fn pad_hex(hex : String, len : Int) -> String {
  if hex.length() >= len {
    hex[:len].to_owned()
  } else {
    "0".repeat(len - hex.length()) + hex
  }
}

///|
fn bytes_to_hex(bytes : Array[Byte]) -> String {
  let chars = []
  for b in bytes {
    chars.push(pad_hex(b.to_int().to_string(radix=16), 2))
  }
  chars.join("")
}

///|
let chip_counter : Ref[Int] = { val: 0 }

///|
let rand : Ref[@random.Rand?] = { val: None }

///|
fn make_seed() -> Bytes {
  let time_str = @env.now().to_string()
  let bytes = []
  for i in 0..<32 {
    bytes.push(time_str[i % time_str.length()].to_int().to_byte())
  }
  Bytes::from_array(bytes)
}

///|
fn get_rand() -> @random.Rand {
  match rand.val {
    Some(r) => r
    None => {
      let r = @random.Rand::chacha8(seed=make_seed())
      rand.val = Some(r)
      r
    }
  }
}

///|
fn generate_chip_id() -> String {
  let r = get_rand()
  let bytes = []
  for _ in 0..<4 {
    bytes.push(r.uint(limit=256).to_byte())
  }
  bytes_to_hex(bytes)
}

///|
fn list_filenames() -> Array[String] raise @error.BeError {
  let dir = cache_dir()
  if !@fs.path_exists(dir) {
    return []
  }
  let entries = @fs.read_dir(dir) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let filenames = []
  for entry in entries {
    let path = dir + "/" + entry
    let is_regular = @fs.is_file(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
    if is_regular && entry.contains("_") {
      filenames.push(entry)
    }
  }
  filenames.sort()
  filenames
}

///|
fn evict_oldest_if_needed() -> Unit raise @error.BeError {
  let filenames = list_filenames()
  let dir = cache_dir()
  for i in 0..<(filenames.length() - max_chip_count) {
    let oldest = filenames[i]
    @fs.remove_file(dir + "/" + oldest) catch {
      _ => ()
    }
  }
}

///|
/// 将 content 保存到 chip 缓存，返回分配的 chip id。
/// 当缓存数量超过 30 时，会自动丢弃最早写入的 chip。
pub fn save(content : String) -> String raise @error.BeError {
  ensure_cache_dir()
  let id = generate_chip_id()
  let filename = chip_filename(id)
  let path = cache_dir() + "/" + filename
  @fs.write_string_to_file(path, content) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
  evict_oldest_if_needed()
  id
}

///|
/// 如果 source 以 `chip://` 开头，则读取对应 chip 内容；否则原样返回。
/// 兼容 `chip://{id} 写入失败：...` 这类返回串，只取第一个空格前的 id。
pub fn resolve(source : String) -> String raise @error.BeError {
  guard source.has_prefix("chip://") else { return source }
  let rest = source[7:].to_owned()
  let id = match rest.find(" ") {
    Some(idx) => rest[:idx].to_owned()
    None => rest
  }
  read(id)
}

///|
/// 根据 id 读取 chip 内容，不存在时返回 FileNotFound 错误。
pub fn read(id : String) -> String raise @error.BeError {
  let dir = cache_dir()
  guard @fs.path_exists(dir) else { raise @error.BeError::FileNotFound(id) }
  let entries = @fs.read_dir(dir) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  for entry in entries {
    if entry.has_suffix("_" + id) {
      let path = dir + "/" + entry
      return @fs.read_file_to_string(path) catch {
        IOError(msg) => raise @error.BeError::ReadError(msg)
      }
    }
  }
  raise @error.BeError::FileNotFound(id)
}

///|
/// 返回所有已保存的 chip id，按写入时间从早到晚排列。
pub fn list() -> Array[String] raise @error.BeError {
  let filenames = list_filenames()
  let ids = []
  for filename in filenames {
    match id_from_filename(filename) {
      Some(id) => ids.push(id)
      None => ()
    }
  }
  ids
}

///|
/// 删除指定 chip。
pub fn remove(id : String) -> Unit {
  let dir = cache_dir()
  if !@fs.path_exists(dir) {
    return
  }
  try {
    let entries = @fs.read_dir(dir)
    for entry in entries {
      if entry.has_suffix("_" + id) || entry == "chip-" + id + ".json" {
        let path = dir + "/" + entry
        @fs.remove_file(path) catch {
          _ => ()
        }
      }
    }
  } catch {
    _ => ()
  }
}

///|
/// 清空所有 chip。
pub fn clear() -> Unit raise @error.BeError {
  let dir = cache_dir()
  if !@fs.path_exists(dir) {
    return
  }
  let entries = @fs.read_dir(dir) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  for entry in entries {
    let path = dir + "/" + entry
    let is_regular = @fs.is_file(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
    if is_regular {
      @fs.remove_file(path) catch {
        _ => ()
      }
    }
  }
}

///|
/// chip 记录。
pub(all) struct ChipRecord {
  id : String
  tool : String
  args : Map[String, String]
  err_msg : String
  created_at : Int64
} derive(Debug, ToJson)

///|
/// chip 队列信息。
pub(all) struct ChipQueueInfo {
  count : Int
  capacity : Int
} derive(Debug, ToJson)

///|
fn chip_json_path(id : String) -> String {
  cache_dir() + "/chip-" + id + ".json"
}

///|
fn parse_chip_record(text : String) -> ChipRecord? {
  let json = @json.parse(text) catch { _ => return None }
  guard json is Object(map) else { return None }
  let id = match map.get("id") {
    Some(String(s)) => s
    _ => return None
  }
  let tool = match map.get("tool") {
    Some(String(s)) => s
    _ => return None
  }
  let args = match map.get("args") {
    Some(Object(arg_map)) => {
      let result = Map::default()
      arg_map.each(fn(k, v) {
        match v {
          String(s) => result.set(k, s)
          _ => result.set(k, v.stringify())
        }
      })
      result
    }
    _ => Map::default()
  }
  let err_msg = match map.get("err_msg") {
    Some(String(s)) => s
    _ => ""
  }
  let created_at = match map.get("created_at") {
    Some(Number(n, ..)) => @strconv.from_str(n.to_string()) catch { _ => 0L }
    _ => 0L
  }
  Some({ id, tool, args, err_msg, created_at })
}

///|
/// 保存失败工具调用的完整参数，返回 chip id。
/// 仅在 args 字符串化后长度 > 50 时保存。
pub fn save_chip(
  tool : String,
  args : Map[String, String],
  err_msg : String,
) -> String raise @error.BeError {
  let args_text = args.to_json().stringify()
  if args_text.length() <= 50 {
    return ""
  }
  ensure_cache_dir()
  let id = generate_chip_id()
  let record = {
    id,
    tool,
    args,
    err_msg,
    created_at: @env.now().reinterpret_as_int64(),
  }
  let path = chip_json_path(id)
  @fs.write_string_to_file(path, record.to_json().stringify()) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
  id
}

///|
/// 读取 chip 记录。
pub fn get_chip(id : String) -> ChipRecord raise @error.BeError {
  let path = chip_json_path(id)
  guard @fs.path_exists(path) else { raise @error.BeError::FileNotFound(id) }
  let text = @fs.read_file_to_string(path) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  match parse_chip_record(text) {
    Some(record) => record
    None => raise @error.BeError::InvalidFormat("chip record invalid: " + id)
  }
}

///|
/// 返回 chip 缓存目录，用于测试验证路径策略。
pub fn chip_cache_dir() -> String {
  cache_dir()
}

///|
/// 返回 chip 队列信息。
pub fn chip_queue_info() -> ChipQueueInfo {
  let dir = cache_dir()
  let count = if @fs.path_exists(dir) {
    let entries = @fs.read_dir(dir) catch { _ => [] }
    let mut n = 0
    for entry in entries {
      if entry.has_prefix("chip-") && entry.has_suffix(".json") {
        n += 1
      }
    }
    n
  } else {
    0
  }
  { count, capacity: max_chip_count }
}
