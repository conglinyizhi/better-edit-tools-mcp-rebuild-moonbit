///|
test "be_read 空文件返回 0 行" {
  let tmp = "/tmp/be-read-empty.txt"
  @fs.write_string_to_file(tmp, "")
  let result = @read.be_read(tmp)
  inspect(result.range.start_line, content="0")
  inspect(result.range.end_line, content="0")
  inspect(result.range.content, content="")
  assert_true(result.viewed_code_id.length() > 0)
  @fs.remove_file(tmp)
}

///|
test "be_read 二进制文件被拒绝" {
  let tmp = "/tmp/be-read-binary.bin"
  @fs.write_bytes_to_file(tmp, Bytes::from_array([b'h', b'i', b'\x00', b'x']))
  try {
    let _ = @read.be_read(tmp)
    (fail("expected ReadError") : Unit)
  } catch {
    @error.BeError::ReadError(msg) =>
      assert_true(msg.contains("appears to be a binary file"))
    _ => (fail("expected ReadError") : Unit)
  } noraise {
    _ => (fail("expected error") : Unit)
  }
  @fs.remove_file(tmp)
}

///|
test "be_read 保留 CRLF 文件字节" {
  let tmp = "/tmp/be-read-crlf.txt"
  @fs.write_bytes_to_file(tmp, Bytes::from_array([b'a', b'\r', b'\n', b'b']))
  let result = @read.be_read(tmp)
  inspect(result.range.content, content="a\nb")
  inspect(result.range.start_line, content="1")
  inspect(result.range.end_line, content="2")
  @fs.remove_file(tmp)
}
