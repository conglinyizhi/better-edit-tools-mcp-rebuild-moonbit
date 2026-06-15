///|
test "简单 HTML 中定位 div 标签" {
  let tmp_file = "/tmp/be-tag-range-simple.html"
  let content = "<html>\n  <body>\n    <div>Hello</div>\n  </body>\n</html>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 3)
  @json.inspect(result, content={
    "start_line": 3,
    "end_line": 3,
    "tag": "div",
    "content": "    <div>Hello</div>",
  })
  @fs.remove_file(tmp_file)
}

///|
test "嵌套标签返回最内层标签" {
  let tmp_file = "/tmp/be-tag-range-nested.html"
  let content = "<root>\n  <outer>\n    <inner>\n      target\n    </inner>\n  </outer>\n</root>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 4)
  @json.inspect(result, content={
    "start_line": 3,
    "end_line": 5,
    "tag": "inner",
    "content": "    <inner>\n      target\n    </inner>",
  })
  @fs.remove_file(tmp_file)
}

///|
test "自闭合标签不视为包含标签" {
  let tmp_file = "/tmp/be-tag-range-self.html"
  let content = "<div>\n  <img src=\"x\" />\n  <br/>\n  text\n</div>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 4)
  @json.inspect(result, content={
    "start_line": 1,
    "end_line": 5,
    "tag": "div",
    "content": "<div>\n  <img src=\"x\" />\n  <br/>\n  text\n</div>",
  })
  @fs.remove_file(tmp_file)
}

///|
test "忽略 HTML/XML 注释中的标签" {
  let tmp_file = "/tmp/be-tag-range-comment.html"
  let content = "<div>\n  <!-- <span>comment</span> -->\n  <p>real</p>\n</div>"
  @fs.write_string_to_file(tmp_file, content)
  let result = @tag_range.be_tag_range(tmp_file, 2)
  @json.inspect(result, content={
    "start_line": 1,
    "end_line": 4,
    "tag": "div",
    "content": "<div>\n  <!-- <span>comment</span> -->\n  <p>real</p>\n</div>",
  })
  @fs.remove_file(tmp_file)
}

///|
test "文件不存在时返回 FileNotFound" {
  let result = try? @tag_range.be_tag_range("/tmp/be-tag-range-missing.txt", 1)
  guard result is Err(@error.BeError::FileNotFound(_)) else {
    fail("expected FileNotFound")
  }
}

///|
test "行号越界时返回 InvalidFormat" {
  let tmp_file = "/tmp/be-tag-range-line.html"
  @fs.write_string_to_file(tmp_file, "<div></div>")
  let r1 = try? @tag_range.be_tag_range(tmp_file, 0)
  guard r1 is Err(@error.BeError::InvalidFormat(_)) else {
    fail("expected InvalidFormat for line 0")
  }
  let r2 = try? @tag_range.be_tag_range(tmp_file, 5)
  guard r2 is Err(@error.BeError::InvalidFormat(_)) else {
    fail("expected InvalidFormat for line 5")
  }
  @fs.remove_file(tmp_file)
}

///|
test "目标行不在任何标签对内时返回 InvalidFormat" {
  let tmp_file = "/tmp/be-tag-range-none.html"
  @fs.write_string_to_file(tmp_file, "plain text\nno tags")
  let result = try? @tag_range.be_tag_range(tmp_file, 1)
  guard result is Err(@error.BeError::InvalidFormat(_)) else {
    fail("expected InvalidFormat")
  }
  @fs.remove_file(tmp_file)
}
