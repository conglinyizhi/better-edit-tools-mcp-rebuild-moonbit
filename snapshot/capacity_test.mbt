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

///|
test "snapshot 队列满时返回警告且写入成功" {
  @testutil.with_temp_file(base_name="queue-full", tmp => {
    let _ = @snapshot.commit_snapshots()
    let mut warning_count = 0
    for i = 0; i < 31; i = i + 1 {
      @fs.write_string_to_file(tmp, "v" + i.to_string())
      let (_, warning) = @snapshot.push_snapshot(tmp, "v" + i.to_string())
      if warning.length() > 0 {
        warning_count += 1
        assert_true(warning.contains("snapshot queue"))
        assert_true(warning.contains("written successfully"))
      }
    }
    assert_eq(warning_count, 1)
    assert_eq(@snapshot.snapshot_queue_stats().used, 30)
    let _ = @snapshot.commit_snapshots()
  })
}

///|
test "snapshot stats respect count and byte capacity" {
  @testutil.with_temp_file(base_name="snap-cap", tmp => {
    let _ = @snapshot.commit_snapshots()
    for i = 0; i < 35; i = i + 1 {
      @fs.write_string_to_file(tmp, "v" + i.to_string())
      let _ = @snapshot.push_snapshot(tmp, "v" + i.to_string())
    }
    let stats = @snapshot.snapshot_queue_stats()
    assert_true(stats.used <= 30)
    assert_true(stats.disk_bytes <= 104857600L)
    let _ = @snapshot.commit_snapshots()
  })
}

///|
test "snapshot commit clears queue and disk" {
  @testutil.with_temp_file(base_name="snap-commit", tmp => {
    let _ = @snapshot.commit_snapshots()
    @fs.write_string_to_file(tmp, "v0")
    let _ = @snapshot.push_snapshot(tmp, "v0")
    assert_eq(@snapshot.snapshot_queue_stats().used, 1)
    let cleared = @snapshot.commit_snapshots()
    assert_eq(cleared, 1)
    assert_eq(@snapshot.snapshot_queue_stats().used, 0)
    assert_eq(@snapshot.list_snapshots().length(), 0)
  })
}
