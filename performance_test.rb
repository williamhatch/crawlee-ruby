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
