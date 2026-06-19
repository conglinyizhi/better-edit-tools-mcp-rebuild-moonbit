///|
/// 读取会话记录。
pub(all) struct ReadSession {
  path : String
  start_line : Int
  end_line : Int
  line_count : Int
  created_at : Int64
} derive(Debug, ToJson)

///|
let session_rand : Ref[@random.Rand?] = { val: None }

///|
let session_counter : Ref[Int] = { val: 0 }

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
  match session_rand.val {
    Some(r) => r
    None => {
      let r = @random.Rand::chacha8(seed=make_seed())
      session_rand.val = Some(r)
      r
    }
  }
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
fn generate_uuid() -> String {
  session_counter.val += 1
  let r = get_rand()
  let bytes = []
  for _ in 0..<16 {
    bytes.push(r.uint(limit=256).to_byte())
  }
  let hex = bytes_to_hex(bytes)
  // 8-4-4-4-12
  hex.sub(start=0, end=8).to_owned() +
  "-" +
  hex.sub(start=8, end=12).to_owned() +
  "-" +
  hex.sub(start=12, end=16).to_owned() +
  "-" +
  hex.sub(start=16, end=20).to_owned() +
  "-" +
  hex.sub(start=20, end=hex.length()).to_owned()
}

///|
fn session_dir() -> String {
  match @env.get_env_var("LOCALAPPDATA") {
    Some(dir) => dir + "/better-edit-tools-mcp/sessions/default"
    None =>
      match @env.get_env_var("HOME") {
        Some(home) =>
          match @env.get_env_var("XDG_CACHE_HOME") {
            Some(xdg) => xdg + "/better-edit-tools-mcp/sessions/default"
            None => home + "/.cache/better-edit-tools-mcp/sessions/default"
          }
        None => "/tmp/better-edit-tools-mcp-sessions-default"
      }
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
fn ensure_session_dir() -> Unit raise @error.BeError {
  ensure_dir_all(session_dir())
}

///|
fn current_line_count(path : String) -> Int {
  if !@fs.path_exists(path) {
    return 0
  }
  let text = @fs.read_file_to_string(path) catch { _ => return 0 }
  if text.is_empty() {
    return 0
  }
  text.split("\n").to_array().length()
}

///|
fn parse_session(text : String) -> ReadSession? {
  let json = @json.parse(text) catch { _ => return None }
  guard json is Object(map) else { return None }
  let path = match map.get("path") {
    Some(String(s)) => s
    _ => return None
  }
  let start_line = match map.get("start_line") {
    Some(Number(n, ..)) =>
      @strconv.from_str(n.to_string()) catch {
        _ => return None
      }
    _ => return None
  }
  let end_line = match map.get("end_line") {
    Some(Number(n, ..)) =>
      @strconv.from_str(n.to_string()) catch {
        _ => return None
      }
    _ => return None
  }
  let line_count = match map.get("line_count") {
    Some(Number(n, ..)) =>
      @strconv.from_str(n.to_string()) catch {
        _ => return None
      }
    _ => return None
  }
  let created_at = match map.get("created_at") {
    Some(Number(n, ..)) => @strconv.from_str(n.to_string()) catch { _ => 0L }
    _ => 0L
  }
  Some({ path, start_line, end_line, line_count, created_at })
}

///|
/// 创建会话并返回 UUID 形式的 viewed_code_id。
pub fn create_session(
  path : String,
  start_line : Int,
  end_line : Int,
) -> String {
  cleanup_expired_sessions()
  let id = generate_uuid()
  let line_count = current_line_count(path)
  let created_at = @env.now().reinterpret_as_int64()
  let session = { path, start_line, end_line, line_count, created_at }
  let text = session.to_json().stringify()
  try {
    ensure_session_dir()
    @fs.write_string_to_file(session_dir() + "/" + id + ".json", text)
  } catch {
    _ => ()
  }
  id
}

///|
/// 根据 viewed_code_id 从缓存中查找会话。
/// 返回 (session, warning)，其中 warning 在文件行数变化时非空。
pub fn session_from_cache(id : String) -> (ReadSession?, String) {
  let path = session_dir() + "/" + id + ".json"
  if !@fs.path_exists(path) {
    return (None, "")
  }
  let text = @fs.read_file_to_string(path) catch { _ => return (None, "") }
  let session = match parse_session(text) {
    Some(s) => s
    None => return (None, "")
  }
  let current = current_line_count(session.path)
  let warning = if current != session.line_count {
    @common.t("warning.line_count_changed")
  } else {
    ""
  }
  (Some(session), warning)
}

///|
/// 清理超过 24 小时的过期会话。
pub fn cleanup_expired_sessions() -> Unit {
  let dir = session_dir()
  if !@fs.path_exists(dir) {
    return
  }
  let entries = @fs.read_dir(dir) catch { _ => return }
  let now = @env.now().reinterpret_as_int64()
  let ttl_ms : Int64 = 24L * 60L * 60L * 1000L
  for entry in entries {
    let path = dir + "/" + entry
    let is_regular = @fs.is_file(path) catch { _ => false }
    if !is_regular {
      continue
    }
    let text = @fs.read_file_to_string(path) catch { _ => continue }
    let session = parse_session(text)
    let expired = match session {
      Some(s) => now - s.created_at > ttl_ms
      None => true
    }
    if expired {
      @fs.remove_file(path) catch {
        _ => ()
      }
    }
  }
}
