# Git Hooks

本项目使用 Git hooks 在提交前自动执行代码检查。

## 启用方式

```bash
./.githooks/setup.sh
```

或手动配置：

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

## pre-commit

提交前自动运行：

- `moon fmt`：统一代码格式
- `moon info`：生成 `.mbti` 接口文件

如果格式化或接口生成修改了文件，提交会被阻止，需要检查并重新暂存后再提交。

## 临时跳过

```bash
git commit --no-verify -m "your message"
```

不建议在常规提交中使用。

原文件来自 https://github.com/moonbitlang/core/tree/main/.githooks/* ，使用 Kimi 2.7 Code 进行翻译
