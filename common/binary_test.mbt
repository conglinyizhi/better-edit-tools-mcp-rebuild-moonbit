///|
test "reject_binary allows text files" {
  let tmp = "/tmp/common-binary-text.txt"
  @fs.write_string_to_file(tmp, "hello world\n")
  @common.reject_binary(tmp)
  @fs.remove_file(tmp)
}

///|
test "reject_binary rejects files with null bytes" {
  let tmp = "/tmp/common-binary-null.bin"
  let bytes : Array[Byte] = [b'h', b'e', b'l', b'l', b'o', b'\x00', b'w']
  @fs.write_bytes_to_file(tmp, Bytes::from_array(bytes))
  try {
    @common.reject_binary(tmp)
    (fail("expected binary rejection") : Unit)
  } catch {
    @error.BeError::ReadError(msg) =>
      assert_true(msg.contains("appears to be a binary file"))
    _ => fail("expected ReadError")
  } noraise {
    _ => fail("expected error to be raised")
  }
  @fs.remove_file(tmp)
}
