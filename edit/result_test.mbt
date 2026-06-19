///|
test "EditResult serializes to JSON" {
  let result : @edit.EditResult = {
    status: "ok",
    file: "/tmp/test.txt",
    removed: 1,
    added: 2,
    total: 5,
    diff: "",
    balance: "",
    affected: [2],
    preview: false,
    brief: false,
    warnings: [],
    event_id: "evt-1",
    queue_full: false,
  }
  let json = result.to_json().stringify()
  assert_true(json.contains("\"status\":\"ok\""))
  assert_true(json.contains("\"file\":\"/tmp/test.txt\""))
  assert_true(json.contains("\"removed\":1"))
  assert_true(json.contains("\"added\":2"))
  assert_true(json.contains("\"total\":5"))
  assert_true(json.contains("\"event_id\":\"evt-1\""))
}
