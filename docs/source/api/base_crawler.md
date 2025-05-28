# BaseCrawler

`BaseCrawler` 是所有爬虫类的基类，提供了爬虫的核心功能和接口。它定义了请求队列管理、路由处理和统计信息收集等基本功能。

## 初始化

```ruby
crawler = Crawlee::Crawlers::BaseCrawler.new(options = {})
```

### 选项

- `max_concurrency` (Integer): 最大并发请求数，默认为 10
- `max_retries` (Integer): 请求失败时的最大重试次数，默认为 3
- `retry_delay` (Integer): 重试请求前的延迟时间（毫秒），默认为 1000
- `exit_on_empty_queue` (Boolean): 队列为空时是否退出，默认为 true
- `storage_dir` (String): 存储目录路径，默认为 './storage'

## 属性

### router

请求路由器，用于定义不同 URL 模式的处理逻辑。

```ruby
crawler.router
```

### request_queue

请求队列，用于管理待处理的请求。

```ruby
crawler.request_queue
```

### dataset

数据集，用于保存爬取的数据。

```ruby
crawler.dataset
```

### key_value_store

键值存储，用于保存配置和其他数据。

```ruby
crawler.key_value_store
```

### stats

爬虫统计信息。

```ruby
crawler.stats
```

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

### process_request

处理单个请求。通常不需要直接调用此方法，而是通过 `run` 方法自动调用。

```ruby
crawler.process_request(request)
```

参数:
- `request` (Crawlee::Request): 要处理的请求

返回:
- (Crawlee::Response): 响应对象

## 示例

```ruby
require 'crawlee'

# 创建基础爬虫
crawler = Crawlee::Crawlers::BaseCrawler.new(
  max_concurrency: 5,
  max_retries: 3
)

# 设置路由处理器
crawler.router.default_handler do |context|
  puts "处理页面: #{context.request.url}"
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: "页面标题"
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

## 继承

要创建自定义爬虫类，可以继承 `BaseCrawler` 并重写相关方法：

```ruby
class MyCrawler < Crawlee::Crawlers::BaseCrawler
  def initialize(options = {})
    super(options)
    # 自定义初始化逻辑
  end
  
  def process_request(request)
    # 自定义请求处理逻辑
    super(request)
  end
end
```
