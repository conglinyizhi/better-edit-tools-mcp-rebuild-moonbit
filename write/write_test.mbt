///|
test "be_write 写入 /tmp 下绝对路径文件并把字面 \\n 转为换行" {
  let tmp_file = "/tmp/be-write-test-absolute.txt"
  let input = "第一行\\n第二行\\n第三行"
  let _ = @write.be_write(tmp_file, input)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\n第二行\n第三行")
  @fs.remove_file(tmp_file)
}

///|
test "be_write 错误路径时保存内容到 chip 并返回 chip://id" {
  let bad_path = "/tmp/be-write-nonexistent-dir/file.txt"
  let content = "临时保存的内容"
  let result = @write.be_write(bad_path, content)
  guard result.has_prefix("chip://") else { fail("expected chip:// id") }
  let chip_id = match result.find(" ") {
    Some(idx) => result[7:idx].to_owned()
    None => result[7:].to_owned()
  }
  let saved = @chip.read(chip_id)
  inspect(saved, content="临时保存的内容")
  @chip.remove(chip_id)
}

///|
test "be_write 支持使用 chip://id 作为参数写入文件" {
  let bad_path = "/tmp/be-write-nonexistent-dir-2/file.txt"
  let content = "来自 chip 的内容"
  let chip_ref = @write.be_write(bad_path, content)
  guard chip_ref.has_prefix("chip://") else { fail("expected chip:// id") }
  let target = "/tmp/be-write-from-chip.txt"
  let _ = @write.be_write(target, chip_ref)
  let text = @fs.read_file_to_string(target)
  inspect(text, content="来自 chip 的内容")
  @fs.remove_file(target)
  let chip_id = match chip_ref.find(" ") {
    Some(idx) => chip_ref[7:idx].to_owned()
    None => chip_ref[7:].to_owned()
  }
  @chip.remove(chip_id)
}

///|
test "be_write 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @write.be_write("chip://some-id", "content")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}
