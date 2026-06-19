///|
test "write_file_atomic 单文件原子写入" {
  let tmp_file = "/tmp/be-atomic-single.txt"
  let _ = @write.write_file_atomic(tmp_file, "原子写入内容")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="原子写入内容")
  // 不应残留临时文件
  let dir = "/tmp"
  let entries = @fs.read_dir(dir) catch { IOError(_) => [] }
  for entry in entries {
    guard !entry.contains("be-atomic-single.txt.tmp.") else {
      fail("残留临时文件：\{entry}")
    }
  }
  @fs.remove_file(tmp_file) catch {
    _ => ()
  }
}

///|
test "write_file_atomic 覆盖已有文件" {
  let tmp_file = "/tmp/be-atomic-overwrite.txt"
  @fs.write_string_to_file(tmp_file, "原始内容")
  let _ = @write.write_file_atomic(tmp_file, "覆盖后内容")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="覆盖后内容")
  @fs.remove_file(tmp_file) catch {
    _ => ()
  }
}

///|
test "write_files_atomic 多文件写入成功" {
  let a = "/tmp/be-atomic-multi-a.txt"
  let b = "/tmp/be-atomic-multi-b.txt"
  @fs.write_string_to_file(a, "a-old")
  @fs.write_string_to_file(b, "b-old")
  let _ = @write.write_files_atomic([(a, "a-new"), (b, "b-new")])
  inspect(@fs.read_file_to_string(a), content="a-new")
  inspect(@fs.read_file_to_string(b), content="b-new")
  @fs.remove_file(a) catch {
    _ => ()
  }
  @fs.remove_file(b) catch {
    _ => ()
  }
}

///|
test "write_files_atomic 中途失败回滚已提交文件" {
  let a = "/tmp/be-atomic-rollback-a.txt"
  let b = "/tmp/be-atomic-rollback-nonexistent-dir/file.txt"
  @fs.write_string_to_file(a, "a-original")
  try {
    let _ = @write.write_files_atomic([(a, "a-new"), (b, "b-new")])
    fail("expected WriteError")
  } catch {
    @error.BeError::WriteError(_) => ()
    _ => fail("expected WriteError")
  }
  inspect(@fs.read_file_to_string(a), content="a-original")
  @fs.remove_file(a) catch {
    _ => ()
  }
}
