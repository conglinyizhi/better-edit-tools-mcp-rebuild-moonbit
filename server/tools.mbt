///|
/// MCP 工具定义。
pub(all) struct Tool {
  name : String
  description : String
  inputSchema : Json
} derive(ToJson)

///|
/// 返回服务器支持的所有工具定义。
pub fn list_tools() -> Array[Tool] {
  let name = "be-read"
  [
    {
      name,
      description: @common.t("tool.description." + name),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "start": { "type": "integer", "minimum": 1 },
          "end": {
            "oneOf": [
              { "type": "integer" },
              { "type": "string", "enum": ["auto"] },
            ],
          },
          "preview": { "type": "boolean" },
          "brief": {
            "type": "boolean",
            "description": "return only metadata, no content",
          },
          "target": {
            "type": "object",
            "properties": {
              "kind": {
                "type": "string",
                "enum": ["line", "function", "marker", "tag"],
              },
              "value": { "type": "string" },
            },
          },
        },
        "required": ["file", "start"],
      },
    },
    {
      name: "be-replace",
      description: @common.t("tool.description.be-replace"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "start": { "type": "integer", "minimum": 1 },
          "end": { "type": "integer", "minimum": 1 },
          "start_line": { "type": "integer", "minimum": 1 },
          "end_line": { "type": "integer", "minimum": 1 },
          "old": { "type": "string" },
          "old_text": { "type": "string" },
          "content": { "type": "string" },
          "preview": { "type": "boolean" },
          "brief": {
            "type": "boolean",
            "description": "return minimal response (omit diff)",
          },
          "viewed_code_id": { "type": "string" },
          "target": {
            "type": "object",
            "properties": {
              "kind": {
                "type": "string",
                "enum": ["line", "function", "marker", "tag"],
              },
              "value": { "type": "string" },
            },
          },
        },
        "required": ["file", "start", "end"],
      },
    },
    {
      name: "be-insert",
      description: @common.t("tool.description.be-insert"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "after_line": { "type": "integer", "minimum": 0 },
          "content": { "type": "string" },
          "preview": { "type": "boolean" },
          "brief": {
            "type": "boolean",
            "description": "return minimal response (omit diff)",
          },
          "target": {
            "type": "object",
            "properties": {
              "kind": {
                "type": "string",
                "enum": ["line", "function", "marker", "tag"],
              },
              "value": { "type": "string" },
            },
          },
        },
        "required": ["file", "after_line", "content"],
      },
    },
    {
      name: "be-delete",
      description: @common.t("tool.description.be-delete"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "start": { "type": "integer", "minimum": 1 },
          "end": { "type": "integer", "minimum": 1 },
          "preview": { "type": "boolean" },
          "brief": {
            "type": "boolean",
            "description": "return minimal response (omit diff)",
          },
          "target": {
            "type": "object",
            "properties": {
              "kind": {
                "type": "string",
                "enum": ["line", "function", "marker", "tag"],
              },
              "value": { "type": "string" },
            },
          },
        },
      },
    },
    {
      name: "be-write",
      description: @common.t("tool.description.be-write"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "content": { "type": "string" },
          "files": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "file": { "type": "string" },
                "content": { "type": "string" },
              },
              "required": ["file", "content"],
            },
          },
          "preview": { "type": "boolean" },
          "brief": {
            "type": "boolean",
            "description": "return minimal response (omit per-file details)",
          },
        },
      },
    },
    {
      name: "be-func-range",
      description: @common.t("tool.description.be-func-range"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "line": { "type": "integer", "minimum": 1 },
        },
        "required": ["file", "line"],
      },
    },
    {
      name: "be-tag-range",
      description: @common.t("tool.description.be-tag-range"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "line": { "type": "integer", "minimum": 1 },
        },
        "required": ["file", "line"],
      },
    },
    {
      name: "be-balance",
      description: @common.t("tool.description.be-balance"),
      inputSchema: {
        "type": "object",
        "properties": {
          "file": { "type": "string" },
          "verbose": {
            "type": "boolean",
            "description": "false: show only unbalanced items; true: full report including matched pairs",
          },
        },
      },
    },
    {
      name: "be-insert-chip",
      description: @common.t("tool.description.be-insert-chip"),
      inputSchema: {
        "type": "object",
        "properties": {
          "from": {
            "type": "string",
            "description": "Source: file:///absolute/path or chip://{id}. Empty/omit to list all chip IDs.",
          },
          "to": {
            "type": "string",
            "description": "Target: file:///absolute/path:line_number",
          },
        },
      },
    },
    {
      name: "be-trx-commit",
      description: @common.t("tool.description.be-trx-commit"),
      inputSchema: { "type": "object", "properties": {} },
    },
  ]
}
