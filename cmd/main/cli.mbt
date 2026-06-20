///|
/// 命令行选项。
struct CliOptions {
  mut show_version : Bool
  mut show_help : Bool
  mut file : String?
  mut start : Int?
  mut end : Int?
  mut content : String?
  mut old : String?
  mut viewed_code_id : String?
  mut output : String?
}

///|
/// 将 BeError 转换为带翻译前缀的消息。
fn format_error(err : @error.BeError) -> String {
  match err {
    @error.BeError::InvalidFormat(msg) =>
      @common.t("error.InvalidFormat") + ": " + msg
    @error.BeError::InvalidArgument(msg) =>
      @common.t("error.InvalidArgument") + ": " + msg
    @error.BeError::FileNotFound(msg) =>
      @common.t("error.FileNotFound") + ": " + msg
    @error.BeError::NotARegularFile(msg) =>
      @common.t("error.NotARegularFile") + ": " + msg
    @error.BeError::PathError(msg) => @common.t("error.PathError") + ": " + msg
    @error.BeError::ReadError(msg) => @common.t("error.ReadError") + ": " + msg
    @error.BeError::WriteError(msg) =>
      @common.t("error.WriteError") + ": " + msg
    @error.BeError::IOError(msg) => @common.t("error.IOError") + ": " + msg
  }
}

///|
/// 解析整数参数，失败返回 None。
fn parse_int_arg(s : String) -> Int? {
  Some(@strconv.from_str(s) catch { _ => return None })
}

///|
/// 输出文本到 stdout 或指定文件。
fn emit_output(text : String, output : String?) -> Int {
  match output {
    None => {
      println(text)
      0
    }
    Some(path) =>
      try {
        @fs.write_string_to_file(path, text)
        0
      } catch {
        IOError(msg) => {
          println(@common.t("error.WriteError") + ": " + msg)
          2
        }
      }
  }
}

///|
/// 返回帮助文本。
fn help_text() -> String {
  [
    @common.t("cli.help.usage"),
    "",
    "Commands:",
    "  read        " + @common.t("cli.command.read"),
    "  replace     " + @common.t("cli.command.replace"),
    "  insert      " + @common.t("cli.command.insert"),
    "  delete      " + @common.t("cli.command.delete"),
    "  write       " + @common.t("cli.command.write"),
    "  balance     " + @common.t("cli.command.balance"),
    "  func-range  " + @common.t("cli.command.func-range"),
    "  tag-range   " + @common.t("cli.command.tag-range"),
    "",
    @common.t("cli.help.global_flags") + ":",
    "  --lang <zh|en>",
    "  --no-prefix",
    "  --version   " + @common.t("cli.help.version"),
    "  --help",
    "",
    "Common flags:",
    "  --file <path>",
    "  -s, --start <n>",
    "  -e, --end <n>",
    "  -c, --content <text>",
    "  --old <text>",
    "  --viewed_code_id <id>",
    "  --preview",
    "  --brief",
    "  --output <path>",
  ].join("\n")
}

///|
/// 返回版本文本。
fn version_text() -> String {
  @common.t("cli.help.version") + " 0.1.0"
}

///|
/// 构造 read 工具的输入字符串。
fn build_range_input(file : String, start : Int?, end : Int?) -> String {
  match start {
    None => file
    Some(s) =>
      match end {
        None => "\{file}:\{s}"
        Some(e) => "\{file}:\{s}-\{e}"
      }
  }
}

///|
/// 解析命令行参数。返回 (选项, 子命令, 解析错误)。
fn parse_args(args : Array[String]) -> (CliOptions, String?, String?) {
  let opts : CliOptions = {
    show_version: false,
    show_help: false,
    file: None,
    start: None,
    end: None,
    content: None,
    old: None,
    viewed_code_id: None,
    output: None,
  }
  let mut command : String? = None
  let mut error : String? = None
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--lang" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --lang")
        break
      }
      @common.set_language(args[i])
    } else if arg == "--no-prefix" {
      // 保留兼容性，忽略
    } else if arg == "--version" {
      opts.show_version = true
    } else if arg == "--help" {
      opts.show_help = true
    } else if arg == "--file" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --file")
        break
      }
      opts.file = Some(args[i])
    } else if arg == "-s" || arg == "--start" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --start")
        break
      }
      match parse_int_arg(args[i]) {
        Some(n) => opts.start = Some(n)
        None => {
          error = Some("Invalid integer for --start: " + args[i])
          break
        }
      }
    } else if arg == "-e" || arg == "--end" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --end")
        break
      }
      match parse_int_arg(args[i]) {
        Some(n) => opts.end = Some(n)
        None => {
          error = Some("Invalid integer for --end: " + args[i])
          break
        }
      }
    } else if arg == "-c" || arg == "--content" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --content")
        break
      }
      opts.content = Some(args[i])
    } else if arg == "--old" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --old")
        break
      }
      opts.old = Some(args[i])
    } else if arg == "--viewed_code_id" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --viewed_code_id")
        break
      }
      opts.viewed_code_id = Some(args[i])
    } else if arg == "--preview" {
      // 保留标志位，当前仅解析
    } else if arg == "--brief" {
      // 保留标志位，当前仅解析
    } else if arg == "--output" {
      i += 1
      if i >= args.length() {
        error = Some("Missing value for --output")
        break
      }
      opts.output = Some(args[i])
    } else if arg.has_prefix("-") {
      error = Some("Unknown flag: " + arg)
      break
    } else if command is None {
      command = Some(arg)
    } else {
      error = Some("Unexpected argument: " + arg)
      break
    }
    i += 1
  }
  (opts, command, error)
}

///|
/// 解析 CLI 参数并执行，返回退出码。
pub fn run_cli(args : Array[String]) -> Int {
  let (opts, command, parse_error) = parse_args(args)
  if parse_error is Some(msg) {
    println(@common.t("error.InvalidFormat") + ": " + msg)
    return 1
  }
  if opts.show_version {
    return emit_output(version_text(), opts.output)
  }
  if opts.show_help {
    return emit_output(help_text(), opts.output)
  }
  let cmd = match command {
    Some(c) => c
    None => {
      let _ = emit_output(help_text(), opts.output)
      return 1
    }
  }
  let file = match opts.file {
    Some(f) => f
    None => {
      println(@common.t("error.InvalidFormat") + ": --file is required")
      return 1
    }
  }
  let content = match opts.content {
    Some(v) => v
    None => ""
  }
  let viewed_code_id = match opts.viewed_code_id {
    Some(v) => v
    None => ""
  }
  let old = match opts.old {
    Some(v) => v
    None => ""
  }
  match cmd {
    "read" => {
      let input = build_range_input(file, opts.start, opts.end)
      try {
        let result = @read.be_read(input)
        emit_output(result.range.content, opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "replace" => {
      guard opts.start is Some(start_line) else {
        println(@common.t("error.InvalidFormat") + ": --start is required")
        return 1
      }
      guard opts.end is Some(end_line) else {
        println(@common.t("error.InvalidFormat") + ": --end is required")
        return 1
      }
      guard opts.content is Some(_) else {
        println(@common.t("error.InvalidFormat") + ": --content is required")
        return 1
      }
      try {
        let result = @edit.be_replace(
          file,
          start_line,
          end_line,
          content,
          viewed_code_id~,
          old~,
        )
        let out = if result.preview && !result.brief && result.diff.length() > 0 {
          result.status + "\n" + result.diff
        } else {
          "OK"
        }
        emit_output(out, opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "insert" => {
      guard opts.content is Some(_) else {
        println(@common.t("error.InvalidFormat") + ": --content is required")
        return 1
      }
      let after_line = match opts.start {
        Some(s) => s
        None =>
          match opts.end {
            Some(e) => e
            None => 0
          }
      }
      try {
        let result = @edit.be_insert(file, content, after_line~)
        let out = if result.preview && !result.brief && result.diff.length() > 0 {
          result.status + "\n" + result.diff
        } else {
          "OK"
        }
        emit_output(out, opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "delete" => {
      guard opts.start is Some(_) else {
        println(@common.t("error.InvalidFormat") + ": --start is required")
        return 1
      }
      guard opts.end is Some(_) else {
        println(@common.t("error.InvalidFormat") + ": --end is required")
        return 1
      }
      let s = match opts.start {
        Some(v) => v
        None => 0
      }
      let e = match opts.end {
        Some(v) => v
        None => 0
      }
      try {
        let result = @edit.be_delete(file, start=s, end=e)
        let out = if result.preview && !result.brief && result.diff.length() > 0 {
          result.status + "\n" + result.diff
        } else {
          "OK"
        }
        emit_output(out, opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "write" => {
      guard opts.content is Some(_) else {
        println(@common.t("error.InvalidFormat") + ": --content is required")
        return 1
      }
      try {
        let input : Json = { "file": file, "content": content }
        let result = @write.be_write(input.stringify())
        let mut failed : String? = None
        for r in result.results {
          if r != "ok" {
            failed = Some(r)
            break
          }
        }
        match failed {
          Some(msg) => {
            let _ = emit_output(msg, opts.output)
            2
          }
          None => emit_output("OK", opts.output)
        }
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "balance" =>
      try {
        let result = @check.be_balance(file, verbose=true)
        emit_output(result.to_json().stringify(), opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    "func-range" => {
      guard opts.start is Some(line) else {
        println(@common.t("error.InvalidFormat") + ": --start is required")
        return 1
      }
      try {
        let result = @check.be_func_range(file, line)
        emit_output(result.to_json().stringify(), opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    "tag-range" => {
      guard opts.start is Some(line) else {
        println(@common.t("error.InvalidFormat") + ": --start is required")
        return 1
      }
      try {
        let result = @check.be_tag_range(file, line)
        emit_output(result.to_json().stringify(), opts.output)
      } catch {
        err => {
          println(format_error(err))
          2
        }
      }
    }
    _ => {
      println(@common.t("error.UnknownTool") + ": " + cmd)
      1
    }
  }
}
