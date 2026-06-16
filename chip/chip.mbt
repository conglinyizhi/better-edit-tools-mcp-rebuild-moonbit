///|
let store : Ref[Map[String, String]] = { val: {} }

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
/// 将 content 保存到内存中的 chip 缓存，返回分配的 chip id。
pub fn save(content : String) -> String {
  let id = generate_chip_id()
  store.val[id] = content
  id
}

///|
/// 根据 id 读取 chip 内容，不存在时返回 FileNotFound 错误。
pub fn read(id : String) -> String raise @error.BeError {
  match store.val.get(id) {
    Some(content) => content
    None => raise @error.BeError::FileNotFound(id)
  }
}

///|
/// 返回所有已保存的 chip id，按字典序排列。
pub fn list() -> Array[String] {
  let ids = []
  for k, _ in store.val {
    ids.push(k)
  }
  ids.sort()
  ids
}

///|
/// 删除指定 chip。
pub fn remove(id : String) -> Unit {
  store.val.remove(id)
}

///|
/// 清空所有 chip。
pub fn clear() -> Unit {
  store.val = {}
}
