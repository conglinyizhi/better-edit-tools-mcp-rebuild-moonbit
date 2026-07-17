///|
/// 快照记录。
pub(all) struct SnapshotRecord {
  id : String
  file : String
  content : String
  created_at : Int64
} derive(Debug, ToJson)

///|
pub extend SnapshotRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SnapshotRecord with ToJson::{to_json}

///|
/// 快照队列统计。
pub(all) struct QueueStats {
  used : Int
  capacity : Int
  disk_bytes : Int64
} derive(Debug, ToJson)

///|
pub extend QueueStats with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend QueueStats with ToJson::{to_json}

///|
let max_count : Int = 30

///|
let max_bytes : Int64 = 104857600L // 100MB

///|
let snapshot_rand : Ref[@random.Rand?] = { val: None }

///|
let snapshot_counter : Ref[Int] = { val: 0 }

///|
let snapshot_queue : Ref[Array[SnapshotRecord]] = { val: [] }

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
  match snapshot_rand.val {
    Some(r) => r
    None => {
      let r = @random.Rand::chacha8(seed=make_seed())
      snapshot_rand.val = Some(r)
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
fn generate_id() -> String {
  snapshot_counter.val += 1
  let r = get_rand()
  let bytes = []
  for _ in 0..<4 {
    bytes.push(r.uint(limit=256).to_byte())
  }
  let hex = bytes_to_hex(bytes)
  "\{@env.now()}_\{snapshot_counter.val}_\{hex}"
}

///|
fn snapshot_dir() -> String {
  match @env.get_env_var("LOCALAPPDATA") {
    Some(dir) => dir + "/better-edit-tools-mcp/snapshots/default"
    None =>
      match @env.get_env_var("HOME") {
        Some(home) =>
          match @env.get_env_var("XDG_CACHE_HOME") {
            Some(xdg) => xdg + "/better-edit-tools-mcp/snapshots/default"
            None => home + "/.cache/better-edit-tools-mcp/snapshots/default"
          }
        None => "/tmp/better-edit-tools-mcp-snapshots-default"
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
fn ensure_snapshot_dir() -> Unit raise @error.BeError {
  ensure_dir_all(snapshot_dir())
}

///|
fn snapshot_path(id : String) -> String {
  snapshot_dir() + "/snapshot-" + id + ".json"
}

///|
fn remove_snapshot_file(id : String) -> Unit {
  let path = snapshot_path(id)
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn parse_snapshot(text : String) -> SnapshotRecord? {
  let json = @json.parse(text) catch { _ => return None }
  guard json is Object(map) else { return None }
  let id = match map.get("id") {
    Some(String(s)) => s
    _ => return None
  }
  let file = match map.get("file") {
    Some(String(s)) => s
    _ => return None
  }
  let content = match map.get("content") {
    Some(String(s)) => s
    _ => return None
  }
  let created_at = match map.get("created_at") {
    Some(Number(n, ..)) =>
      @strconv.from_str(n.to_string()) catch {
        _ => return None
      }
    _ => return None
  }
  Some({ id, file, content, created_at })
}

///|
fn load_queue_from_disk() -> Array[SnapshotRecord] {
  let dir = snapshot_dir()
  if !@fs.path_exists(dir) {
    return []
  }
  let entries = @fs.read_dir(dir) catch { _ => return [] }
  let records = []
  for entry in entries {
    if !entry.has_prefix("snapshot-") || !entry.has_suffix(".json") {
      continue
    }
    let text = @fs.read_file_to_string(dir + "/" + entry) catch {
      _ => continue
    }
    match parse_snapshot(text) {
      Some(r) => records.push(r)
      None => ()
    }
  }
  records.sort_by(fn(a, b) {
    if a.created_at < b.created_at {
      -1
    } else if a.created_at > b.created_at {
      1
    } else {
      0
    }
  })
  records
}

///|
fn get_queue() -> Array[SnapshotRecord] {
  if snapshot_queue.val.length() == 0 {
    snapshot_queue.val = load_queue_from_disk()
  }
  snapshot_queue.val
}

///|
fn total_content_bytes(records : Array[SnapshotRecord]) -> Int64 {
  let mut total : Int64 = 0L
  for r in records {
    total = total + r.content.length().to_int64()
  }
  total
}

///|
fn evict_oldest_if_needed(queue : Array[SnapshotRecord]) -> Bool {
  let mut evicted = false
  // 超出数量限制
  while queue.length() > max_count {
    let oldest = queue.remove(0)
    remove_snapshot_file(oldest.id)
    evicted = true
  }
  // 超出磁盘限制（以 content 长度近似）
  while total_content_bytes(queue) > max_bytes && queue.length() > 0 {
    let oldest = queue.remove(0)
    remove_snapshot_file(oldest.id)
    evicted = true
  }
  evicted
}

///|
/// 将修改前完整文件内容加入快照队列，返回 (snapshot_id, warning)。
pub fn push_snapshot(file : String, content : String) -> (String, String) {
  let id = generate_id()
  let created_at = @env.now().reinterpret_as_int64()
  let record = { id, file, content, created_at }
  let write_ok = try {
    ensure_snapshot_dir()
    @fs.write_string_to_file(snapshot_path(id), record.to_json().stringify())
    true
  } catch {
    _ => false
  }
  if !write_ok {
    return ("", "failed to persist snapshot")
  }
  let queue = get_queue()
  queue.push(record)
  let evicted = evict_oldest_if_needed(queue)
  let warning = if evicted {
    "snapshot queue is full; oldest snapshot was evicted, but current edit was written successfully"
  } else {
    ""
  }
  (id, warning)
}

///|
/// 提交（清空）快照队列，返回被清空的记录数。
pub fn commit_snapshots() -> Int {
  let queue = get_queue()
  let count = queue.length()
  for record in queue {
    remove_snapshot_file(record.id)
  }
  queue.clear()
  count
}

///|
/// 按 step 数量回滚最近的快照，返回 (回滚文件数, 错误列表)。
pub fn rollback_snapshots(step : Int) -> (Int, Array[@error.BeError]) {
  let queue = get_queue()
  let steps = if step > queue.length() { queue.length() } else { step }
  let errors : Array[@error.BeError] = []
  let mut restored = 0
  for _ in 0..<steps {
    let record = queue.remove(queue.length() - 1)
    try {
      @fs.write_string_to_file(record.file, record.content)
      restored += 1
    } catch {
      IOError(msg) => errors.push(@error.BeError::WriteError(msg))
    }
    remove_snapshot_file(record.id)
  }
  (restored, errors)
}

///|
/// 列出当前队列中的所有快照，最新快照在前。
pub fn list_snapshots() -> Array[SnapshotRecord] {
  let queue = get_queue().copy()
  queue.sort_by(fn(a, b) {
    if a.created_at > b.created_at {
      -1
    } else if a.created_at < b.created_at {
      1
    } else {
      0
    }
  })
  queue
}

///|
/// 返回队列统计信息。
pub fn snapshot_queue_stats() -> QueueStats {
  let queue = get_queue()
  {
    used: queue.length(),
    capacity: max_count,
    disk_bytes: total_content_bytes(queue),
  }
}
