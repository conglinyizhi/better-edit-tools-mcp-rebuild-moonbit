///|
test "be_write 写入 /tmp 下绝对路径文件并把字面 \\n 转为换行" {
  let tmp_file = "/tmp/be-write-test-absolute.txt"
  let input = "第一行\\n第二行\\n第三行"
  @write.be_write(tmp_file, input)
  let text = @fs.read_file_to_string(tmp_file)
  inspect(text, content="第一行\n第二行\n第三行")
  @fs.remove_file(tmp_file)
}
