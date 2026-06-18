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
  [
    {
      name: "be-read",
      description: "Read file content with line numbers.",
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
      description: "Replace a precise line range in a file.",
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
      description: "Insert content after a specific line.",
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
      description: "Delete a line range from a file.",
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
      description: "Write raw content to file(s).",
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
      description: "Find the enclosing function or brace block for a given line.",
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
      description: "Find the enclosing XML/HTML/Vue tag pair for a given line.",
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
      description: "Check bracket, brace, parenthesis, tag, and quote balance.",
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
      description: "Insert content from a file (file://) or chip cache (chip://). Omit from to list all chip IDs.",
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
      description: "Commit all pending edit snapshots (clear the queue).",
      inputSchema: { "type": "object", "properties": {} },
    },
  ]
}
