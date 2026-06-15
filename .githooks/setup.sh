#!/bin/bash
# 启用项目自带的 Git hooks

echo "🔧 配置 MoonBit Git hooks..."

git config core.hooksPath .githooks
chmod +x .githooks/*

echo "✅ Git hooks 配置成功！"
echo ""
echo "📝 当前激活的 hooks："
echo "   - pre-commit: 提交前运行 moon fmt && moon info"
echo ""
echo "💡 临时跳过时使用: git commit --no-verify"
