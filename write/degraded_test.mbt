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

///|
test "parse_spec_raw 处理未转义 tab" {
  @testutil.with_temp_file(base_name="deg-tab", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"hello\tworld\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("hello"))
    assert_true(text.contains("world"))
  })
}

///|
test "parse_spec_raw 处理未转义 CR" {
  @testutil.with_temp_file(base_name="deg-cr", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"hello\rworld\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("world"))
  })
}

///|
test "parse_spec_raw 处理不平衡引号" {
  @testutil.with_temp_file(base_name="deg-quote", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"it's \"bad\" quote\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.length() > 0)
  })
}

///|
test "parse_spec_raw 保留反引号" {
  @testutil.with_temp_file(base_name="deg-backtick", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"`code`\"}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("`code`"))
  })
}

///|
test "parse_spec_raw 处理嵌套未转义引号" {
  @testutil.with_temp_file(base_name="deg-nested", tmp => {
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"line with \"nested\" and \"more\" quotes\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.length() > 0)
  })
}

///|
test "parse_spec_raw key 之间允许换行且不降级" {
  @testutil.with_temp_file(base_name="deg-keys", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\n\"content\":\"hello\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, false)
    let text = @fs.read_file_to_string(tmp)
    assert_eq(text, "hello")
  })
}

///|
test "parse_spec_raw 缺少 file 字段时不执行写入" {
  let input = "{\"content\":\"write to nowhere\"}"
  let result = @write.be_write(input)
  assert_eq(result.files.length(), 0)
}

///|
test "parse_spec_raw null content 生成空文件" {
  @testutil.with_temp_file(base_name="deg-null", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":null}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_eq(text, "")
  })
}

///|
test "parse_spec_raw Unicode 内容保留" {
  @testutil.with_temp_file(base_name="deg-unicode", tmp => {
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"hello 世界 unicode ✓\"}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_eq(text, "hello 世界 unicode ✓")
  })
}

///|
test "parse_spec_raw 降级模式下 Unicode 仍保留" {
  @testutil.with_temp_file(base_name="deg-unicode-deg", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":\"hello\n世界\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("hello"))
  })
}

///|
test "parse_spec_raw 处理转义引号开头的 content" {
  @testutil.with_temp_file(base_name="deg-esc-quote", tmp => {
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"\\\"leading quote\\\"\"}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_eq(text, "\"leading quote\"")
  })
}

///|
test "parse_spec_raw 处理混合未转义控制字符" {
  @testutil.with_temp_file(base_name="deg-ctrl", tmp => {
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"hello\tline2\r\nline3\"}"
    let result = @write.be_write(input)
    assert_eq(result.degraded, true)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("hello"))
    assert_true(text.contains("line"))
  })
}

///|
test "parse_spec_raw content 为 JSON 对象时不崩溃" {
  @testutil.with_temp_file(base_name="deg-json-obj", tmp => {
    let input = "{\"file\":\"" + tmp + "\",\"content\":{\"nested\":true}}"
    let result = @write.be_write(input)
    // 当前实现对非字符串 content 退化为空内容
    assert_eq(result.degraded, false)
  })
}

///|
test "parse_spec_raw Go raw string 风格保留关键字" {
  @testutil.with_temp_file(base_name="deg-raw", tmp => {
    let input = "{\"file\":\"" +
      tmp +
      "\",\"content\":\"raw\\\\nstring\\\\nliteral\"}"
    let _ = @write.be_write(input)
    let text = @fs.read_file_to_string(tmp)
    assert_true(text.contains("raw"))
    assert_true(text.contains("literal"))
  })
}

///|
test "parse_spec_raw 降级模式下写入多个文件" {
  let tmp_a = "/tmp/be-write-deg-multi-a.txt"
  let tmp_b = "/tmp/be-write-deg-multi-b.txt"
  let input = "{\"file\":\"" +
    tmp_a +
    "\",\"content\":'line \"a\" end',\"file\":\"" +
    tmp_b +
    "\",\"content\":'line \"b\" end'}"
  let result = @write.be_write(input)
  assert_eq(result.degraded, true)
  assert_eq(result.files.length(), 2)
  assert_true(@fs.read_file_to_string(tmp_a).contains("line \"a\" end"))
  assert_true(@fs.read_file_to_string(tmp_b).contains("line \"b\" end"))
  @fs.remove_file(tmp_a)
  @fs.remove_file(tmp_b)
}
