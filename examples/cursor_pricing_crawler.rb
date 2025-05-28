#!/usr/bin/env ruby
# encoding: utf-8

# 使用本地编译的Crawlee库
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'crawlee'
require 'json'
require 'fileutils'

# 确保 JSON 目录存在
FileUtils.mkdir_p('json') unless Dir.exist?('json')

puts "开始抓取 Cursor 定价页面数据..."

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 1
  config.request_timeout = 60
  config.max_retries = 3
  config.log_level = :info
  
  # 设置用户代理
  config.default_headers = {
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'zh-CN,zh;q=0.9,en;q=0.8'
  }
end

# 清空请求队列
FileUtils.rm_rf("./storage/request_queues")
FileUtils.mkdir_p("./storage/request_queues")

# 初始化 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new({
  max_concurrency: 1,
  storage_dir: './storage',
  request_queue_name: 'cursor_pricing',
  dataset_name: 'cursor_pricing',
  max_request_retries: 3
})

# 配置路由处理
crawler.router.add(/.+/) do |context|
  puts "URL: #{context.request.url}"
  
  # 获取页面内容
  html = context.response.body
  
  # 提取定价信息
  pricing_data = {
    url: context.request.url,
    timestamp: Time.now.to_s,
    plans: []
  }
  
  # 获取页面文本
  page_text = html.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
  
  # 提取 Hobby 计划信息
  hobby_match = page_text.match(/Hobby[^$]*免费/i)
  if hobby_match
    pricing_data[:plans] << {
      name: "Hobby",
      price: "免费",
      features: hobby_match[0].strip
    }
  end
  
  # 提取 Pro 计划信息
  pro_match = page_text.match(/Pro[^$]*\$20/i)
  if pro_match
    pricing_data[:plans] << {
      name: "Pro",
      price: "$20",
      features: pro_match[0].strip
    }
  end
  
  # 提取 Business 计划信息
  business_match = page_text.match(/Business[^$]*\$40/i)
  if business_match
    pricing_data[:plans] << {
      name: "Business",
      price: "$40",
      features: business_match[0].strip
    }
  end
  
  # 保存提取的数据
  if pricing_data[:plans].any?
    puts "找到 #{pricing_data[:plans].size} 个计划信息"
    json_file = "json/cursor_pricing.json"
    File.write(json_file, JSON.pretty_generate(pricing_data))
    puts "数据已保存到: #{json_file}"
  else
    puts "未找到任何计划信息"
  end
end

# 添加起始 URL
url = 'https://www.cursor.com/cn/pricing'

# 创建请求对象
request = Crawlee::Request.new(url)

# 添加请求
crawler.enqueue(request)

# 运行爬虫
puts "开始运行爬虫..."
crawler.run

puts "爬虫运行完成"

# 检查生成的JSON文件
json_file = 'json/cursor_pricing.json'
if File.exist?(json_file)
  puts "成功生成JSON文件: #{json_file}"
else
  puts "警告: 未生成JSON文件"
end

puts "抓取完成！"
