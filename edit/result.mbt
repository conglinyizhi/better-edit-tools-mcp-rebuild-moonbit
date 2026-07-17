///|
let event_counter : Ref[Int] = { val: 0 }

///|
fn new_event_id() -> String {
  event_counter.val += 1
  "evt-\{@env.now()}-\{event_counter.val}"
}

///|
/// 统一编辑操作结果。
pub(all) struct EditResult {
  status : String
  file : String
  removed : Int
  added : Int
  total : Int
  diff : String
  balance : String
  affected : Array[Int]
  preview : Bool
  brief : Bool
  warnings : Array[String]
  event_id : String
  queue_full : Bool
} derive(Debug, ToJson)

///|
pub extend EditResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend EditResult with ToJson::{to_json}
