///|
test "parse_spec_raw 提取 file 与 content" {
  let input = "{\"file\":\"/tmp/a.txt\",\"content\":\"hello\"}"
  // 通过 be_write 间接验证降级解析：标准 JSON 会成功，因此 degraded=false。
  let result = @write.be_write(input)
  assert_eq(result.degraded, false)
}

///|
test "parse_spec_raw 处理带换行的类 JSON" {
  let tmp = "/tmp/be-write-degraded-raw.txt"
  let input = "{\"file\":\"" + tmp + "\",\"content\":\"line1\nline2\"}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, true)
  assert_eq(result.results[0], "ok")
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="line1\nline2")
  @fs.remove_file(tmp)
}

///|
test "parse_spec_raw 识别 extract 标志" {
  let tmp = "/tmp/be-write-degraded-extract.txt"
  let input = "{\"file\":\"" +
    tmp +
    "\",\"content\":\"```\nextracted\n```\",\"extract\":true}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, true)
  assert_eq(result.results[0], "ok")
  let text = @fs.read_file_to_string(tmp)
  inspect(text, content="extracted")
  @fs.remove_file(tmp)
}
