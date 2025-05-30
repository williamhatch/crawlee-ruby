#!/bin/bash

# 确保 SimpleCov 依赖已安装
bundle install

# 清理旧的覆盖率报告
rm -rf coverage

# 运行测试并生成覆盖率报告
COVERAGE=true bundle exec rspec

# 显示覆盖率摘要
echo "测试覆盖率报告已生成在 coverage 目录中"
echo "可以打开 coverage/index.html 查看详细报告"

# 更新 README.md 中的覆盖率徽章
coverage_percent=$(grep "Line Coverage" coverage/index.html | sed -E 's/.*>([0-9.]+)%<.*/\1/')
if [ -n "$coverage_percent" ]; then
  echo "当前测试覆盖率: $coverage_percent%"
  # 更新 README.md 中的覆盖率徽章
  sed -i '' "s/coverage-[0-9.]\+%/coverage-${coverage_percent}%/" README.md
fi
