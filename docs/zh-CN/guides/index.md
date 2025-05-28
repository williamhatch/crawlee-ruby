# Crawlee Ruby 指南

本节包含了使用 Crawlee Ruby 的详细指南和最佳实践，帮助您充分利用这个强大的爬虫框架。

## 目录

- [入门指南](./getting-started.md)
- [避免网站封锁](./avoiding-blocking.md)
- [会话管理](./session-management.md)
- [代理配置](./proxy-configuration.md)
- [数据存储](./data-storage.md)
- [错误处理](./error-handling.md)
- [性能优化](./performance-optimization.md)
- [部署最佳实践](./deployment.md)

## 入门指南

### 安装

Crawlee Ruby 可以通过 RubyGems 安装：

```bash
gem install crawlee
```

或者在您的 Gemfile 中添加：

```ruby
gem 'crawlee'
```

然后运行：

```bash
bundle install
```

### 基本配置

Crawlee Ruby 提供了一个全局配置对象，您可以通过它设置爬虫的行为：

```ruby
require 'crawlee'

Crawlee.configure do |config|
  # 设置最大并发请求数
  config.max_concurrency = 10
  
  # 设置请求超时时间（秒）
  config.request_timeout = 30
  
  # 设置最大重试次数
  config.max_retries = 3
  
  # 设置日志级别
  config.log_level = :info
  
  # 设置存储目录
  config.storage_dir = "./storage"
  
  # 配置代理
  config.configure_proxy(
    ['http://proxy1.example.com:8080', 'http://proxy2.example.com:8080'],
    rotation: :round_robin
  )
end
```

### 创建爬虫

Crawlee Ruby 提供了几种类型的爬虫，适用于不同的场景：

#### HTTP 爬虫

HTTP 爬虫使用 HTTP 请求直接获取网页内容，适用于不需要 JavaScript 渲染的网站：

```ruby
crawler = Crawlee::Crawlers::HttpCrawler.new
```

#### 浏览器爬虫

浏览器爬虫使用真实浏览器（通过 Ferrum）获取网页内容，适用于需要 JavaScript 渲染的网站：

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new
```

#### 自适应爬虫

自适应爬虫可以根据需要在 HTTP 和浏览器模式之间切换，优化性能和资源使用：

```ruby
crawler = Crawlee::Crawlers::AdaptiveCrawler.new
```

### 添加路由处理器

路由处理器用于处理爬取到的页面：

```ruby
# 添加特定 URL 模式的处理器
crawler.router.add(/product/) do |context|
  # 处理产品页面
  name = context.query_selector('.product-name')&.text
  price = context.query_selector('.product-price')&.text
  
  context.save_data({
    url: context.request.url,
    name: name,
    price: price
  })
end

# 添加默认处理器
crawler.router.default do |context|
  # 处理所有其他页面
  title = context.query_selector('title')&.text
  
  # 提取并跟踪链接
  context.enqueue_links('a')
end
```

### 启动爬虫

添加起始 URL 并运行爬虫：

```ruby
# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

## 下一步

请查看其他指南，了解 Crawlee Ruby 的更多高级功能和最佳实践。
