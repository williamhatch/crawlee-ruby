# 基础 HTTP 爬虫示例

本示例展示了如何使用 Crawlee Ruby 的 `HttpCrawler` 类创建一个简单的网页爬虫，抓取网页内容并保存数据。

## 完整代码

```ruby
# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2,  # 设置最大并发请求数
  request_timeout: 30  # 设置请求超时时间（秒）
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 获取请求和响应对象
  request = context.request
  response = context.response
  
  # 输出请求信息
  puts "正在处理: #{request.url}"
  
  # 解析 HTML
  if response.html?
    # 获取页面标题
    title = context.query_selector('title')&.text
    puts "页面标题: #{title}"
    
    # 获取所有链接
    links = context.query_selector_all('a').map { |a| a['href'] }.compact
    puts "找到 #{links.size} 个链接"
    
    # 保存数据
    context.save_data({
      url: request.url,
      title: title,
      links_count: links.size
    })
    
    # 提取并跟踪链接（最多 5 个）
    context.enqueue_links('a', {})
  end
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
puts "开始运行爬虫..."
stats = crawler.run
puts "爬虫运行完成"

# 输出统计信息
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"
puts "重试请求数: #{stats[:requests_retried]}"
```

## 代码解析

### 1. 创建爬虫实例

```ruby
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2,  # 设置最大并发请求数
  request_timeout: 30  # 设置请求超时时间（秒）
)
```

这里我们创建了一个 `HttpCrawler` 实例，设置最大并发请求数为 2，请求超时时间为 30 秒。

### 2. 设置路由处理器

```ruby
crawler.router.default_handler do |context|
  # 处理逻辑
end
```

路由处理器定义了如何处理每个请求和响应。`context` 对象包含了请求、响应和其他有用的方法。

### 3. 解析 HTML 和提取数据

```ruby
# 获取页面标题
title = context.query_selector('title')&.text

# 获取所有链接
links = context.query_selector_all('a').map { |a| a['href'] }.compact
```

使用 `query_selector` 和 `query_selector_all` 方法可以方便地从 HTML 中提取数据。

### 4. 保存数据

```ruby
context.save_data({
  url: request.url,
  title: title,
  links_count: links.size
})
```

使用 `save_data` 方法将提取的数据保存到数据集中。

### 5. 提取并跟踪链接

```ruby
context.enqueue_links('a', {})
```

使用 `enqueue_links` 方法可以提取页面中的链接并添加到请求队列中，实现爬虫的递归抓取。

### 6. 运行爬虫

```ruby
stats = crawler.run
```

调用 `run` 方法启动爬虫，处理队列中的所有请求，并返回统计信息。

## 运行结果

运行这个示例后，爬虫会从 `https://example.com` 开始，抓取页面内容，提取链接并继续抓取这些链接指向的页面。所有抓取的数据都会保存到默认的数据集中，可以在 `storage/datasets/default/data.json` 文件中找到。

```json
[
  {
    "url": "https://example.com",
    "title": "Example Domain",
    "links_count": 1,
    "id": "f8b2c9d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
    "createdAt": 1716913234
  },
  {
    "url": "https://www.iana.org/domains/example",
    "title": "IANA-managed Reserved Domains",
    "links_count": 10,
    "id": "7a8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d",
    "createdAt": 1716913235
  }
]
```
