# frozen_string_literal: true

require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 2  # 浏览器爬虫通常需要更多资源，所以降低并发数
  config.request_timeout = 60 # 增加超时时间，因为浏览器加载可能较慢
  config.max_retries = 3
  config.log_level = :info
  
  # 可选：配置代理
  # config.configure_proxy(
  #   ['http://proxy1.example.com:8080', 'http://proxy2.example.com:8080'],
  #   rotation: :round_robin
  # )
end

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  browser_options: {
    # Ferrum 浏览器选项
    headless: true,           # 无头模式
    window_size: [1366, 768], # 窗口大小
    timeout: 60,              # 浏览器操作超时时间
    # 其他 Ferrum 选项...
  }
)

# 添加默认路由处理器
crawler.router.default_handler do |context|
  puts "正在处理: #{context.request.url}"
  
  # 提取标题
  title = context.query_selector('title')&.text
  puts "页面标题: #{title}"
  
  # 提取所有链接
  links = context.query_selector_all('a').map do |element|
    href = element['href']
    text = element.text.strip
    { url: href, text: text }
  end
  
  puts "找到 #{links.size} 个链接"
  
  # 提取页面上的所有图片
  images = context.query_selector_all('img').map do |element|
    {
      src: element['src'],
      alt: element['alt'],
      width: element['width'],
      height: element['height']
    }
  end
  
  puts "找到 #{images.size} 张图片"
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    links: links.first(5), # 只保存前 5 个链接
    images: images.first(5), # 只保存前 5 张图片
    crawled_at: Time.now.to_s
  })
  
  # 只跟踪同一域名下的链接，最多 3 个（浏览器爬虫更耗资源）
  same_domain_links = links.select do |link|
    link[:url] && URI.parse(context.request.url).host == URI.parse(link[:url]).host rescue false
  end
  
  context.enqueue_links(same_domain_links.map { |link| link[:url] }.first(3))
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
puts "开始爬取..."
stats = crawler.run
puts "爬取完成!"

# 打印统计信息
puts "\n爬虫统计信息:"
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"
puts "重试请求数: #{stats[:requests_retried]}"
