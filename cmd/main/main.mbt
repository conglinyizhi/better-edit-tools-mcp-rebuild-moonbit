///|
/// CLI entry point. Run `moon run cmd/main` to start the MCP server.
fn main raise {
  let args = @sys.get_cli_args()
  if should_start_server(args) {
    @server.run()
  } else {
    println("Usage: better-edit-tools-mcp [command] [options]")
    println("")
    println("Without arguments, starts the MCP server over stdin/stdout.")
    @sys.exit(0)
  }
}

///|
/// Determine whether the program should start the MCP server from the
/// command-line argument list.
pub fn should_start_server(args : Array[String]) -> Bool {
  args.length() <= 1
}
