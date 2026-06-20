///|
test "be_replace 成功替换指定行范围" {
  let tmp_file = "/tmp/be-replace-test-success.txt"
  let original = "第一行\n第二行\n第三行\n第四行\n第五行"
  @fs.write_string_to_file(tmp_file, original)
  let _ = @edit.be_replace(tmp_file, 2, 4, "NEW2\\nNEW3")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\nNEW2\nNEW3\n第五行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验通过的 viewed_code_id" {
  let tmp_file = "/tmp/be-replace-test-id.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  let id = @session.create_session(tmp_file, 2, 3)
  let _ = @edit.be_replace(tmp_file, 2, 3, "X", viewed_code_id=id)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\nX\n第四行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验通过的 old 和 old_text" {
  let tmp_file = "/tmp/be-replace-test-old.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  let _ = @edit.be_replace(tmp_file, 2, 3, "X\\nY", old="第二行\n第三行")
  let text1 = @fs.read_file_to_string(tmp_file)
  inspect(text1, content="第一行\nX\nY\n第四行")
  @fs.write_string_to_file(tmp_file, original)
  let _ = @edit.be_replace(
    tmp_file,
    2,
    3,
    "A\\nB",
    old_text="第二行\n第三行",
  )
  let text2 = @fs.read_file_to_string(tmp_file)
  inspect(text2, content="第一行\nA\nB\n第四行")
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 读取同范围两次得到不同 viewed_code_id" {
  let tmp_file = "/tmp/be-replace-uuid-twice.txt"
  @fs.write_string_to_file(tmp_file, "a\nb\nc")
  let id1 = @session.create_session(tmp_file, 1, 2)
  let id2 = @session.create_session(tmp_file, 1, 2)
  assert_true(id1 != id2)
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 文件行数变化后返回非致命警告" {
  let tmp_file = "/tmp/be-replace-line-count-warning.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  let id = @session.create_session(tmp_file, 2, 3)
  @fs.write_string_to_file(tmp_file, "第一行\n第二行\n第三行")
  let result = @edit.be_replace(tmp_file, 2, 2, "X", viewed_code_id=id)
  assert_true(result.warnings.length() > 0)
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 校验失败的 old" {
  let tmp_file = "/tmp/be-replace-test-old-fail.txt"
  let original = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, original)
  let _ = try @edit.be_replace(tmp_file, 2, 3, "X", old="wrong-old") catch {
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
  let _ = try @edit.be_replace(tmp_file, 0, 2, "X") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  let _ = try @edit.be_replace(tmp_file, 2, 5, "X") catch {
    InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error")
  }
  @fs.remove_file(tmp_file)
}

///|
test "be_replace 文件不存在" {
  let tmp_file = "/tmp/be-replace-missing.txt"
  @fs.remove_file(tmp_file) catch {
    _ => ()
  }
  let _ = try @edit.be_replace(tmp_file, 1, 1, "X") catch {
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
  let _ = @edit.be_replace(tmp_file, 2, 2, "chip://" + chip_id)
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

///|
test "be_replace 替换第一行" {
  @testutil.with_temp_file(base_name="replace-first", tmp => {
    @fs.write_string_to_file(tmp, "old_first\nsecond\nthird")
    let _ = @edit.be_replace(tmp, 1, 1, "new_first")
    assert_eq(@fs.read_file_to_string(tmp), "new_first\nsecond\nthird")
  })
}

///|
test "be_replace 替换最后一行" {
  @testutil.with_temp_file(base_name="replace-last", tmp => {
    @fs.write_string_to_file(tmp, "first\nsecond\nold_last")
    let _ = @edit.be_replace(tmp, 3, 3, "new_last")
    assert_eq(@fs.read_file_to_string(tmp), "first\nsecond\nnew_last")
  })
}

///|
test "be_replace 闭区间替换多行" {
  @testutil.with_temp_file(base_name="replace-range", tmp => {
    @fs.write_string_to_file(tmp, "a\nb\nc\nd\ne")
    let _ = @edit.be_replace(tmp, 2, 4, "x\ny")
    assert_eq(@fs.read_file_to_string(tmp), "a\nx\ny\ne")
  })
}

///|
test "be_replace 拒绝 old 缺少末尾空行" {
  @testutil.with_temp_file(base_name="replace-missing-empty", tmp => {
    @fs.write_string_to_file(tmp, "a\nb\n\nc")
    try {
      let _ = @edit.be_replace(tmp, 2, 3, "x", old="b")
      fail("expected error")
    } catch {
      @error.BeError::InvalidFormat(_) => ()
      _ => fail("expected InvalidFormat")
    }
    assert_eq(@fs.read_file_to_string(tmp), "a\nb\n\nc")
  })
}

///|
test "be_replace 拒绝 old 多余末尾空行" {
  @testutil.with_temp_file(base_name="replace-extra-empty", tmp => {
    @fs.write_string_to_file(tmp, "a\nb\nc")
    try {
      let _ = @edit.be_replace(tmp, 2, 2, "x", old="b\n")
      fail("expected error")
    } catch {
      @error.BeError::InvalidFormat(_) => ()
      _ => fail("expected InvalidFormat")
    }
    assert_eq(@fs.read_file_to_string(tmp), "a\nb\nc")
  })
}

///|
test "be_replace 多行 tab 缩进保留" {
  @testutil.with_temp_file(base_name="replace-tab", tmp => {
    let content = "func foo() {\n\tif true {\n\t\tdoSomething()\n\t}\n}"
    @fs.write_string_to_file(tmp, content)
    let old = "\tif true {\n\t\tdoSomething()\n\t}"
    let new_content = "\tif false {\n\t\tdoNothing()\n\t}"
    let _ = @edit.be_replace(tmp, 2, 4, new_content, old~)
    let expected = "func foo() {\n\tif false {\n\t\tdoNothing()\n\t}\n}"
    assert_eq(@fs.read_file_to_string(tmp), expected)
  })
}
