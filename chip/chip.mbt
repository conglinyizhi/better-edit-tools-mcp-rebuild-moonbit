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
fn chip_path(id : String) -> String {
  cache_dir() + "/" + id
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
let rand : Ref[@random.Rand?] = { val: None }

///|
fn get_rand() -> @random.Rand {
  match rand.val {
    Some(r) => r
    None => {
      let r = @random.Rand::chacha8()
      rand.val = Some(r)
      r
    }
  }
}

///|
fn generate_chip_id() -> String {
  let r = get_rand()
  let bytes = []
  for _ in 0..<3 {
    bytes.push(r.uint(limit=256).to_byte())
  }
  bytes_to_hex(bytes)
}

///|
/// 将 content 保存到 chip 缓存，返回分配的 chip id。
pub fn save(content : String) -> String raise @error.BeError {
  ensure_cache_dir()
  let id = generate_chip_id()
  let path = chip_path(id)
  @fs.write_string_to_file(path, content) catch {
    IOError(msg) => raise @error.BeError::WriteError(msg)
  }
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
  let path = chip_path(id)
  guard @fs.path_exists(path) else { raise @error.BeError::FileNotFound(path) }
  @fs.read_file_to_string(path) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
}

///|
/// 返回所有已保存的 chip id，按字典序排列。
pub fn list() -> Array[String] raise @error.BeError {
  let dir = cache_dir()
  if !@fs.path_exists(dir) {
    return []
  }
  let entries = @fs.read_dir(dir) catch {
    IOError(msg) => raise @error.BeError::ReadError(msg)
  }
  let ids = []
  for entry in entries {
    let path = dir + "/" + entry
    let is_regular = @fs.is_file(path) catch {
      IOError(msg) => raise @error.BeError::ReadError(msg)
    }
    if is_regular {
      ids.push(entry)
    }
  }
  ids.sort()
  ids
}

///|
/// 删除指定 chip。
pub fn remove(id : String) -> Unit {
  let path = chip_path(id)
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
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
        IOError(msg) => raise @error.BeError::WriteError(msg)
      }
    }
  }
}
