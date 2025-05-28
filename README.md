<h1 align="center">
    <img alt="Crawlee Ruby" src="https://via.placeholder.com/500x100?text=Crawlee+Ruby" width="500">
    <br>
    <small>Ruby 版网络爬虫和浏览器自动化库</small>
</h1>

## 致谢

本项目是受 [Crawlee](https://crawlee.dev) 社区提供的 JavaScript 和 Python 版本的启发，作为兴趣项目开发的 Ruby 实现版本。在此特别感谢 Crawlee 社区的开发者们提供了如此优秀的爬虫框架，为本项目提供了宝贵的设计思路和参考。

Crawlee 官方版本：
- [Crawlee JavaScript](https://github.com/apify/crawlee) - 原始 JavaScript 实现
- [Crawlee Python](https://github.com/apify/crawlee-python) - Python 实现版本

<p align=center>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/gem/v/crawlee.svg" alt="Gem Version">
    </a>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/gem/dt/crawlee.svg" alt="Gem Downloads">
    </a>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/badge/ruby-%3E%3D%203.0.0-ruby.svg" alt="Ruby Version">
    </a>
</p>

Crawlee Ruby 是一个全面的网络爬虫和数据提取框架，帮助您构建可靠的爬虫。快速且高效。

> 🚀 Crawlee Ruby 是 Crawlee 生态系统的 Ruby 实现版本！

即使使用默认配置，您的爬虫也能表现得几乎与人类行为相似，轻松绕过现代网站的反爬虫保护。Crawlee Ruby 为您提供了爬取网页链接、提取数据并以机器可读格式持久存储的工具，无需担心技术细节。通过丰富的配置选项，您可以根据项目需求调整 Crawlee Ruby 的几乎任何方面。

## 架构图

```
+---------------------+      +---------------------+
|      应用层         |      |     工具与扩展      |
|  (用户爬虫脚本)      |      |                     |
+----------+----------+      | +---------------+   |
           |                 | | 指纹生成器     |   |
           v                 | +---------------+   |
+---------------------+      |                     |
|      爬虫层         |<---->| +---------------+   |
|                     |      | | 代理管理器     |   |
| +---------------+   |      | +---------------+   |
| | HttpCrawler   |   |      |                     |
| +---------------+   |      | +---------------+   |
|                     |      | | 浏览器管理     |   |
| +---------------+   |      | +---------------+   |
| | BrowserCrawler|   |      +---------------------+
| +---------------+   |                ^
|                     |                |
| +---------------+   |                v
| | AdaptiveCrawler|  |      +---------------------+
| +---------------+   |      |     中间件系统      |
+----------+----------+      |                     |
           |                 | +---------------+   |
           v                 | | 请求中间件     |   |
+---------------------+      | +---------------+   |
|      核心层         |<---->|                     |
|                     |      | +---------------+   |
| +---------------+   |      | | 响应中间件     |   |
| | 请求/响应处理  |   |      | +---------------+   |
| +---------------+   |      |                     |
|                     |      | +---------------+   |
| +---------------+   |      | | 错误处理中间件 |   |
| | 会话管理       |   |      | +---------------+   |
| +---------------+   |      +---------------------+
|                     |                ^
| +---------------+   |                |
| | 路由系统       |   |                v
| +---------------+   |      +---------------------+
+----------+----------+      |     监控与日志      |
           |                 |                     |
           v                 | +---------------+   |
+---------------------+      | | 性能监控       |   |
|      存储层         |<---->| +---------------+   |
|                     |      |                     |
| +---------------+   |      | +---------------+   |
| | 请求队列       |   |      | | 日志系统       |   |
| +---------------+   |      | +---------------+   |
|                     |      |                     |
| +---------------+   |      | +---------------+   |
| | 数据集         |   |      | | 统计分析       |   |
| +---------------+   |      | +---------------+   |
|                     |      +---------------------+
| +---------------+   |
| | 键值存储       |   |
| +---------------+   |
+---------------------+
```

## 安装

我们建议访问 Crawlee Ruby 文档中的入门教程获取更多信息。

Crawlee Ruby 可通过 RubyGems 安装，包名为 `crawlee`。此包包含核心功能，而额外功能可作为可选依赖项安装，以保持依赖项和包大小最小化。

要安装 Crawlee Ruby 及其所有功能，请运行以下命令：

```sh
gem install crawlee
```

或者在您的 Gemfile 中添加：

```ruby
gem 'crawlee'
```

然后运行：

```sh
bundle install
```

## 测试

Crawlee Ruby 使用 RSpec 进行测试。要运行测试，请执行以下步骤：

1. 安装开发依赖：

```sh
bundle install
```

2. 运行测试：

```sh
bundle exec rspec
```

您可以运行特定的测试文件：

```sh
bundle exec rspec spec/lib/crawlee/configuration_spec.rb
```

或者运行特定的测试用例：

```sh
bundle exec rspec spec/lib/crawlee/request_spec.rb:10
```

或者在您的 Gemfile 中添加：

```ruby
gem 'crawlee'
```

然后运行：

```sh
bundle install
```

验证 Crawlee Ruby 是否成功安装：

```sh
ruby -e 'require "crawlee"; puts Crawlee::VERSION'
```

## 示例

### 基本 HTTP 爬虫

```ruby
require 'crawlee'

# 配置 Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 10
  config.request_timeout = 30
end

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加路由处理器
crawler.router.add(/example\.com/) do |context|
  # 提取数据
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

### 更多示例

请查看 `examples` 目录获取更多示例：

- 使用 Nokogiri 的基本爬虫
- 使用 Ferrum 的浏览器爬虫
- 自适应爬虫示例
- 代理轮换示例
- 数据存储示例

## 特性

为什么选择 Crawlee Ruby 作为网络爬虫和数据提取的首选？

### 为什么使用 Crawlee Ruby 而不是随机的 HTTP 库和 HTML 解析器？

- **HTTP 和浏览器爬取**的统一接口
- 基于可用系统资源的自动**并行爬取**
- 使用 Ruby 编写，具有**完整的文档**和**清晰的 API**
- 错误或被封锁时自动**重试**
- 集成的**代理轮换**和会话管理
- 可配置的**请求路由** - 将 URL 定向到适当的处理程序
- 用于爬取的持久化 **URL 队列**
- 可插拔的表格数据和文件**存储**
- 强大的**错误处理**
- 基于**真实浏览器指纹**的反爬虫绕过

### 为什么使用 Crawlee Ruby 而不是其他 Ruby 爬虫框架？

- **现代设计** - 基于最新的 Ruby 实践和模式构建
- **简单集成** - Crawlee 爬虫是常规 Ruby 脚本，无需额外的启动器执行器。这种灵活性允许将爬虫直接集成到其他应用程序中
- **状态持久化** - 支持中断期间的状态持久化，通过避免在问题发生后从头重启爬取管道来节省时间和成本
- **组织化数据存储** - 允许在单次爬取运行中保存多种类型的结果。提供多种存储选项（请参阅数据集和键值存储）
- **高级会话管理** - 提供强大的会话池和 Cookie 管理功能，有效模拟真实用户行为

## 快速入门

### 1. 安装 Crawlee Ruby

```sh
gem install crawlee
```

### 2. 创建您的第一个爬虫

创建一个名为 `my_crawler.rb` 的文件：

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
crawler.run
```

### 3. 运行爬虫

```sh
ruby my_crawler.rb
```

## 文档

完整的文档可在 DeepWiki 中找到：[Crawlee Ruby 文档](https://deepwiki.example.com/crawlee-ruby)

## 在 Apify 平台上运行

Crawlee Ruby 可以在 [Apify 平台](https://apify.com)上运行，该平台提供了托管、扩展和监控您的爬虫的基础设施。

## 支持与社区

- **GitHub Issues**：如果您在使用 Crawlee Ruby 时遇到任何问题，请在我们的 [GitHub 仓库](https://github.com/example/crawlee-ruby/issues)上创建 issue
- **讨论**：加入我们的[讨论区](https://github.com/example/crawlee-ruby/discussions)分享您的经验和问题

## 贡献

我们欢迎任何形式的贡献！请查看我们的[贡献指南](CONTRIBUTING.md)了解更多信息。

## 许可证

本项目采用 MIT 许可证 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
