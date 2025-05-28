# Crawlee Ruby 示例

本节提供了各种使用 Crawlee Ruby 的代码示例，帮助您快速上手并了解如何在不同场景中使用这个强大的爬虫框架。

## 基础示例

- [基本 HTTP 爬虫](./basic-http-crawler.md) - 使用 HTTP 爬虫爬取网页
- [基本浏览器爬虫](./basic-browser-crawler.md) - 使用浏览器爬虫爬取需要 JavaScript 渲染的网页
- [自适应爬虫](./adaptive-crawler.md) - 使用自适应爬虫自动在 HTTP 和浏览器模式之间切换

## 高级示例

- [代理轮换](./proxy-rotation.md) - 使用代理轮换避免 IP 封锁
- [会话管理](./session-management.md) - 使用会话池管理 Cookie 和会话状态
- [指纹生成](./fingerprint-generation.md) - 使用指纹生成器模拟真实浏览器
- [数据存储](./data-storage.md) - 使用不同的存储选项保存爬取数据

## 实际应用场景

- [电子商务网站爬虫](./ecommerce-crawler.md) - 爬取电子商务网站的产品信息
- [新闻网站爬虫](./news-crawler.md) - 爬取新闻网站的文章内容
- [社交媒体爬虫](./social-media-crawler.md) - 爬取社交媒体平台的公开内容
- [API 爬虫](./api-crawler.md) - 爬取 API 接口数据

## 基本 HTTP 爬虫示例

下面是一个基本的 HTTP 爬虫示例，用于爬取网页标题和链接：

```ruby
require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 5
  config.request_timeout = 30
  config.max_retries = 3
  config.log_level = :info
end

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加默认路由处理器
crawler.router.default_handler do |context|
  puts "正在处理: #{context.request.url}"
  
  # 提取标题
  title = context.query_selector('title')&.text
  puts "页面标题: #{title}"
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    crawled_at: Time.now.to_s
  })
  
  # 提取并跟踪所有链接
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
stats = crawler.run

# 打印统计信息
puts "爬虫统计信息:"
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"
puts "重试请求数: #{stats[:requests_retried]}"
```

## 电子商务网站爬虫示例

下面是一个更复杂的示例，用于爬取电子商务网站的产品信息：

```ruby
require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 10
  config.request_timeout = 30
  config.max_retries = 3
  
  # 配置代理
  config.configure_proxy(
    ['http://proxy1.example.com:8080', 'http://proxy2.example.com:8080'],
    rotation: :round_robin
  )
end

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加产品列表页面处理器
crawler.router.add(/\/category\//) do |context|
  puts "正在处理产品列表页面: #{context.request.url}"
  
  # 提取产品链接
  product_links = context.query_selector_all('.product-item a').map do |element|
    element['href']
  end
  
  # 添加产品链接到队列
  context.enqueue_links(product_links)
  
  # 提取并跟踪分页链接
  context.enqueue_links('.pagination a')
end

# 添加产品详情页面处理器
crawler.router.add(/\/product\//) do |context|
  puts "正在处理产品详情页面: #{context.request.url}"
  
  # 提取产品信息
  name = context.query_selector('.product-name')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  description = context.query_selector('.product-description')&.text&.strip
  image_url = context.query_selector('.product-image img')&.[]('src')
  
  # 保存产品数据
  context.save_data({
    url: context.request.url,
    name: name,
    price: price,
    description: description,
    image_url: image_url,
    crawled_at: Time.now.to_s
  })
end

# 添加默认处理器
crawler.router.default_handler do |context|
  puts "正在处理其他页面: #{context.request.url}"
  
  # 提取并跟踪所有链接
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example-shop.com')

# 运行爬虫
crawler.run
```

## 更多示例

请查看各个示例页面，了解更多详细的使用场景和代码示例。
