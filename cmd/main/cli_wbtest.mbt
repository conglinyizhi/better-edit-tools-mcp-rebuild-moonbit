// target: native

///|
test "help returns 0 and contains Usage" {
  let output = "/tmp/cli-help-test.txt"
  let code = run_cli(["better-edit-tools-mcp", "--help", "--output", output])
  assert_eq(code, 0)
  let text = @fs.read_file_to_string(output)
  assert_true(text.contains("Usage"))
  @fs.remove_file(output)
}

///|
test "help is Chinese after --lang zh" {
  let output = "/tmp/cli-help-zh-test.txt"
  let code = run_cli([
    "better-edit-tools-mcp", "--lang", "zh", "--help", "--output", output,
  ])
  assert_eq(code, 0)
  let text = @fs.read_file_to_string(output)
  assert_true(text.contains("用法"))
  @fs.remove_file(output)
}

///|
test "read subcommand reads file range" {
  let tmp = "/tmp/cli-read-test.txt"
  let output = "/tmp/cli-read-output.txt"
  @fs.write_string_to_file(tmp, "第一行\n第二行\n第三行")
  let code = run_cli([
    "better-edit-tools-mcp", "read", "--file", tmp, "-s", "1", "-e", "2", "--output",
    output,
  ])
  assert_eq(code, 0)
  let text = @fs.read_file_to_string(output)
  assert_eq(text, "第一行\n第二行")
  @fs.remove_file(tmp)
  @fs.remove_file(output)
}

///|
test "write subcommand writes file" {
  let tmp = "/tmp/cli-write-test.txt"
  let output = "/tmp/cli-write-output.txt"
  let code = run_cli([
    "better-edit-tools-mcp", "write", "--file", tmp, "-c", "hello\\nworld", "--output",
    output,
  ])
  assert_eq(code, 0)
  let text = @fs.read_file_to_string(tmp)
  assert_eq(text, "hello\nworld")
  let out_text = @fs.read_file_to_string(output)
  assert_eq(out_text, "OK")
  @fs.remove_file(tmp)
  @fs.remove_file(output)
}
