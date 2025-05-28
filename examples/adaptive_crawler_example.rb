# frozen_string_literal: true

require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 5
  config.request_timeout = 45
  config.max_retries = 3
  config.log_level = :info
end

# 创建自适应爬虫
crawler = Crawlee::Crawlers::AdaptiveCrawler.new

# 预先设置一些已知需要浏览器的 URL 模式
crawler.add_browser_pattern(/\.js$/)  # JavaScript 文件
crawler.add_browser_pattern(/spa/)    # 单页应用
crawler.add_browser_pattern(/react/)  # React 应用
crawler.add_browser_pattern(/vue/)    # Vue 应用

# 预先设置一些已知只需要 HTTP 的 URL 模式
crawler.add_http_pattern(/\.xml$/)    # XML 文件
crawler.add_http_pattern(/\.txt$/)    # 文本文件
crawler.add_http_pattern(/sitemap/)   # 网站地图

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
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    links: links.first(5), # 只保存前 5 个链接
    has_javascript: !context.query_selector_all('script').empty?,
    crawled_at: Time.now.to_s
  })
  
  # 只跟踪同一域名下的链接，最多 5 个
  same_domain_links = links.select do |link|
    link[:url] && URI.parse(context.request.url).host == URI.parse(link[:url]).host rescue false
  end
  
  context.enqueue_links(same_domain_links.map { |link| link[:url] }.first(5))
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
