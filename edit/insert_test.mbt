///|
test "be_insert 在文件开头插入内容" {
  let tmp = "/tmp/be-insert-begin.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  @edit.be_insert(tmp, "新行", line=0)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="新行\n第一行\n第二行\n第三行")
  @fs.remove_file(tmp)
}

///|
test "be_insert 在指定行后插入并把字面 \\n 转为换行" {
  let tmp = "/tmp/be-insert-middle.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  @edit.be_insert(tmp, "插入1\\n插入2", line=2)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n第二行\n插入1\n插入2\n第三行")
  @fs.remove_file(tmp)
}

///|
test "be_insert 的 after_line 别名与 line 等价" {
  let tmp = "/tmp/be-insert-alias.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  @edit.be_insert(tmp, "新行", after_line=2)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n第二行\n新行\n第三行")
  @fs.remove_file(tmp)
}

///|
test "be_insert line 与 after_line 冲突时报 InvalidFormat" {
  let tmp = "/tmp/be-insert-conflict.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行")
  try @edit.be_insert(tmp, "新行", line=1, after_line=2) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("期望 InvalidFormat 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
  @fs.remove_file(tmp)
}

///|
test "be_insert 行号越界时报 InvalidFormat" {
  let tmp = "/tmp/be-insert-out-of-range.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行")
  try @edit.be_insert(tmp, "新行", line=10) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("期望 InvalidFormat 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
  try @edit.be_insert(tmp, "新行", line=-1) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("期望 InvalidFormat 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
  @fs.remove_file(tmp)
}

///|
test "be_insert 文件不存在时报 FileNotFound" {
  let tmp = "/tmp/be-insert-missing.txt"
  try @edit.be_insert(tmp, "新行", line=1) catch {
    @error.BeError::FileNotFound(path) => inspect(path, content=tmp)
    _ => fail("期望 FileNotFound 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
}

///|
test "be_insert 支持 chip://id 作为 content" {
  @chip.clear()
  let tmp = "/tmp/be-insert-chip-content.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行")
  let chip_id = @chip.save("来自 chip 的内容")
  @edit.be_insert(tmp, "chip://" + chip_id, line=1)
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="第一行\n来自 chip 的内容\n第二行")
  @fs.remove_file(tmp)
  @chip.remove(chip_id)
}

///|
test "be_insert 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @edit.be_insert("chip://some-id", "content", line=1)
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}
