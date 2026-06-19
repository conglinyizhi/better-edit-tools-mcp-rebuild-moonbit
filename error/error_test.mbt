///|
test "BeError variants include new IOError" {
  let err : @error.BeError = IOError("disk full")
  match err {
    IOError(msg) => inspect(msg, content="disk full")
    _ => fail("expected IOError")
  }
}

///|
test "BeError InvalidArgument can be created" {
  let err : @error.BeError = InvalidArgument("bad arg")
  match err {
    InvalidArgument(msg) => inspect(msg, content="bad arg")
    _ => fail("expected InvalidArgument")
  }
}

///|
test "BeError PathError can be created" {
  let err : @error.BeError = PathError("invalid path")
  match err {
    PathError(msg) => inspect(msg, content="invalid path")
    _ => fail("expected PathError")
  }
}
