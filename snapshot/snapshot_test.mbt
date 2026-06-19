///|
test "push_snapshot 返回 id 与空 warning" {
  let tmp = "/tmp/snapshot-push-test.txt"
  @fs.write_string_to_file(tmp, "hello")
  let (id, warning) = @snapshot.push_snapshot(tmp, "hello")
  assert_true(id.length() > 0)
  assert_eq(warning, "")
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}

///|
test "连续编辑三次后 status 显示 used=3" {
  let tmp = "/tmp/snapshot-status-test.txt"
  let _ = @snapshot.commit_snapshots()
  @fs.write_string_to_file(tmp, "v0")
  let _ = @snapshot.push_snapshot(tmp, "v0")
  let _ = @snapshot.push_snapshot(tmp, "v1")
  let _ = @snapshot.push_snapshot(tmp, "v2")
  let stats = @snapshot.snapshot_queue_stats()
  assert_eq(stats.used, 3)
  assert_eq(stats.capacity, 30)
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}

///|
test "rollback step=1 恢复到最后一次编辑前" {
  let tmp = "/tmp/snapshot-rollback-test.txt"
  let _ = @snapshot.commit_snapshots()
  @fs.write_string_to_file(tmp, "v0")
  let _ = @snapshot.push_snapshot(tmp, "v0")
  @fs.write_string_to_file(tmp, "v1")
  let _ = @snapshot.push_snapshot(tmp, "v1")
  @fs.write_string_to_file(tmp, "v2")
  let (restored, errors) = @snapshot.rollback_snapshots(1)
  assert_eq(restored, 1)
  assert_eq(errors.length(), 0)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="v1")
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}

///|
test "commit 清空队列" {
  let tmp = "/tmp/snapshot-commit-test.txt"
  let _ = @snapshot.commit_snapshots()
  @fs.write_string_to_file(tmp, "content")
  let _ = @snapshot.push_snapshot(tmp, "content")
  let _ = @snapshot.push_snapshot(tmp, "content2")
  assert_eq(@snapshot.snapshot_queue_stats().used, 2)
  let count = @snapshot.commit_snapshots()
  assert_eq(count, 2)
  assert_eq(@snapshot.snapshot_queue_stats().used, 0)
  @fs.remove_file(tmp)
}

///|
test "list_snapshots 返回队列内容" {
  let tmp = "/tmp/snapshot-list-test.txt"
  let _ = @snapshot.commit_snapshots()
  @fs.write_string_to_file(tmp, "a")
  let _ = @snapshot.push_snapshot(tmp, "a")
  let _ = @snapshot.push_snapshot(tmp, "b")
  let list = @snapshot.list_snapshots()
  assert_eq(list.length(), 2)
  let _ = @snapshot.commit_snapshots()
  @fs.remove_file(tmp)
}
