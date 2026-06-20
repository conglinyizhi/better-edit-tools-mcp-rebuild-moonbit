///|
test "be_func_range 返回包含目标行的最内层 {} 块" {
  let tmp = "/tmp/be-func-range-simple.mbt"
  let content =
    #|fn f() {
    #|  let x = 1
    #|  return x
    #|}
  @fs.write_string_to_file(tmp, content)
  let result = @check.be_func_range(tmp, 2)
  inspect(result.start_line, content="1")
  inspect(result.end_line, content="4")
  inspect(result.content, content="fn f() {\n  let x = 1\n  return x\n}")
  @fs.remove_file(tmp)
}

///|
test "be_func_range 嵌套块返回最内层块" {
  let tmp = "/tmp/be-func-range-nested.mbt"
  let content =
    #|fn outer() {
    #|  fn inner() {
    #|    let x = 1
    #|  }
    #|}
  @fs.write_string_to_file(tmp, content)
  let result = @check.be_func_range(tmp, 3)
  inspect(result.start_line, content="2")
  inspect(result.end_line, content="4")
  inspect(result.content, content="  fn inner() {\n    let x = 1\n  }")
  @fs.remove_file(tmp)
}

///|
test "be_func_range 忽略字符串和注释中的花括号" {
  let tmp = "/tmp/be-func-range-string-comment.mbt"
  let content =
    #|fn f() {
    #|  let s = "{ not a block }"
    #|  let c = '{'
    #|  // { this is ignored
    #|  let x = 1
    #|}
  @fs.write_string_to_file(tmp, content)
  let result = @check.be_func_range(tmp, 5)
  inspect(result.start_line, content="1")
  inspect(result.end_line, content="6")
  inspect(
    result.content,
    content="fn f() {\n  let s = \"{ not a block }\"\n  let c = '{'\n  // { this is ignored\n  let x = 1\n}",
  )
  @fs.remove_file(tmp)
}

///|
test "be_func_range 文件不存在时返回 FileNotFound" {
  let tmp = "/tmp/be-func-range-missing.mbt"
  try @check.be_func_range(tmp, 1) catch {
    @error.BeError::FileNotFound(path) => inspect(path, content=tmp)
    _ => fail("期望 FileNotFound 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
}

///|
test "be_func_range 行号越界时返回 InvalidFormat" {
  let tmp = "/tmp/be-func-range-out-of-range.mbt"
  let content =
    #|fn f() {
    #|  let x = 1
    #|}
  @fs.write_string_to_file(tmp, content)
  try @check.be_func_range(tmp, 0) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("行号 0 应返回 InvalidFormat")
  } noraise {
    _ => fail("行号 0 应抛出错误")
  }
  try @check.be_func_range(tmp, 10) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("行号 10 应返回 InvalidFormat")
  } noraise {
    _ => fail("行号 10 应抛出错误")
  }
  @fs.remove_file(tmp)
}

///|
test "be_func_range 目标行不在任何 {} 块内时返回 InvalidFormat" {
  let tmp = "/tmp/be-func-range-no-block.mbt"
  let content =
    #|let x = 1
    #|let y = 2
  @fs.write_string_to_file(tmp, content)
  try @check.be_func_range(tmp, 1) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("期望 InvalidFormat 错误")
  } noraise {
    _ => fail("期望函数抛出错误")
  }
  @fs.remove_file(tmp)
}

///|
test "func_range 包含函数签名行" {
  @testutil.with_temp_file(base_name="func-sig", tmp => {
    let content =
      #|package main
      #|
      #|func hello() {
      #|  return 1
      #|}
    @fs.write_string_to_file(tmp, content)
    let result = @check.be_func_range(tmp, 3)
    assert_eq(result.start_line, 3)
    assert_eq(result.end_line, 5)
  })
}

///|
test "func_range 空函数体单行返回" {
  @testutil.with_temp_file(base_name="func-empty", tmp => {
    let content =
      #|package main
      #|
      #|func empty() {}
    @fs.write_string_to_file(tmp, content)
    let result = @check.be_func_range(tmp, 3)
    assert_eq(result.start_line, 3)
    assert_eq(result.end_line, 3)
  })
}

///|
test "func_range 嵌套块返回最外层函数" {
  @testutil.with_temp_file(base_name="func-nested", tmp => {
    let content =
      #|package main
      #|
      #|func demo() {
      #|  if true {
      #|    for i := 0; i < 10; i++ {
      #|      do()
      #|    }
      #|  }
      #|}
    @fs.write_string_to_file(tmp, content)
    let result = @check.be_func_range(tmp, 3)
    assert_eq(result.start_line, 3)
    assert_eq(result.end_line, 9)
  })
}

///|
test "func_range 目标在内部块时返回最内层包含块" {
  @testutil.with_temp_file(base_name="func-inner", tmp => {
    let content =
      #|package main
      #|
      #|func outer() {
      #|  if true {
      #|    innerFunc()
      #|  }
      #|}
    @fs.write_string_to_file(tmp, content)
    let result = @check.be_func_range(tmp, 5)
    // 当前实现返回包含目标行的最内层 {} 块（if 块），而非外层函数
    assert_eq(result.start_line, 4)
    assert_eq(result.end_line, 6)
  })
}
