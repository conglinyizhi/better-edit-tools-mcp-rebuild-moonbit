///|
test "snapshot 队列容量限制为 30" {
  let _ = @snapshot.commit_snapshots()
  let tmp = "/tmp/snapshot-capacity.txt"
  for i = 0; i < 35; i = i + 1 {
    @fs.write_string_to_file(tmp, "v" + i.to_string())
    let _ = @snapshot.push_snapshot(tmp, "v" + i.to_string())
  }
  let stats = @snapshot.snapshot_queue_stats()
  assert_eq(stats.used, 30)
  assert_eq(stats.capacity, 30)
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}

///|
test "snapshot 持久化后能从磁盘恢复" {
  let _ = @snapshot.commit_snapshots()
  let tmp = "/tmp/snapshot-persist.txt"
  @fs.write_string_to_file(tmp, "v0")
  let (id, _) = @snapshot.push_snapshot(tmp, "v0")
  assert_true(id.length() > 0)
  let list = @snapshot.list_snapshots()
  assert_eq(list.length(), 1)
  assert_eq(list[0].file, tmp)
  assert_eq(list[0].content, "v0")
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}

///|
test "snapshot rollback 多步恢复" {
  let _ = @snapshot.commit_snapshots()
  let tmp = "/tmp/snapshot-multi-rollback.txt"
  @fs.write_string_to_file(tmp, "v0")
  let _ = @snapshot.push_snapshot(tmp, "v0")
  @fs.write_string_to_file(tmp, "v1")
  let _ = @snapshot.push_snapshot(tmp, "v0")
  @fs.write_string_to_file(tmp, "v2")
  let _ = @snapshot.push_snapshot(tmp, "v1")
  let (restored, errors) = @snapshot.rollback_snapshots(2)
  assert_eq(restored, 2)
  assert_eq(errors.length(), 0)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="v0")
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}
