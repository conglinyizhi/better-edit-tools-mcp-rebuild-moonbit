///|
/// 将字符串按 UTF-8 编码为字节序列，保留换行符等控制字符。
fn string_to_utf8_bytes(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for char in s {
    let code = char.to_uint()
    if code < 0x80 {
      arr.push(code.to_byte())
    } else if code < 0x800 {
      arr.push((((code >> 6) & 0x1F) | 0xC0).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    } else if code < 0x10000 {
      arr.push((((code >> 12) & 0x0F) | 0xE0).to_byte())
      arr.push((((code >> 6) & 0x3F) | 0x80).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    } else {
      arr.push((((code >> 18) & 0x07) | 0xF0).to_byte())
      arr.push((((code >> 12) & 0x3F) | 0x80).to_byte())
      arr.push((((code >> 6) & 0x3F) | 0x80).to_byte())
      arr.push(((code & 0x3F) | 0x80).to_byte())
    }
  }
  Bytes::from_array(arr)
}
