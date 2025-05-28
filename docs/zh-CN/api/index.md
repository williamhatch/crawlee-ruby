# Crawlee Ruby API 参考

本节提供了 Crawlee Ruby 的完整 API 文档，帮助您了解各个类和方法的详细用法。

## 核心模块

- [Crawlee](./crawlee.md) - 主模块和全局配置
- [Configuration](./configuration.md) - 配置选项
- [Logger](./logger.md) - 日志系统

## 请求和响应

- [Request](./request.md) - 请求类
- [Response](./response.md) - 响应类

## 爬虫类型

- [BaseCrawler](./crawlers/base_crawler.md) - 基础爬虫类
- [HttpCrawler](./crawlers/http_crawler.md) - HTTP 爬虫
- [BrowserCrawler](./crawlers/browser_crawler.md) - 浏览器爬虫
- [AdaptiveCrawler](./crawlers/adaptive_crawler.md) - 自适应爬虫

## 上下文和路由

- [Router](./router.md) - 请求路由系统
- [HttpContext](./contexts/http_context.md) - HTTP 上下文
- [BrowserContext](./contexts/browser_context.md) - 浏览器上下文

## 存储系统

- [Storage](./storage.md) - 存储管理类
- [RequestQueueStorage](./storage/request_queue_storage.md) - 请求队列存储
- [DatasetStorage](./storage/dataset_storage.md) - 数据集存储
- [KeyValueStorage](./storage/key_value_storage.md) - 键值存储

## 工具和辅助类

- [SessionPool](./session_pool.md) - 会话池
- [FingerprintGenerator](./fingerprint_generator.md) - 指纹生成器

## 类型和接口

- [常量和枚举](./constants.md) - 常量和枚举值
- [类型定义](./types.md) - 类型定义和接口

## API 使用示例

### 基本配置

```ruby
require 'crawlee'

Crawlee.configure do |config|
  config.max_concurrency = 10
  config.request_timeout = 30
  config.max_retries = 3
  config.log_level = :info
end
```

### 创建和运行爬虫

```ruby
# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加路由处理器
crawler.router.add(/example\.com/) do |context|
  # 处理页面
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

### 使用会话池和指纹生成器

```ruby
# 创建会话池
session_pool = Crawlee::SessionPool.new(20)

# 创建指纹生成器
fingerprint_generator = Crawlee::FingerprintGenerator.new(
  browsers: [:chrome, :firefox],
  devices: [:desktop, :mobile]
)

# 生成指纹
fingerprint = fingerprint_generator.generate('example.com')

# 获取会话
session = session_pool.get_session('example.com')

# 更新会话 Cookie
session_pool.update_cookies('example.com', [
  { name: 'session_id', value: '12345', domain: 'example.com' }
])
```

### 使用存储系统

```ruby
# 创建存储管理器
storage = Crawlee::Storage.new('./storage')

# 获取请求队列
request_queue = storage.request_queue('my_queue')

# 获取数据集
dataset = storage.dataset('my_dataset')

# 获取键值存储
key_value_store = storage.key_value('my_store')

# 保存数据
dataset.push_data({ title: 'Example Page', url: 'https://example.com' })

# 存储键值
key_value_store.set('last_run', Time.now.to_i)
```
