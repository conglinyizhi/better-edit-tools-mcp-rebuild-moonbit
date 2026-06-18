///|
/// CLI entry point. Run `moon run cmd/main` to start the MCP server.
fn main {
  let args = @sys.get_cli_args()
  if should_start_server(args) {
    @server.run()
  } else {
    dispatch_cli_or_server(args)
  }
}

///|
/// native target 下执行 CLI 子命令并退出；其他 target 回退到启动 MCP 服务器。
#cfg(target="native")
fn dispatch_cli_or_server(args : Array[String]) -> Unit {
  let code = run_cli(args)
  @sys.exit(code)
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
fn dispatch_cli_or_server(args : Array[String]) -> Unit {
  let _ = args
  @server.run()
}

///|
/// Determine whether the program should start the MCP server from the
/// command-line argument list.
pub fn should_start_server(args : Array[String]) -> Bool {
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "--version" {
      return false
    }
    if arg == "--lang" {
      i += 2
      continue
    }
    if arg == "--no-prefix" {
      i += 1
      continue
    }
    if arg.has_prefix("-") {
      return false
    }
    return false
  }
  true
}
