# HttpCrawler

`HttpCrawler` 是一个基于 HTTP 请求的爬虫类，用于抓取网页内容。它继承自 `BaseCrawler`，提供了处理 HTTP 请求和响应的功能。

## 初始化

```ruby
crawler = Crawlee::Crawlers::HttpCrawler.new(options = {})
```

### 选项

- `max_concurrency` (Integer): 最大并发请求数，默认为 10
- `request_timeout` (Integer): 请求超时时间（秒），默认为 30
- `max_retries` (Integer): 请求失败时的最大重试次数，默认为 3
- `proxy_configuration` (Hash): 代理配置
- `exit_on_empty_queue` (Boolean): 队列为空时是否退出，默认为 true

## 方法

### enqueue

添加 URL 或请求对象到队列。

```ruby
crawler.enqueue(url_or_request, options = {})
```

参数:
- `url_or_request` (String, Crawlee::Request): URL 或请求对象
- `options` (Hash): 请求选项
  - `method` (Symbol): HTTP 方法，如 `:get`, `:post` 等，默认为 `:get`
  - `headers` (Hash): 请求头
  - `payload` (Hash, String): 请求体
  - `metadata` (Hash): 元数据

返回:
- (Boolean): 是否成功添加

### enqueue_links

批量添加 URL 到队列。

```ruby
crawler.enqueue_links(urls_or_requests, options = {})
```

参数:
- `urls_or_requests` (Array<String, Crawlee::Request>): URL 或请求对象数组
- `options` (Hash): 请求选项，同 `enqueue`

返回:
- (Integer): 成功添加的请求数量

### run

运行爬虫，处理队列中的所有请求。

```ruby
crawler.run(options = {})
```

参数:
- `options` (Hash): 运行选项
  - `exit_on_empty_queue` (Boolean): 队列为空时是否退出，默认为 true

返回:
- (Hash): 爬虫统计信息
  - `requests_total` (Integer): 总请求数
  - `requests_successful` (Integer): 成功请求数
  - `requests_failed` (Integer): 失败请求数
  - `requests_retried` (Integer): 重试请求数

### stop

停止爬虫。

```ruby
crawler.stop
```

### save_data

保存数据到数据集。

```ruby
crawler.save_data(data)
```

参数:
- `data` (Hash): 要保存的数据

返回:
- (Hash): 带有 ID 的数据

### stats

获取爬虫统计信息。

```ruby
crawler.stats
```

返回:
- (Hash): 统计信息，同 `run` 方法的返回值

## 示例

```ruby
require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 5,
  request_timeout: 20
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
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
stats = crawler.run

# 输出统计信息
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"
```
