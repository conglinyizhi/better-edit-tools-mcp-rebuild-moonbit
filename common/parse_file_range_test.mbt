///|
test "parse simple range with dash" {
  let (path, start, end) = parse_file_range("src/main.go:5-10")
  assert_eq(path, "src/main.go")
  assert_eq(start, 5)
  assert_eq(end, 10)
}

///|
test "parse simple range with tilde" {
  let (path, start, end) = parse_file_range("src/main.go:5~10")
  assert_eq(path, "src/main.go")
  assert_eq(start, 5)
  assert_eq(end, 10)
}

///|
test "parse single line" {
  let (path, start, end) = parse_file_range("src/main.go:5")
  assert_eq(path, "src/main.go")
  assert_eq(start, 5)
  assert_eq(end, 5)
}

///|
test "parse ALL range" {
  let (path, start, end) = parse_file_range("src/main.go:ALL")
  assert_eq(path, "src/main.go")
  assert_eq(start, -1)
  assert_eq(end, -1)
}

///|
test "parse Windows absolute path" {
  let (path, start, end) = parse_file_range("C:\\foo.txt:3")
  assert_eq(path, "C:\\foo.txt")
  assert_eq(start, 3)
  assert_eq(end, 3)
}

///|
test "parse file URL with empty authority" {
  let (path, start, end) = parse_file_range("file:///path/to/file:3")
  assert_eq(path, "file:///path/to/file")
  assert_eq(start, 3)
  assert_eq(end, 3)
}

///|
test "parse file URL with host" {
  let (path, start, end) = parse_file_range("file://host/path:3")
  assert_eq(path, "file://host/path")
  assert_eq(start, 3)
  assert_eq(end, 3)
}

///|
test "parse file URL with port" {
  let (path, start, end) = parse_file_range("file://host:8080/path:3")
  assert_eq(path, "file://host:8080/path")
  assert_eq(start, 3)
  assert_eq(end, 3)
}

///|
test "parse without range suffix" {
  let (path, start, end) = parse_file_range("src/main.go")
  assert_eq(path, "src/main.go")
  assert_eq(start, -1)
  assert_eq(end, -1)
}

///|
test "parse Windows path without range suffix" {
  let (path, start, end) = parse_file_range("C:\\foo.txt")
  assert_eq(path, "C:\\foo.txt")
  assert_eq(start, -1)
  assert_eq(end, -1)
}

///|
test "parse file URL without range suffix" {
  let (path, start, end) = parse_file_range("file:///path/to/file")
  assert_eq(path, "file:///path/to/file")
  assert_eq(start, -1)
  assert_eq(end, -1)
}

///|
test "parse file URL with port without range suffix" {
  let (path, start, end) = parse_file_range("file://host:8080/path")
  assert_eq(path, "file://host:8080/path")
  assert_eq(start, -1)
  assert_eq(end, -1)
}

///|
test "reject negative single line" {
  try {
    let _ = parse_file_range("src/main.go:-5")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "reject negative range start" {
  try {
    let _ = parse_file_range("src/main.go:-5-10")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "reject negative range end" {
  try {
    let _ = parse_file_range("src/main.go:5--10")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "reject zero line" {
  try {
    let _ = parse_file_range("src/main.go:0")
    (fail("expected InvalidFormat error") : Unit)
  } catch {
    @error.BeError::InvalidFormat(_) => ()
    _ => fail("expected InvalidFormat error")
  } noraise {
    _ => fail("expected error to be raised")
  }
}

///|
test "has_file_range with range suffix" {
  assert_eq(has_file_range("src/main.go:5-10"), true)
}

///|
test "has_file_range with single line" {
  assert_eq(has_file_range("src/main.go:5"), true)
}

///|
test "has_file_range with ALL" {
  assert_eq(has_file_range("src/main.go:ALL"), true)
}

///|
test "has_file_range without range suffix" {
  assert_eq(has_file_range("src/main.go"), false)
}

///|
test "has_file_range Windows path with range" {
  assert_eq(has_file_range("C:\\foo.txt:3"), true)
}

///|
test "has_file_range Windows path without range" {
  assert_eq(has_file_range("C:\\foo.txt"), false)
}

///|
test "has_file_range with invalid negative line" {
  assert_eq(has_file_range("src/main.go:-5"), true)
}

///|
test "has_file_range with non-range suffix" {
  assert_eq(has_file_range("src/main.go:abc"), false)
}
