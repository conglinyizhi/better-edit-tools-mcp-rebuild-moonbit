///|
test "save_chip 记录跨读取保持一致" {
  @chip.clear()
  let args = { "file": "/tmp/chip-persist.txt", "content": "x".repeat(60) }
  let id = @chip.save_chip("be-write", args, "persist test")
  assert_true(id.length() > 0)
  let record = @chip.get_chip(id)
  assert_eq(record.tool, "be-write")
  assert_eq(record.err_msg, "persist test")
  assert_true(record.args.get("file") is Some("/tmp/chip-persist.txt"))
  @chip.remove(id)
}

///|
test "chip_queue_info 统计仅含 JSON 记录" {
  @chip.clear()
  let args = { "content": "x".repeat(60) }
  let _ = @chip.save_chip("be-write", args, "err")
  let info = @chip.chip_queue_info()
  assert_eq(info.capacity, 30)
  assert_true(info.count >= 1)
  @chip.clear()
}
