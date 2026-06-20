///|
test "with_temp_file creates file path and cleans up" {
  let seen = Ref("")
  let _ : Unit = @testutil.with_temp_file(base_name="self", path => {
    seen.val = path
    @fs.write_string_to_file(path, "hello")
    assert_true(@fs.path_exists(path))
  })
  assert_false(@fs.path_exists(seen.val))
}

///|
test "with_temp_file cleans up even when test body raises" {
  let seen = Ref("")
  try {
    let _ : Unit = @testutil.with_temp_file(base_name="self-raise", path => {
      seen.val = path
      @fs.write_string_to_file(path, "hello")
      fail("intentional failure")
    })
  } catch {
    _ => ()
  } noraise {
    _ => fail("expected raised error")
  }
  assert_false(@fs.path_exists(seen.val))
}
