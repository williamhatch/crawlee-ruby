#!/bin/bash
# Crawlee Ruby Test Script
# Run test cases and execute crawler examples

# 设置超时时间（秒）
TIMEOUT=120  # 增加超时时间到 2 分钟

# 初始化进程 ID 数组
declare -a process_pids=()

# 添加信号处理
cleanup() {
  echo -e "\n\n收到中断信号，正在清理并退出..."
  
  # 结束所有跟踪的后台进程
  for pid in "${process_pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null
    fi
  done
  
  # 结束所有子进程
  pkill -P $$
  
  echo -e "${GREEN}清理完成，已安全退出${NC}"
  exit 1
}

# 注册信号处理程序
trap cleanup INT TERM

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 调试函数
debug_log() {
  echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 错误处理函数
handle_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  echo "错误详情已记录到 logs/error.log"
  echo "$1" >> logs/error.log
  return 1
}

# 带超时的命令执行函数
run_with_timeout() {
  local cmd="$1"
  local timeout_seconds="$2"
  local description="$3"
  
  echo -e "${YELLOW}执行命令：${NC} $cmd"
  echo -e "${YELLOW}超时设置：${NC} $timeout_seconds 秒"
  
  # 创建临时文件存储输出
  local temp_file=$(mktemp)
  
  # 使用 timeout 命令运行，并捕获输出
  # 使用 tee 实时显示输出，同时保存到文件
  (timeout $timeout_seconds bash -c "$cmd" 2>&1 | tee "$temp_file"; exit ${PIPESTATUS[0]}) &
  local pid=$!
  
  # 添加这个进程到进程组，以便于清理
  process_pids+=($pid)
  
  # 等待命令完成
  wait $pid
  local exit_code=$?
  
  # 检查是否超时
  if [ $exit_code -eq 124 ]; then
    handle_error "$description 执行超时（超过 $timeout_seconds 秒）"
    return 1
  elif [ $exit_code -eq 130 ]; then
    echo -e "\n${YELLOW}命令被用户中断${NC}"
    cleanup
  elif [ $exit_code -ne 0 ]; then
    handle_error "$description 执行失败，退出码: $exit_code"
    return $exit_code
  fi
  
  # 清理临时文件
  rm -f "$temp_file"
  return 0
}

echo -e "${YELLOW}Crawlee Ruby 测试脚本${NC}"
echo "=============================="
debug_log "脚本开始执行时间: $(date)"

# 创建日志和数据目录
mkdir -p logs
mkdir -p json
debug_log "创建了 logs 和 json 目录"

# 0. 安装依赖
echo -e "\n${YELLOW}0. 安装必要的依赖${NC}"
echo "------------------------------"

# 检查 Ruby 版本
ruby_version=$(ruby -v)
echo -e "${BLUE}当前 Ruby 版本:${NC} $ruby_version"

# 如果不是 Ruby 3.x，尝试使用 RVM 切换
debug_log "检查并切换到 Ruby 3.2.2"
if [[ ! "$ruby_version" =~ "3." ]]; then
  echo -e "${YELLOW}当前不是 Ruby 3.x，尝试切换到 Ruby 3.2.2${NC}"
  
  # 检查 RVM 是否可用
  if command -v rvm &> /dev/null; then
    echo -e "${GREEN}RVM 可用，切换到 Ruby 3.2.2${NC}"
    source "$HOME/.rvm/scripts/rvm" || source /usr/local/rvm/scripts/rvm
    rvm use 3.2.2
    
    # 再次检查 Ruby 版本
    ruby_version=$(ruby -v)
    echo -e "${BLUE}切换后的 Ruby 版本:${NC} $ruby_version"
  else
    echo -e "${RED}RVM 不可用，将使用当前 Ruby 版本${NC}"
    echo -e "${YELLOW}警告: 项目可能需要 Ruby 3.x${NC}"
  fi
fi

# 检查并安装必要的依赖
debug_log "检查并安装必要的 gem 依赖"

# 检查 bundler 是否已安装
if gem list -i bundler -v 2.6.9 > /dev/null 2>&1; then
  echo -e "${GREEN}bundler 2.6.9 已经安装，跳过安装步骤${NC}"
else
  echo -e "${YELLOW}安装 bundler 2.6.9...${NC}"
  run_with_timeout "gem install bundler -v 2.6.9 --no-document" $TIMEOUT "安装 bundler"
fi

# 检查并安装其他依赖
echo -e "${YELLOW}检查并安装其他依赖...${NC}"

# 定义需要安装的 gem 列表
gems_to_install=()

for gem_name in addressable nokogiri httparty ferrum concurrent-ruby faker; do
  if ! gem list -i "$gem_name" > /dev/null 2>&1; then
    gems_to_install+=("$gem_name")
  else
    echo -e "${GREEN}$gem_name 已经安装，跳过安装步骤${NC}"
  fi
done

# 如果有需要安装的 gem，则安装它们
if [ ${#gems_to_install[@]} -gt 0 ]; then
  echo -e "${YELLOW}安装以下 gem: ${gems_to_install[*]}${NC}"
  run_with_timeout "gem install ${gems_to_install[*]} --no-document" $TIMEOUT "安装依赖 gem"
else
  echo -e "${GREEN}所有依赖 gem 已经安装${NC}"
fi

# 安装 bundle 依赖
echo -e "${YELLOW}安装 bundle 依赖...${NC}"
debug_log "运行 bundle install 确保所有依赖安装完成"
run_with_timeout "bundle install" $TIMEOUT "安装 bundle 依赖"

# 0.1 构建和安装本地 gem
echo -e "\n${YELLOW}0.1 构建和安装本地 gem${NC}"
echo "------------------------------"
debug_log "检查本地 gem 状态"

# 获取当前版本
version=$(grep -E "VERSION\s*=" lib/crawlee/version.rb | cut -d '"' -f 2)
echo -e "${BLUE}当前 Crawlee 版本: ${NC}$version"

# 检查是否有代码变更
if [ -f "crawlee-$version.gem" ]; then
  gem_time=$(stat -f "%m" "crawlee-$version.gem")
  code_time=$(find lib -type f -name "*.rb" -exec stat -f "%m" {} \; | sort -nr | head -1)
  
  if [ $code_time -gt $gem_time ]; then
    echo -e "${YELLOW}检测到代码变更，重新构建 gem${NC}"
    need_rebuild=true
  else
    echo -e "${GREEN}没有代码变更，使用现有 gem${NC}"
    need_rebuild=false
  fi
else
  echo -e "${YELLOW}未找到现有 gem，需要构建${NC}"
  need_rebuild=true
fi

# 构建 gem
if [ "$need_rebuild" = true ]; then
  debug_log "开始构建本地 gem"
  run_with_timeout "gem build crawlee.gemspec" $TIMEOUT "构建 crawlee gem"
fi

# 检查是否已安装相同版本
if gem list -i crawlee -v "$version" > /dev/null 2>&1; then
  if [ "$need_rebuild" = true ]; then
    echo -e "${YELLOW}crawlee $version 已安装，但代码有变更，重新安装${NC}"
    run_with_timeout "gem install ./crawlee-$version.gem --no-document --force" $TIMEOUT "安装 crawlee gem"
  else
    echo -e "${GREEN}crawlee $version 已经安装，跳过安装步骤${NC}"
  fi
else
  echo -e "${YELLOW}安装 crawlee $version...${NC}"
  run_with_timeout "gem install ./crawlee-$version.gem --no-document --force" $TIMEOUT "安装 crawlee gem"
fi

# 1. 运行 RSpec 测试
echo -e "\n${YELLOW}1. 运行 RSpec 测试${NC}"
echo "------------------------------"
debug_log "开始运行 RSpec 测试"

run_with_timeout "bundle exec rspec 2>&1 | tee logs/rspec_tests.log" $TIMEOUT "运行 RSpec 测试"
rspec_status=$?

if [ $rspec_status -eq 0 ]; then
  echo -e "${GREEN}✓ 所有测试通过${NC}"
  debug_log "RSpec 测试全部通过"
else
  echo -e "${RED}✗ 测试失败，请检查日志${NC}"
  debug_log "RSpec 测试失败，退出码: $rspec_status"
fi

# 2. 运行基本 HTTP 爬虫示例
echo -e "\n${YELLOW}2. 运行基本 HTTP 爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行基本 HTTP 爬虫示例"

run_with_timeout "ruby examples/basic_http_crawler.rb 2>&1 | tee logs/basic_http_crawler.log" $TIMEOUT "运行基本 HTTP 爬虫示例"
http_status=$?

if [ $http_status -eq 0 ]; then
  debug_log "基本 HTTP 爬虫示例运行成功"
else
  debug_log "基本 HTTP 爬虫示例运行失败，退出码: $http_status"
fi

# 3. 运行浏览器爬虫示例
echo -e "\n${YELLOW}3. 运行浏览器爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行浏览器爬虫示例"

run_with_timeout "ruby examples/browser_crawler_example.rb 2>&1 | tee logs/browser_crawler.log" $TIMEOUT "运行浏览器爬虫示例"
browser_status=$?

if [ $browser_status -eq 0 ]; then
  debug_log "浏览器爬虫示例运行成功"
else
  debug_log "浏览器爬虫示例运行失败，退出码: $browser_status"
fi

# 4. 运行自适应爬虫示例
echo -e "\n${YELLOW}4. 运行自适应爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行自适应爬虫示例"

run_with_timeout "ruby examples/adaptive_crawler_example.rb 2>&1 | tee logs/adaptive_crawler.log" $TIMEOUT "运行自适应爬虫示例"
adaptive_status=$?

if [ $adaptive_status -eq 0 ]; then
  debug_log "自适应爬虫示例运行成功"
else
  debug_log "自适应爬虫示例运行失败，退出码: $adaptive_status"
fi

# 5. 运行 Cursor 定价页面爬虫
echo -e "\n${YELLOW}5. 抓取 Cursor 定价页面数据${NC}"
echo "------------------------------"
debug_log "开始运行 Cursor 定价页面爬虫"

run_with_timeout "ruby examples/cursor_pricing_crawler.rb 2>&1 | tee logs/cursor_pricing_crawler.log" $((TIMEOUT * 2)) "运行 Cursor 定价页面爬虫"
cursor_status=$?

if [ $cursor_status -eq 0 ]; then
  debug_log "Cursor 定价页面爬虫运行成功"
else
  debug_log "Cursor 定价页面爬虫运行失败，退出码: $cursor_status"
fi

# 6. 运行电子商务爬虫示例
echo -e "\n${YELLOW}6. 运行电子商务爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行电子商务爬虫示例"

run_with_timeout "ruby examples/ecommerce_crawler.rb 2>&1 | tee logs/ecommerce_crawler.log" $TIMEOUT "运行电子商务爬虫示例"
ecommerce_status=$?

if [ $ecommerce_status -eq 0 ]; then
  debug_log "电子商务爬虫示例运行成功"
else
  debug_log "电子商务爬虫示例运行失败，退出码: $ecommerce_status"
fi

# 7. 运行新闻爬虫示例
echo -e "\n${YELLOW}7. 运行新闻爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行新闻爬虫示例"

run_with_timeout "ruby examples/news_crawler.rb 2>&1 | tee logs/news_crawler.log" $TIMEOUT "运行新闻爬虫示例"
news_status=$?

if [ $news_status -eq 0 ]; then
  debug_log "新闻爬虫示例运行成功"
else
  debug_log "新闻爬虫示例运行失败，退出码: $news_status"
fi

# 8. 运行微博热搜爬虫示例
echo -e "\n${YELLOW}8. 运行微博热搜爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行微博热搜爬虫示例"

run_with_timeout "ruby examples/weibo_hot_search_crawler.rb 2>&1 | tee logs/weibo_hot_search_crawler.log" $((TIMEOUT * 2)) "运行微博热搜爬虫示例"
weibo_status=$?

if [ $weibo_status -eq 0 ]; then
  debug_log "微博热搜爬虫示例运行成功"
else
  debug_log "微博热搜爬虫示例运行失败，退出码: $weibo_status"
fi

# 9. 运行京东产品爬虫示例
echo -e "\n${YELLOW}9. 运行京东产品爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行京东产品爬虫示例"

run_with_timeout "ruby examples/jd_product_crawler.rb 2>&1 | tee logs/jd_product_crawler.log" $((TIMEOUT * 2)) "运行京东产品爬虫示例"
jd_status=$?

if [ $jd_status -eq 0 ]; then
  debug_log "京东产品爬虫示例运行成功"
else
  debug_log "京东产品爬虫示例运行失败，退出码: $jd_status"
fi

# 10. 运行知乎话题爬虫示例
echo -e "\n${YELLOW}10. 运行知乎话题爬虫示例${NC}"
echo "------------------------------"
debug_log "开始运行知乎话题爬虫示例"

run_with_timeout "ruby examples/zhihu_topic_crawler.rb 2>&1 | tee logs/zhihu_topic_crawler.log" $((TIMEOUT * 2)) "运行知乎话题爬虫示例"
zhihu_status=$?

if [ $zhihu_status -eq 0 ]; then
  debug_log "知乎话题爬虫示例运行成功"
else
  debug_log "知乎话题爬虫示例运行失败，退出码: $zhihu_status"
fi

# 11. 性能测试
echo -e "\n${YELLOW}11. 运行性能测试${NC}"
echo "------------------------------"
debug_log "开始运行性能测试"

# 创建性能测试脚本
cat > performance_test.rb << 'EOL'
# frozen_string_literal: true

require 'crawlee'
require 'benchmark'
require 'json'

# 性能测试配置
CONCURRENCY_LEVELS = [1, 2, 5, 10]
REQUEST_COUNTS = [10, 50, 100]
TEST_URL = 'https://example.com'

# 结果存储
results = []

# 测试 HTTP 爬虫性能
puts "\n测试 HTTP 爬虫性能..."
CONCURRENCY_LEVELS.each do |concurrency|
  REQUEST_COUNTS.each do |count|
    puts "\n测试并发数: #{concurrency}, 请求数: #{count}"
    
    # 创建爬虫
    crawler = Crawlee::Crawlers::HttpCrawler.new(
      max_concurrency: concurrency
    )
    
    # 设置路由处理器
    crawler.router.default_handler do |context|
      # 简单处理，只获取标题
      title = context.query_selector('title')&.text
      context.save_data({
        url: context.request.url,
        title: title
      })
    end
    
    # 添加请求
    count.times do |i|
      crawler.enqueue("#{TEST_URL}?id=#{i}")
    end
    
    # 测量性能
    time = Benchmark.realtime do
      crawler.run
    end
    
    # 记录结果
    results << {
      crawler_type: 'HttpCrawler',
      concurrency: concurrency,
      request_count: count,
      time_seconds: time.round(2),
      requests_per_second: (count / time).round(2)
    }
    
    puts "完成时间: #{time.round(2)} 秒"
    puts "每秒请求数: #{(count / time).round(2)}"
  end
 end

# 保存结果
File.open('performance_results.json', 'w') do |file|
  file.write(JSON.pretty_generate(results))
end

puts "\n性能测试完成，结果已保存到 performance_results.json"
EOL

# 运行性能测试
run_with_timeout "ruby performance_test.rb 2>&1 | tee logs/performance_test.log" $((TIMEOUT * 3)) "运行性能测试"
performance_status=$?

if [ $performance_status -eq 0 ]; then
  debug_log "性能测试运行成功"
  
  # 分析性能测试结果
  if [ -f "performance_results.json" ]; then
    echo -e "\n${YELLOW}性能测试结果摘要${NC}"
    echo "------------------------------"
    
    # 使用 Ruby 解析并显示结果摘要
    ruby -rjson -e '
      results = JSON.parse(File.read("performance_results.json"))
      puts "最佳性能配置:"
      best = results.max_by { |r| r["requests_per_second"] }
      puts "  并发数: #{best["concurrency"]}"
      puts "  请求数: #{best["request_count"]}"
      puts "  每秒请求数: #{best["requests_per_second"]}"
      
      puts "\n性能对比:"
      results.group_by { |r| r["concurrency"] }.each do |concurrency, group|
        puts "  并发数 #{concurrency}:"
        group.each do |r|
          puts "    请求数 #{r["request_count"]}: #{r["requests_per_second"]} 请求/秒"
        end
      end
    '
  else
    echo -e "${RED}未找到性能测试结果文件${NC}"
  fi
else
  debug_log "性能测试运行失败，退出码: $performance_status"
fi

# 总结测试结果
echo -e "\n${YELLOW}测试结果摘要${NC}"
echo "------------------------------"
echo -e "RSpec 测试: $([ $rspec_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")" 
echo -e "基本 HTTP 爬虫: $([ $http_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "浏览器爬虫: $([ $browser_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "自适应爬虫: $([ $adaptive_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "Cursor 定价页面爬虫: $([ $cursor_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "电子商务爬虫: $([ $ecommerce_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "新闻爬虫: $([ $news_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "微博热搜爬虫: $([ $weibo_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "京东产品爬虫: $([ $jd_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "知乎话题爬虫: $([ $zhihu_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"
echo -e "性能测试: $([ $performance_status -eq 0 ] && echo -e "${GREEN}通过${NC}" || echo -e "${RED}失败${NC}")"

echo -e "\n${GREEN}测试完成！${NC}"
debug_log "测试脚本执行结束时间: $(date)"
echo "所有日志文件保存在 logs 目录中"
echo "抓取的数据保存在 json 目录中"
echo "性能测试结果保存在 performance_results.json 文件中"

