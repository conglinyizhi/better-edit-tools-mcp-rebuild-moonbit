// 黑盒测试针对包的公共 API 运行。使用 `@better-edit-tools-mcp` 导入。
// 优先验证高层行为，而非实现细节。
// 运行 `moon test` 执行测试，`moon test --update` 刷新快照。

///|
test "be_read 读取 /tmp 下绝对路径文件的指定行范围" {
  let tmp_file = "/tmp/be-read-test-absolute.txt"
  let content = "第一行\n第二行\n第三行\n第四行\n第五行"
  @fs.write_string_to_file(tmp_file, content)
  let result = @better-edit-tools-mcp.be_read("\{tmp_file}:2-4")
  inspect(result.content, content="第二行\n第三行\n第四行")
  inspect(result.start_line, content="2")
  inspect(result.end_line, content="4")
  assert_true(result.viewed_code_id.length() > 0)
  @fs.remove_file(tmp_file)
}
