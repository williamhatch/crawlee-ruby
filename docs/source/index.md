# Crawlee Ruby 文档

欢迎使用 Crawlee Ruby 文档！Crawlee Ruby 是一个强大的网页爬虫框架，专为 Ruby 开发者设计，提供了简洁而强大的 API 来构建可靠的网页爬虫。

## 特点

- **简单易用**：简洁的 API 设计，让爬虫开发变得简单
- **高性能**：支持并发请求，提高爬取效率
- **灵活强大**：支持 HTTP 和浏览器爬虫，满足不同需求
- **可扩展**：模块化设计，易于扩展和定制
- **稳定可靠**：完善的错误处理和重试机制，确保爬虫稳定运行

## 快速开始

### 安装

```bash
gem install crawlee
```

或者在 Gemfile 中添加：

```ruby
gem 'crawlee', '~> 0.2.0'
```

然后运行：

```bash
bundle install
```

### 基本示例

```ruby
require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2  # 设置最大并发请求数
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 获取页面标题
  title = context.query_selector('title')&.text
  puts "页面标题: #{title}"
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title
  })
  
  # 提取并跟踪链接
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

## 文档结构

- [**API 参考**](api/index.md)：详细的 API 文档
  - [BaseCrawler](api/base_crawler.md)：所有爬虫的基类
  - [HttpCrawler](api/http_crawler.md)：用于 HTTP 请求的爬虫
  - [BrowserCrawler](api/browser_crawler.md)：基于浏览器的爬虫
  - [Request](api/request.md)：表示一个 HTTP 请求
  - [Response](api/response.md)：表示一个 HTTP 响应
  - [Storage](api/storage.md)：存储系统

- [**示例**](examples/index.md)：各种爬虫示例
  - [基础 HTTP 爬虫](examples/basic_http_crawler.md)
  - [电子商务爬虫](examples/ecommerce_crawler.md)
  - [新闻爬虫](examples/news_crawler.md)
  - [知乎话题爬虫](examples/zhihu_topic_crawler.md)
  - [微博热搜爬虫](examples/weibo_hot_search_crawler.md)
  - [京东产品爬虫](examples/jd_product_crawler.md)

- [**指南**](guides/index.md)：使用指南和最佳实践
  - [高级爬虫技巧](guides/advanced_crawling.md)
  - [处理动态内容](guides/handling_dynamic_content.md)
  - [代理和反爬虫](guides/proxies_and_anti_scraping.md)
  - [数据存储和导出](guides/data_storage_and_export.md)

- [**教程**](tutorials/index.md)：从零开始的教程
  - [入门教程](tutorials/getting_started.md)
  - [构建你的第一个爬虫](tutorials/building_your_first_crawler.md)
  - [处理表单和登录](tutorials/handling_forms_and_login.md)

## 与 Crawlee Python 的比较

Crawlee Ruby 相比 Crawlee Python 有以下优势：

1. **更简洁的语法**：利用 Ruby 语言的优雅特性，使代码更加简洁易读
2. **更强大的 DSL**：提供更直观的领域特定语言，让爬虫开发更加自然
3. **更好的集成**：与 Ruby 生态系统无缝集成，支持各种 Ruby 库和框架
4. **更高的性能**：优化的实现，提供更高的爬取效率
5. **更易于扩展**：模块化设计，使扩展和定制变得简单

## 贡献

欢迎贡献代码、报告问题或提出改进建议！请查看 [贡献指南](guides/contributing.md) 了解更多信息。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](../LICENSE) 文件。
