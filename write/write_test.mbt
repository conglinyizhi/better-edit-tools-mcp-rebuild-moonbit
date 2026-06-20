///|
test "be_write JSON 单文件写入 /tmp 下绝对路径文件并把字面 \\n 转为换行" {
  let tmp_file = "/tmp/be-write-test-absolute.txt"
  let input = "{\"file\":\"" +
    tmp_file +
    "\",\"content\":\"第一行\\n第二行\\n第三行\"}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, false)
  inspect(result.files.length(), content="1")
  inspect(result.results.length(), content="1")
  inspect(result.results[0], content="ok")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\n第二行\n第三行")
  @fs.remove_file(tmp_file)
}

///|
test "be_write 多文件 JSON 写入两个文件均成功" {
  let a = "/tmp/be-write-multi-a.txt"
  let b = "/tmp/be-write-multi-b.txt"
  let input = "{\"files\":[{\"file\":\"" +
    a +
    "\",\"content\":\"hello\"},{\"file\":\"" +
    b +
    "\",\"content\":\"world\"}]}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, false)
  inspect(result.files.length(), content="2")
  inspect(result.results.length(), content="2")
  inspect(result.results[0], content="ok")
  inspect(result.results[1], content="ok")
  inspect(@fs.read_file_to_string(a), content="hello")
  inspect(@fs.read_file_to_string(b), content="world")
  @fs.remove_file(a)
  @fs.remove_file(b)
}

///|
test "be_write 错误路径时保存内容到 chip 并返回 chip://id" {
  let bad_path = "/tmp/be-write-nonexistent-dir/file.txt"
  let content = "临时保存的内容"
  let input = "{\"file\":\"" + bad_path + "\",\"content\":\"" + content + "\"}"
  let result = @write.be_write(input)
  inspect(result.files.length(), content="1")
  inspect(result.files[0], content=bad_path)
  let msg = result.results[0]
  guard msg.has_prefix("chip://") else { fail("expected chip:// id") }
  let chip_id = match msg.find(" ") {
    Some(idx) => msg[7:idx].to_owned()
    None => msg[7:].to_owned()
  }
  let saved = @chip.read(chip_id)
  inspect(saved, content="临时保存的内容")
  @chip.remove(chip_id)
}

///|
test "be_write 支持使用 chip://id 作为参数写入文件" {
  let bad_path = "/tmp/be-write-nonexistent-dir-2/file.txt"
  let content = "来自 chip 的内容"
  let input = "{\"file\":\"" + bad_path + "\",\"content\":\"" + content + "\"}"
  let chip_ref_result = @write.be_write(input)
  let chip_ref = chip_ref_result.results[0]
  guard chip_ref.has_prefix("chip://") else { fail("expected chip:// id") }
  let target = "/tmp/be-write-from-chip.txt"
  let target_input = "{\"file\":\"" +
    target +
    "\",\"content\":\"" +
    chip_ref +
    "\"}"
  let _ = @write.be_write(target_input)
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
    let _ = @write.be_write(
      "{\"file\":\"chip://some-id\",\"content\":\"content\"}",
    )
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}

///|
test "be_write 带未转义换行的 JSON 降级解析写入" {
  let tmp_file = "/tmp/be-write-degraded.txt"
  let input = "{\"file\":\"" +
    tmp_file +
    "\",\"content\":\"line1\nline2\nline3\"}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, true)
  inspect(result.files.length(), content="1")
  inspect(result.files[0], content=tmp_file)
  inspect(result.results[0], content="ok")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="line1\nline2\nline3")
  @fs.remove_file(tmp_file)
}

///|
test "be_write extract 从 markdown 代码块提取内容" {
  let tmp_file = "/tmp/be-write-extract.txt"
  let input = "{\"file\":\"" +
    tmp_file +
    "\",\"content\":\"```python\\nprint('hi')\\n```\",\"extract\":true}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, false)
  inspect(result.results[0], content="ok")
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="print('hi')")
  @fs.remove_file(tmp_file)
}

///|
test "be_write 保持 CRLF 文件换行风格" {
  let tmp_file = "/tmp/be-write-crlf.txt"
  @fs.write_bytes_to_file(
    tmp_file,
    Bytes::from_array([
      b'a', b'\r', b'\n', b'b', b'\r', b'\n', b'c', b'\r', b'\n',
    ]),
  )
  let input = "{\"file\":\"" + tmp_file + "\",\"content\":\"x\\ny\\nz\"}"
  let _ = @write.be_write(input)
  let bytes = @fs.read_file_to_bytes(tmp_file)
  let mut has_cr = false
  for i = 0; i < bytes.length(); i = i + 1 {
    if bytes[i] == b'\r' {
      has_cr = true
      break
    }
  }
  assert_true(has_cr)
  @fs.remove_file(tmp_file)
}

///|
test "be_write_single 向后兼容单文件写入" {
  let tmp_file = "/tmp/be-write-single-compat.txt"
  let input = "第一行\\n第二行\\n第三行"
  let _ = @write.be_write_single(tmp_file, input)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\n第二行\n第三行")
  @fs.remove_file(tmp_file)
}

///|
test "be_write 新文件默认使用 LF" {
  @testutil.with_temp_file(base_name="new-lf", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"hello\\nworld\\n\"}"
    let _ = @write.be_write(input)
    let bytes = @fs.read_file_to_bytes(tmp)
    let mut has_cr = false
    for i = 0; i < bytes.length(); i = i + 1 {
      if bytes[i] == b'\r' {
        has_cr = true
        break
      }
    }
    assert_false(has_cr)
  })
}

///|
test "be_write 覆盖 CRLF 文件时保留换行风格" {
  @testutil.with_temp_file(base_name="crlf-keep", tmp => {
    @fs.write_bytes_to_file(
      tmp,
      Bytes::from_array([b'l', b'i', b'n', b'e', b'1', b'\r', b'\n']),
    )
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"new1\\nnew2\\n\"}"
    let _ = @write.be_write(input)
    let bytes = @fs.read_file_to_bytes(tmp)
    let mut has_crlf = false
    for i = 0; i < bytes.length() - 1; i = i + 1 {
      if bytes[i] == b'\r' && bytes[i + 1] == b'\n' {
        has_crlf = true
        break
      }
    }
    assert_true(has_crlf)
  })
}

///|
test "be_write 混合 CRLF 输入统一为现有文件换行风格" {
  @testutil.with_temp_file(base_name="crlf-mixed", tmp => {
    @fs.write_bytes_to_file(
      tmp,
      Bytes::from_array([b'k', b'e', b'e', b'p', b'\r', b'\n']),
    )
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"a\\r\\nb\\nc\\r\\nd\\n\"}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("\r\n"))
    assert_false(text.contains("\n\r"))
  })
}

///|
test "be_write 空 content 不报告 trailing newline 警告" {
  @testutil.with_temp_file(base_name="empty-warn", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"\"}"
    let result = @write.be_write(input)
    for warning in result.warnings {
      assert_false(warning.contains("newline"))
    }
  })
}
