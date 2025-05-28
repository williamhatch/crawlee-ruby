# API 参考

Crawlee Ruby 框架提供了多种类和模块，用于构建强大的网页爬虫。以下是主要组件的 API 参考文档。

## 爬虫类

- [BaseCrawler](base_crawler.md) - 所有爬虫的基类
- [HttpCrawler](http_crawler.md) - 用于 HTTP 请求的爬虫
- [BrowserCrawler](browser_crawler.md) - 基于浏览器的爬虫
- [AdaptiveCrawler](adaptive_crawler.md) - 自适应爬虫，可以根据需要切换 HTTP 和浏览器模式

## 请求和响应

- [Request](request.md) - 表示一个 HTTP 请求
- [Response](response.md) - 表示一个 HTTP 响应

## 会话管理

- [SessionPool](session_pool.md) - 管理会话和 Cookie

## 存储

- [Storage](storage.md) - 存储系统
  - [RequestQueueStorage](request_queue_storage.md) - 请求队列存储
  - [DatasetStorage](dataset_storage.md) - 数据集存储
  - [KeyValueStorage](key_value_storage.md) - 键值存储

## 工具类

- [Configuration](configuration.md) - 配置选项
- [Logger](logger.md) - 日志记录
- [FingerprintGenerator](fingerprint_generator.md) - 生成请求指纹
