# Crawlee Ruby 教程

本节提供了一系列从零开始的教程，帮助您逐步学习如何使用 Crawlee Ruby 构建强大的爬虫应用。

## 入门教程

- [安装与配置](./installation.md) - 安装 Crawlee Ruby 并进行基本配置
- [第一个爬虫](./first-crawler.md) - 创建您的第一个爬虫应用
- [处理数据](./handling-data.md) - 提取和存储爬取的数据

## 基础教程

- [HTTP 爬虫详解](./http-crawler.md) - 深入了解 HTTP 爬虫的工作原理和用法
- [浏览器爬虫详解](./browser-crawler.md) - 学习如何使用浏览器爬虫处理 JavaScript 渲染的网页
- [路由系统](./routing-system.md) - 掌握 Crawlee Ruby 的路由系统
- [会话与 Cookie 管理](./session-management.md) - 学习如何管理会话和 Cookie

## 高级教程

- [代理配置与轮换](./proxy-configuration.md) - 配置和使用代理服务
- [指纹生成与反爬虫](./fingerprinting.md) - 使用指纹生成器避免网站封锁
- [并发与性能优化](./concurrency.md) - 优化爬虫性能和资源使用
- [错误处理与重试机制](./error-handling.md) - 实现健壮的错误处理和重试机制

## 实战教程

- [爬取电子商务网站](./ecommerce-scraping.md) - 构建一个完整的电子商务网站爬虫
- [新闻聚合器](./news-aggregator.md) - 创建一个新闻聚合爬虫
- [API 数据采集](./api-scraping.md) - 学习如何爬取 API 数据
- [定时任务与监控](./scheduling.md) - 设置定时爬取任务和监控系统

## 第一个爬虫教程

下面是一个简单的教程，指导您创建第一个 Crawlee Ruby 爬虫：

### 步骤 1: 安装 Crawlee Ruby

首先，确保您已经安装了 Ruby（推荐 2.7.0 或更高版本）。然后，安装 Crawlee Ruby gem：

```bash
gem install crawlee
```

### 步骤 2: 创建项目目录

创建一个新的项目目录：

```bash
mkdir my_first_crawler
cd my_first_crawler
```

### 步骤 3: 创建爬虫脚本

创建一个名为 `crawler.rb` 的文件，内容如下：

```ruby
require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 2  # 设置较低的并发数，适合初学者
  config.log_level = :info    # 显示详细日志
end

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加默认路由处理器
crawler.router.default_handler do |context|
  puts "正在处理: #{context.request.url}"
  
  # 提取页面标题
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
    links: links,
    crawled_at: Time.now.to_s
  })
  
  # 只跟踪同一域名下的链接
  same_domain_links = links.select do |link|
    link[:url] && URI.parse(link[:url]).host == URI.parse(context.request.url).host
  rescue URI::InvalidURIError
    false
  end
  
  # 将链接添加到队列（最多 5 个，避免爬取过多）
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
```

### 步骤 4: 运行爬虫

执行您的爬虫脚本：

```bash
ruby crawler.rb
```

您应该会看到爬虫开始工作，并在控制台输出处理的 URL、页面标题和找到的链接数量。

### 步骤 5: 查看结果

爬取完成后，您可以在 `./storage/datasets/default` 目录中找到保存的数据：

```bash
cat ./storage/datasets/default/data.json
```

这个文件包含了爬取到的所有页面数据，格式为 JSON。

### 下一步

恭喜！您已经成功创建并运行了第一个 Crawlee Ruby 爬虫。接下来，您可以：

1. 尝试修改爬虫代码，添加更多的数据提取逻辑
2. 学习如何使用浏览器爬虫处理 JavaScript 渲染的网页
3. 探索更高级的功能，如代理轮换、指纹生成等

请继续阅读其他教程，深入学习 Crawlee Ruby 的更多功能和用法。
