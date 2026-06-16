///|
test "be_read 读取 /tmp 下绝对路径文件的指定行范围" {
  let tmp_file = "/tmp/be-read-test-absolute.txt"
  let content = "第一行\n第二行\n第三行\n第四行\n第五行"
  @fs.write_string_to_file(tmp_file, content)
  let result = @read.be_read("\{tmp_file}:2-4")
  inspect(result.range.content, content="第二行\n第三行\n第四行")
  inspect(result.range.start_line, content="2")
  inspect(result.range.end_line, content="4")
  assert_true(result.viewed_code_id.length() > 0)
  @fs.remove_file(tmp_file)
}

///|
test "be_read 能处理路径中包含冒号的文件" {
  let tmp_file = "/tmp/be:read:test.txt"
  let content = "第一行\n第二行\n第三行\n第四行"
  @fs.write_string_to_file(tmp_file, content)
  let result = @read.be_read("\{tmp_file}:2-3")
  inspect(result.range.content, content="第二行\n第三行")
  inspect(result.range.start_line, content="2")
  inspect(result.range.end_line, content="3")
  @fs.remove_file(tmp_file)
}

///|
test "be_read 拒绝 chip:// 作为目标文件" {
  try {
    let _ = @read.be_read("chip://some-id:1-2")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => (fail("expected InvalidFormat error") : Unit)
  } noraise {
    _ => (fail("expected error to be raised") : Unit)
  }
}

///|
test "be_read 不提供行号时读取整个文件" {
  let tmp_file = "/tmp/be-read-test-whole.txt"
  let content = "第一行\n第二行\n第三行"
  @fs.write_string_to_file(tmp_file, content)
  let result = @read.be_read(tmp_file)
  inspect(result.range.content, content="第一行\n第二行\n第三行")
  inspect(result.range.start_line, content="1")
  inspect(result.range.end_line, content="3")
  assert_true(result.viewed_code_id.length() > 0)
  @fs.remove_file(tmp_file)
}

///|
test "be_read 支持单独行号读取单行" {
  let tmp_file = "/tmp/be-read-test-single.txt"
  @fs.write_string_to_file(tmp_file, "第一行\n第二行\n第三行")
  let result = @read.be_read(tmp_file + ":2")
  inspect(result.range.content, content="第二行")
  inspect(result.range.start_line, content="2")
  inspect(result.range.end_line, content="2")
  @fs.remove_file(tmp_file)
}

///|
test "be_read 支持 ~ 作为多行分隔符" {
  let tmp_file = "/tmp/be-read-test-tilde.txt"
  @fs.write_string_to_file(
    tmp_file, "第一行\n第二行\n第三行\n第四行",
  )
  let result = @read.be_read(tmp_file + ":2~3")
  inspect(result.range.content, content="第二行\n第三行")
  inspect(result.range.start_line, content="2")
  inspect(result.range.end_line, content="3")
  @fs.remove_file(tmp_file)
}
