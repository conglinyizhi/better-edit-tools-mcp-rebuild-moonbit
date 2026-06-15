///|
test "简单 HTML 中定位 div 标签" {
  let tmp_file = "/tmp/be-tag-range-simple.html"
  let content = "<html>\n  <body>\n    <div>Hello</div>\n  </body>\n</html>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 3)
  json_inspect(result, content={
    "tag": "div",
    "range": {
      "start_line": 3,
      "end_line": 3,
      "content": "    <div>Hello</div>",
    },
  })
  @fs.remove_file(tmp_file)
}

///|
test "嵌套标签返回最内层标签" {
  let tmp_file = "/tmp/be-tag-range-nested.html"
  let content = "<root>\n  <outer>\n    <inner>\n      target\n    </inner>\n  </outer>\n</root>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 4)
  json_inspect(result, content={
    "tag": "inner",
    "range": {
      "start_line": 3,
      "end_line": 5,
      "content": "    <inner>\n      target\n    </inner>",
    },
  })
  @fs.remove_file(tmp_file)
}

///|
test "自闭合标签不视为包含标签" {
  let tmp_file = "/tmp/be-tag-range-self.html"
  let content = "<div>\n  <img src=\"x\" />\n  <br/>\n  text\n</div>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 4)
  json_inspect(result, content={
    "tag": "div",
    "range": {
      "start_line": 1,
      "end_line": 5,
      "content": "<div>\n  <img src=\"x\" />\n  <br/>\n  text\n</div>",
    },
  })
  @fs.remove_file(tmp_file)
}

///|
test "忽略 HTML/XML 注释中的标签" {
  let tmp_file = "/tmp/be-tag-range-comment.html"
  let content = "<div>\n  <!-- <span>comment</span> -->\n  <p>real</p>\n</div>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 2)
  json_inspect(result, content={
    "tag": "div",
    "range": {
      "start_line": 1,
      "end_line": 4,
      "content": "<div>\n  <!-- <span>comment</span> -->\n  <p>real</p>\n</div>",
    },
  })
  @fs.remove_file(tmp_file)
}

///|
test "文件不存在时返回 FileNotFound" {
  try @tag_range.be_tag_range("/tmp/be-tag-range-missing.txt", 1) catch {
    @error.BeError::FileNotFound(_) => ()
    _ => fail("expected FileNotFound")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "行号越界时返回 InvalidFormat" {
  let tmp_file = "/tmp/be-tag-range-line.html"
  @fs.write_string_to_file(tmp_file, "<div></div>")
  try @tag_range.be_tag_range(tmp_file, 0) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat for line 0")
  } noraise {
    _ => fail("expected error to be raised for line 0")
  }
  try @tag_range.be_tag_range(tmp_file, 5) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat for line 5")
  } noraise {
    _ => fail("expected error to be raised for line 5")
  }
  @fs.remove_file(tmp_file)
}

///|
test "目标行不在任何标签对内时返回 InvalidFormat" {
  let tmp_file = "/tmp/be-tag-range-none.html"
  @fs.write_string_to_file(tmp_file, "plain text\nno tags")
  try @tag_range.be_tag_range(tmp_file, 1) catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat")
  } noraise {
    _ => fail("expected error to be raised")
  }
  @fs.remove_file(tmp_file)
}
