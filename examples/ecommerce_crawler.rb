# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 3,  # 设置最大并发请求数
  request_timeout: 30  # 设置请求超时时间（秒）
)

# 产品页面处理器
crawler.router.add(/\/product\//) do |context|
  puts "处理产品页面: #{context.request.url}"
  
  # 提取产品信息
  title = context.query_selector('h1.product-title')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  description = context.query_selector('.product-description')&.text&.strip
  
  # 提取产品图片
  images = context.query_selector_all('.product-image').map { |img| img['src'] }.compact
  
  # 提取产品规格
  specs = {}
  context.query_selector_all('.product-spec').each do |spec|
    key = spec.at_css('.spec-name')&.text&.strip
    value = spec.at_css('.spec-value')&.text&.strip
    specs[key] = value if key && value
  end
  
  # 保存产品数据
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    description: description,
    images: images,
    specs: specs,
    crawled_at: Time.now.to_i
  })
end

# 分类页面处理器
crawler.router.add(/\/category\//) do |context|
  puts "处理分类页面: #{context.request.url}"
  
  # 提取产品链接
  product_links = context.query_selector_all('a.product-link')
  puts "找到 #{product_links.size} 个产品"
  
  # 将产品链接添加到队列
  context.enqueue_links('a.product-link')
  
  # 查找下一页链接并添加到队列
  context.enqueue_links('a.next-page')
end

# 添加起始 URL
crawler.enqueue('https://shop.example.com/category/electronics')

# 运行爬虫
puts "开始运行爬虫..."
stats = crawler.run
puts "爬虫运行完成！"

# 输出统计信息
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"

# 导出数据为 JSON 文件
require 'json'

dataset = crawler.dataset
all_data = dataset.get_data

File.open('products.json', 'w') do |file|
  file.write(JSON.pretty_generate(all_data))
end

puts "已将 #{all_data.size} 个产品保存到 products.json"
