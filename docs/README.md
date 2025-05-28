# Crawlee Ruby 文档

Crawlee Ruby 是一个强大的网页爬虫框架，专为 Ruby 开发者设计，提供了简洁而强大的 API 来构建可靠的网页爬虫。

## 文档结构

- **API 参考**：[api/](source/api/) - 详细的 API 文档
- **示例**：[examples/](source/examples/) - 各种爬虫示例
- **指南**：[guides/](source/guides/) - 使用指南和最佳实践
- **教程**：[tutorials/](source/tutorials/) - 从零开始的教程

## 快速开始

```ruby
require 'crawlee'

# 创建一个 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 10,
  request_timeout: 30
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 获取页面标题
  title = context.query_selector('title')&.text
  
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

## 安装

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

## 贡献

欢迎贡献代码、报告问题或提出改进建议！请查看 [贡献指南](source/guides/contributing.md) 了解更多信息。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](../LICENSE) 文件。
