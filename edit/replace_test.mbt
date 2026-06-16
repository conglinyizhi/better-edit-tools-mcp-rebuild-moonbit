///|
test "be_replace 成功替换指定行范围" {
  let tmp_file = "/tmp/be-replace-test-success.txt"
  let original = "第一行\n第二行\n第三行\n第四行\n第五行"
  @fs.write_string_to_file(tmp_file, original)
  @edit.be_replace(tmp_file, 2, 4, "NEW2\\nNEW3")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\nNEW2\nNEW3\n第五行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验通过的 viewed_code_id" {
  let tmp_file = "/tmp/be-replace-test-id.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  let id = @common.compute_viewed_code_id(
    tmp_file, 2, 3, "第二行\n第三行",
  )
  @edit.be_replace(tmp_file, 2, 3, "X", viewed_code_id=id)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\nX\n第四行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验通过的 old 和 old_text" {
  let tmp_file = "/tmp/be-replace-test-old.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  @edit.be_replace(tmp_file, 2, 3, "X\\nY", old="第二行\n第三行")
  let text1 = @fs.read_file_to_string(tmp_file)
  inspect(text1, content="第一行\nX\nY\n第四行")
  @fs.write_string_to_file(tmp_file, original)
  @edit.be_replace(tmp_file, 2, 3, "A\\nB", old_text="第二行\n第三行")
  let text2 = @fs.read_file_to_string(tmp_file)
  inspect(text2, content="第一行\nA\nB\n第四行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验失败的 viewed_code_id" {
  let tmp_file = "/tmp/be-replace-test-id-fail.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  try @edit.be_replace(tmp_file, 2, 3, "X", viewed_code_id="wrong-id") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验失败的 old" {
  let tmp_file = "/tmp/be-replace-test-old-fail.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  try @edit.be_replace(tmp_file, 2, 3, "X", old="wrong-old") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 行范围越界" {
  let tmp_file = "/tmp/be-replace-test-range.txt"
  let original = "第一行\n第二行\n第三行"
  @fs.write_string_to_file(tmp_file, original)
  try @edit.be_replace(tmp_file, 0, 2, "X") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  try @edit.be_replace(tmp_file, 2, 5, "X") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 文件不存在" {
  let tmp_file = "/tmp/be-replace-test-missing.txt"
  @fs.remove_file(tmp_file) catch {
    _ => ()
  }
  try @edit.be_replace(tmp_file, 1, 1, "X") catch {
    FileNotFound(_) => ()
    _ => fail("expected FileNotFound")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "be_replace 支持 chip://id 作为 content" {
  @chip.clear()
  let tmp_file = "/tmp/be-replace-test-chip-content.txt"
  @fs.write_string_to_file(tmp_file, "第一行\n第二行\n第三行")
  let chip_id = @chip.save("来自 chip 的内容")
  @edit.be_replace(tmp_file, 2, 2, "chip://" + chip_id)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\n来自 chip 的内容\n第三行")
  @fs.remove_file(tmp_file)
  @chip.remove(chip_id)
}

///|
test "be_replace 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @edit.be_replace("chip://some-id", 1, 1, "X")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}
