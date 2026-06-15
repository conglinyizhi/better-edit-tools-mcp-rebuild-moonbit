///|
test "balanced file with all supported kinds (verbose=true)" {
  let tmp = "/tmp/be-balance-balanced.txt"
  let content = "(a){b}[c]\n\"str\"\n'x'\n<div><span></span></div>"
  @fs.write_string_to_file(tmp, content)
  let result = @balance.be_balance(tmp, verbose=true)
  json_inspect(result, content={
    "ok": true,
    "pairs": [
      {
        "kind": "paren",
        "open": { "line": 1, "col": 1 },
        "close": { "line": 1, "col": 3 },
      },
      {
        "kind": "brace",
        "open": { "line": 1, "col": 4 },
        "close": { "line": 1, "col": 6 },
      },
      {
        "kind": "bracket",
        "open": { "line": 1, "col": 7 },
        "close": { "line": 1, "col": 9 },
      },
      {
        "kind": "dquote",
        "open": { "line": 2, "col": 1 },
        "close": { "line": 2, "col": 5 },
      },
      {
        "kind": "squote",
        "open": { "line": 3, "col": 1 },
        "close": { "line": 3, "col": 3 },
      },
      {
        "kind": "tag",
        "open": { "line": 4, "col": 6 },
        "close": { "line": 4, "col": 18 },
      },
      {
        "kind": "tag",
        "open": { "line": 4, "col": 1 },
        "close": { "line": 4, "col": 24 },
      },
    ],
    "mismatches": [],
  })
  @fs.remove_file(tmp)
}

///|
test "balanced file with verbose=false returns no pairs" {
  let tmp = "/tmp/be-balance-balanced-quiet.txt"
  let content = "(a){b}[c]\n\"str\"\n'x'\n<div><span></span></div>"
  @fs.write_string_to_file(tmp, content)
  let result = @balance.be_balance(tmp, verbose=false)
  json_inspect(result, content={ "ok": true, "pairs": [], "mismatches": [] })
  @fs.remove_file(tmp)
}

///|
test "symbols inside strings and comments are ignored" {
  let tmp = "/tmp/be-balance-ignored.txt"
  let content = "\"(\"\n'[' /* } */"
  @fs.write_string_to_file(tmp, content)
  let result = @balance.be_balance(tmp)
  json_inspect(result, content={ "ok": true, "pairs": [], "mismatches": [] })
  @fs.remove_file(tmp)
}

///|
test "unbalanced file returns mismatches (verbose=false)" {
  let tmp = "/tmp/be-balance-unbalanced.txt"
  let content = "(a]\n}\n<div></span>\n\""
  @fs.write_string_to_file(tmp, content)
  let result = @balance.be_balance(tmp)
  json_inspect(result, content={
    "ok": false,
    "pairs": [],
    "mismatches": [
      {
        "kind": "bracket",
        "loc": { "line": 1, "col": 3 },
        "reason": "unexpected closing bracket",
      },
      {
        "kind": "brace",
        "loc": { "line": 2, "col": 1 },
        "reason": "unexpected closing brace",
      },
      {
        "kind": "tag",
        "loc": { "line": 3, "col": 6 },
        "reason": "tag mismatch: expected </div> but found </span>",
      },
      {
        "kind": "paren",
        "loc": { "line": 1, "col": 1 },
        "reason": "unclosed paren",
      },
      {
        "kind": "tag",
        "loc": { "line": 3, "col": 1 },
        "reason": "unclosed tag",
      },
      {
        "kind": "dquote",
        "loc": { "line": 4, "col": 1 },
        "reason": "unclosed dquote",
      },
    ],
  })
  @fs.remove_file(tmp)
}

///|
test "file not found raises FileNotFound" {
  try @balance.be_balance("/tmp/be-balance-missing.txt") catch {
    @error.BeError::FileNotFound(_) => ()
    _ => fail("expected FileNotFound error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "directory path raises NotARegularFile" {
  try @balance.be_balance("/tmp") catch {
    @error.BeError::NotARegularFile(_) => ()
    _ => fail("expected NotARegularFile error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}
