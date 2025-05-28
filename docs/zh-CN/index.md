# Crawlee Ruby 文档

欢迎使用 Crawlee Ruby 文档！Crawlee Ruby 是一个强大的网络爬虫和浏览器自动化库，旨在帮助您构建可靠、高效的爬虫应用。

## 什么是 Crawlee Ruby？

Crawlee Ruby 是 Crawlee 生态系统的 Ruby 实现版本，提供了一套完整的工具和 API，用于网络爬取、数据提取和浏览器自动化。它处理了许多复杂的问题，如网站封锁、代理轮换、会话管理等，让您可以专注于业务逻辑而不是技术细节。

## 主要特性

- **统一的 API** - 为 HTTP 和浏览器爬取提供统一的接口
- **自动并行爬取** - 基于可用系统资源自动调整并发度
- **反爬虫绕过** - 内置指纹生成和会话管理，有效模拟真实用户行为
- **请求路由** - 强大的路由系统，将 URL 定向到适当的处理程序
- **持久化存储** - 用于请求队列、数据集和键值存储的持久化解决方案
- **错误处理** - 自动重试和健壮的错误处理机制

## 快速入门

### 安装

```bash
gem install crawlee
```

或者在您的 Gemfile 中添加：

```ruby
gem 'crawlee'
```

### 基本用法

```ruby
require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 5
end

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加默认路由处理器
crawler.router.default_handler do |context|
  # 提取标题
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

## 文档导航

- [指南](./guides/index.md) - 详细的使用指南和最佳实践
- [API 参考](./api/index.md) - 完整的 API 文档
- [示例](./examples/index.md) - 各种使用场景的代码示例
- [教程](./tutorials/index.md) - 从零开始的教程

## 贡献

Crawlee Ruby 是一个开源项目，我们欢迎社区贡献。如果您发现了 bug 或有改进建议，请在 [GitHub 仓库](https://github.com/example/crawlee-ruby) 上提交 issue 或 pull request。
