// target: native

///|
test "should_start_server returns true for empty args" {
  assert_true(should_start_server([]))
}

///|
test "should_start_server returns true for program name only" {
  assert_true(should_start_server(["better-edit-tools-mcp"]))
}

///|
test "should_start_server returns false when a subcommand is given" {
  assert_false(should_start_server(["better-edit-tools-mcp", "read"]))
}
