///|
/// 当前语言，有效值为 "zh" 或 "en"。
let current_lang : Ref[String] = { val: "en" }

///|
/// 已加载的翻译表缓存，language -> (key -> value)。
let translations : Ref[Map[String, Map[String, String]]] = {
  val: Map::default(),
}

///|
/// 从 `./i18n/{lang}.json` 加载翻译表。失败时返回空表。
fn load_language(lang : String) -> Map[String, String] {
  let path = "./i18n/" + lang + ".json"
  let text = @fs.read_file_to_string(path) catch { _ => return Map::default() }
  let json = @json.parse(text) catch { _ => return Map::default() }
  let result = Map::default()
  match json {
    Object(map) =>
      map.each(fn(k, v) {
        match v {
          String(s) => result.set(k, s)
          _ => ()
        }
      })
    _ => ()
  }
  result
}

///|
/// 获取指定语言的翻译表，优先使用缓存。
fn get_translation(lang : String) -> Map[String, String] {
  match translations.val.get(lang) {
    Some(map) => map
    None => {
      let map = load_language(lang)
      translations.val.set(lang, map)
      map
    }
  }
}

///|
/// 设置当前语言。有效值 "zh" 或 "en"，其他值按英文回退。
pub fn set_language(lang : String) -> Unit {
  current_lang.val = if lang == "zh" || lang == "en" { lang } else { "en" }
}

///|
/// 获取当前语言。
pub fn current_language() -> String {
  current_lang.val
}

///|
/// 根据 key 返回翻译文本。`lang` 省略时使用 current_language()。
/// 若对应语言文件不存在或 key 不存在，先回退到英文，再不存在则返回 key。
pub fn t(key : String, lang? : String) -> String {
  let effective_lang = match lang {
    Some(l) => l
    None => current_lang.val
  }
  let map = get_translation(effective_lang)
  match map.get(key) {
    Some(value) => value
    None => {
      let en_map = get_translation("en")
      match en_map.get(key) {
        Some(value) => value
        None => key
      }
    }
  }
}
