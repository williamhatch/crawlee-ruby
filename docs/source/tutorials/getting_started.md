# Crawlee Ruby 入门教程

本教程将指导您从零开始使用 Crawlee Ruby 框架构建一个简单的网页爬虫。

## 安装

首先，安装 Crawlee Ruby gem：

```bash
gem install crawlee
```

或者，在您的 Gemfile 中添加：

```ruby
gem 'crawlee', '~> 0.2.0'
```

然后运行：

```bash
bundle install
```

## 创建第一个爬虫

让我们创建一个简单的爬虫，抓取一个网站的标题和链接。

### 步骤 1：创建项目目录

```bash
mkdir my_crawler
cd my_crawler
```

### 步骤 2：创建爬虫脚本

创建一个名为 `simple_crawler.rb` 的文件：

```ruby
# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2  # 设置最大并发请求数为 2
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 获取请求和响应对象
  request = context.request
  response = context.response
  
  puts "处理页面: #{request.url}"
  
  # 检查响应是否为 HTML
  if response.html?
    # 获取页面标题
    title = context.query_selector('title')&.text
    puts "页面标题: #{title}"
    
    # 保存数据
    context.save_data({
      url: request.url,
      title: title
    })
  end
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
puts "开始运行爬虫..."
crawler.run
puts "爬虫运行完成！"
```

### 步骤 3：运行爬虫

```bash
ruby simple_crawler.rb
```

您应该会看到类似以下的输出：

```
开始运行爬虫...
[2025-05-28 20:30:00] INFO: 开始运行爬虫，并发数: 2
处理页面: https://example.com
页面标题: Example Domain
[2025-05-28 20:30:01] INFO: 爬虫运行完成，处理请求数: 1
爬虫运行完成！
```

恭喜！您已经成功创建并运行了第一个 Crawlee Ruby 爬虫。

## 提取和跟踪链接

现在，让我们修改爬虫，使其能够提取页面中的链接并继续抓取这些链接指向的页面。

修改 `simple_crawler.rb` 文件：

```ruby
# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2  # 设置最大并发请求数为 2
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 获取请求和响应对象
  request = context.request
  response = context.response
  
  puts "处理页面: #{request.url}"
  
  # 检查响应是否为 HTML
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
    
    # 提取并跟踪链接
    context.enqueue_links('a')
  end
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
puts "开始运行爬虫..."
crawler.run
puts "爬虫运行完成！"
```

运行修改后的爬虫：

```bash
ruby simple_crawler.rb
```

现在，爬虫会从起始 URL 开始，提取页面中的链接，并继续抓取这些链接指向的页面。

## 查看抓取的数据

Crawlee Ruby 会自动将抓取的数据保存到默认的数据集中。您可以在 `storage/datasets/default/data.json` 文件中找到这些数据：

```bash
cat storage/datasets/default/data.json
```

输出可能类似于：

```json
[
  {
    "url": "https://example.com",
    "title": "Example Domain",
    "links_count": 1,
    "id": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6",
    "createdAt": 1716913234
  },
  {
    "url": "https://www.iana.org/domains/example",
    "title": "IANA-managed Reserved Domains",
    "links_count": 10,
    "id": "b2c3d4e5-f6g7-h8i9-j0k1-l2m3n4o5p6q7",
    "createdAt": 1716913235
  }
]
```

## 使用路由模式

Crawlee Ruby 允许您为不同的 URL 模式设置不同的处理器。这在抓取复杂网站时非常有用。

修改 `simple_crawler.rb` 文件：

```ruby
# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2  # 设置最大并发请求数为 2
)

# 主页处理器
crawler.router.add(/example\.com\/?$/) do |context|
  puts "处理主页: #{context.request.url}"
  
  # 获取页面标题
  title = context.query_selector('title')&.text
  puts "主页标题: #{title}"
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    type: 'homepage'
  })
  
  # 提取并跟踪链接
  context.enqueue_links('a')
end

# IANA 页面处理器
crawler.router.add(/iana\.org/) do |context|
  puts "处理 IANA 页面: #{context.request.url}"
  
  # 获取页面标题
  title = context.query_selector('title')&.text
  puts "IANA 页面标题: #{title}"
  
  # 获取所有段落文本
  paragraphs = context.query_selector_all('p').map { |p| p.text.strip }.compact
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    paragraphs: paragraphs,
    type: 'iana'
  })
end

# 默认处理器（处理其他所有 URL）
crawler.router.default_handler do |context|
  puts "处理其他页面: #{context.request.url}"
  
  # 获取页面标题
  title = context.query_selector('title')&.text
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    type: 'other'
  })
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
puts "开始运行爬虫..."
crawler.run
puts "爬虫运行完成！"
```

## 处理表单和 POST 请求

某些网站需要通过表单提交数据。以下是如何处理表单和 POST 请求的示例：

```ruby
# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加搜索表单提交
crawler.enqueue('https://example.com/search', {
  method: :post,
  payload: {
    query: 'crawlee ruby',
    page: 1
  },
  headers: {
    'Content-Type' => 'application/x-www-form-urlencoded'
  }
})

# 设置路由处理器
crawler.router.add(/\/search/) do |context|
  # 处理搜索结果页面
  results = context.query_selector_all('.search-result').map do |result|
    {
      title: result.at_css('.title')&.text&.strip,
      url: result.at_css('a')&.[]('href'),
      description: result.at_css('.description')&.text&.strip
    }
  end
  
  # 保存搜索结果
  results.each do |result|
    context.save_data(result)
  end
  
  # 检查是否有下一页
  next_page = context.query_selector('.pagination .next')
  if next_page && next_page['href']
    # 提取页码
    current_page = context.request.payload[:page] || 1
    
    # 添加下一页到队列
    crawler.enqueue('https://example.com/search', {
      method: :post,
      payload: {
        query: 'crawlee ruby',
        page: current_page + 1
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    })
  end
end
```

## 下一步

恭喜！您已经学会了如何使用 Crawlee Ruby 创建基本的网页爬虫。接下来，您可以：

1. 查看[示例](../examples/index.md)了解更多爬虫示例
2. 阅读[指南](../guides/index.md)学习高级爬虫技巧
3. 参考[API 文档](../api/index.md)了解详细的 API 信息

祝您爬虫愉快！
