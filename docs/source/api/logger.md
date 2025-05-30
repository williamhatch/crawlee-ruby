# Logger 类

Logger 类是 Crawlee Ruby 框架中的日志记录组件，用于记录爬虫运行过程中的各种信息、警告和错误。本文档详细介绍了 Logger 类的功能、方法和使用示例。

## 概述

Logger 类是对 Ruby 标准库中 `Logger` 类的封装，提供了更简洁的接口和更适合爬虫应用的默认配置。它支持多种日志级别，可以输出到控制台或文件，并且可以自定义日志格式。

## 初始化

```ruby
def initialize(level = :info, output = STDOUT)
  @logger = ::Logger.new(output)
  @logger.level = LEVELS[level] || ::Logger::INFO
  @logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
  end
end
```

创建一个新的 Logger 实例。

**参数：**
- `level` (Symbol): 日志级别，可选值为 `:debug`、`:info`、`:warn`、`:error`、`:fatal`，默认为 `:info`。
- `output` (IO): 日志输出目标，默认为 `STDOUT`（标准输出）。

**示例：**
```ruby
# 创建默认日志记录器（INFO 级别，输出到控制台）
logger = Crawlee::Logger.new

# 创建 DEBUG 级别的日志记录器
logger = Crawlee::Logger.new(:debug)

# 创建输出到文件的日志记录器
logger = Crawlee::Logger.new(:info, File.open('crawlee.log', 'a'))
```

## 日志级别

Logger 类支持以下日志级别，按严重程度从低到高排序：

1. **DEBUG**：详细的调试信息，通常只在开发和调试时使用。
2. **INFO**：常规信息，表示程序正常运行。
3. **WARN**：警告信息，表示可能出现问题，但程序仍能继续运行。
4. **ERROR**：错误信息，表示发生了错误，但程序仍能部分运行。
5. **FATAL**：致命错误信息，表示发生了严重错误，程序可能无法继续运行。

日志记录器只会记录级别大于或等于当前设置级别的日志。例如，如果日志级别设置为 `:info`，则 `:debug` 级别的日志将不会被记录。

## 方法

### debug

```ruby
def debug(message)
  @logger.debug(message)
end
```

记录调试信息。

**参数：**
- `message` (String): 日志消息。

**示例：**
```ruby
logger.debug("正在处理 URL: #{url}")
```

### info

```ruby
def info(message)
  @logger.info(message)
end
```

记录普通信息。

**参数：**
- `message` (String): 日志消息。

**示例：**
```ruby
logger.info("爬虫已启动，初始 URL: #{start_url}")
```

### warn

```ruby
def warn(message)
  @logger.warn(message)
end
```

记录警告信息。

**参数：**
- `message` (String): 日志消息。

**示例：**
```ruby
logger.warn("请求重试次数过多: #{url}")
```

### error

```ruby
def error(message)
  @logger.error(message)
end
```

记录错误信息。

**参数：**
- `message` (String): 日志消息。

**示例：**
```ruby
logger.error("请求失败: #{url}, 错误: #{e.message}")
```

### fatal

```ruby
def fatal(message)
  @logger.fatal(message)
end
```

记录致命错误信息。

**参数：**
- `message` (String): 日志消息。

**示例：**
```ruby
logger.fatal("爬虫崩溃: #{e.message}")
```

## 全局日志记录器

Crawlee 框架提供了一个全局日志记录器，可以通过 `Crawlee.logger` 访问。这个全局日志记录器在框架内部使用，也可以在自定义代码中使用。

**示例：**
```ruby
# 在爬虫代码中使用全局日志记录器
Crawlee.logger.info("开始处理页面")
```

## 自定义日志格式

Logger 类使用以下默认格式：

```
[YYYY-MM-DD HH:MM:SS] SEVERITY: MESSAGE
```

如果需要自定义日志格式，可以在创建 Logger 实例后修改其 formatter：

```ruby
logger = Crawlee::Logger.new
logger.instance_variable_get(:@logger).formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}][#{severity}] #{msg}\n"
end
```

## 高级用法

### 日志轮替

对于长时间运行的爬虫，可以设置日志文件的轮替，防止日志文件过大：

```ruby
# 创建每天轮替的日志记录器
logger = Crawlee::Logger.new(:info, ::Logger.new('crawler.log', 'daily'))

# 或者按文件大小轮替，每个文件最大 10MB，保留 10 个旧文件
logger = Crawlee::Logger.new(:info, ::Logger.new('crawler.log', 10, 10 * 1024 * 1024))
```

### 结构化日志

对于需要进行日志分析的应用，可以使用 JSON 格式的结构化日志：

```ruby
logger = Crawlee::Logger.new(:info)
logger.instance_variable_get(:@logger).formatter = proc do |severity, datetime, progname, msg|
  JSON.dump({
    timestamp: datetime.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
    severity: severity,
    message: msg,
    crawler_id: ENV['CRAWLER_ID'] || 'default',
    pid: Process.pid
  }) + "\n"
end
```

### 多目标日志

同时输出日志到控制台和文件：

```ruby
require 'logger'

# 创建多目标日志记录器
file_logger = ::Logger.new('crawler.log')
console_logger = ::Logger.new(STDOUT)

# 将两个日志记录器组合到一个数组中
multi_logger = [file_logger, console_logger]

# 创建一个代理对象，转发所有日志调用
logger_proxy = Object.new

# 定义日志方法
[:debug, :info, :warn, :error, :fatal].each do |level|
  logger_proxy.define_singleton_method(level) do |message|
    multi_logger.each { |logger| logger.send(level, message) }
  end
end

# 使用代理对象创建 Crawlee 日志记录器
logger = Crawlee::Logger.new
logger.instance_variable_set(:@logger, logger_proxy)
```

### 与其他日志框架集成

如果项目使用其他日志框架，如 Lograge 或 Fluentd，可以进行集成：

```ruby
# 例如，与 Fluentd 集成
require 'fluent-logger'

fluent_logger = Fluent::Logger::FluentLogger.new('crawlee', {
  host: 'fluentd-host',
  port: 24224
})

logger = Crawlee::Logger.new
original_logger = logger.instance_variable_get(:@logger)

# 重写日志方法，同时发送到 Fluentd
[:debug, :info, :warn, :error, :fatal].each do |level|
  logger.define_singleton_method(level) do |message|
    original_logger.send(level, message)
    fluent_logger.post(level.to_s, { message: message })
  end
end
```

## 最佳实践

### 1. 使用适当的日志级别

* **开发环境**：使用 `:debug` 级别，记录详细信息以帮助调试。
* **测试环境**：使用 `:info` 级别，记录主要操作和状态变化。
* **生产环境**：使用 `:warn` 或 `:error` 级别，只记录异常情况，减少日志量。

```ruby
# 根据环境设置日志级别
env = ENV['CRAWLEE_ENV'] || 'development'
log_level = case env
             when 'development' then :debug
             when 'test' then :info
             when 'production' then :warn
             end

logger = Crawlee::Logger.new(log_level)
```

### 2. 结构化日志消息

使用一致的格式记录日志，便于后期分析和过滤：

```ruby
# 记录请求相关信息
logger.info("REQUEST: url=#{url}, method=#{method}, headers=#{headers.keys.join(',')}, timeout=#{timeout}")

# 记录响应相关信息
logger.info("RESPONSE: url=#{url}, status=#{status}, content_type=#{content_type}, size=#{body.size}")

# 记录数据提取信息
logger.info("DATA: url=#{url}, items=#{items.size}, fields=#{items.first.keys.join(',')}")
```

### 3. 包含上下文信息

在日志中包含足够的上下文信息，便于问题追踪：

```ruby
# 在路由处理器中使用
crawler.router.default do |context|
  request_id = SecureRandom.uuid
  logger.info("[请求 #{request_id}] 开始处理: #{context.request.url}")
  
  begin
    # 处理逻辑...
    
    logger.info("[请求 #{request_id}] 完成处理: #{context.request.url}, 耗时: #{Time.now - start_time}s")
  rescue => e
    logger.error("[请求 #{request_id}] 处理失败: #{context.request.url}, 错误: #{e.message}")
    logger.debug("[请求 #{request_id}] 堆栈跟踪: \n#{e.backtrace.join("\n")}")
    raise
  end
end
```

### 4. 定期记录统计信息

定期记录爬虫的运行统计信息，监控爬虫的运行状态：

```ruby
require 'concurrent-ruby'

# 创建一个定时任务，每分钟记录一次统计信息
stats_task = Concurrent::TimerTask.new(execution_interval: 60) do
  memory_usage = `ps -o rss= -p #{Process.pid}`.to_i / 1024  # 内存使用（MB）
  
  stats = {
    requests_processed: crawler.processed_requests_count,
    requests_failed: crawler.failed_requests_count,
    requests_per_minute: crawler.requests_per_minute,
    memory_usage: memory_usage,
    queue_size: crawler.request_queue.size,
    active_requests: crawler.active_requests_count
  }
  
  logger.info("STATS: #{stats.map { |k, v| "#{k}=#{v}" }.join(', ')}")
end

# 启动统计任务
stats_task.execute

# 运行爬虫
begin
  crawler.run
ensure
  # 停止统计任务
  stats_task.shutdown
end
```

## 完整示例

以下是一个使用 Logger 类的完整示例，包含高级用法和最佳实践：

```ruby
require 'crawlee'
require 'securerandom'
require 'concurrent-ruby'

# 设置环境变量
ENV['CRAWLER_ID'] = SecureRandom.hex(4)
ENV['CRAWLEE_ENV'] ||= 'development'

# 创建日志目录
log_dir = File.join(Dir.pwd, 'logs')
Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

# 创建日志文件
log_file = File.join(log_dir, "crawler-#{ENV['CRAWLER_ID']}.log")

# 创建日志记录器
log_level = ENV['CRAWLEE_ENV'] == 'production' ? :info : :debug
logger = Crawlee::Logger.new(log_level, ::Logger.new(log_file, 10, 10 * 1024 * 1024))

# 自定义日志格式
logger.instance_variable_get(:@logger).formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}][#{severity}][#{ENV['CRAWLER_ID']}] #{msg}\n"
end

# 创建爬虫实例
crawler = Crawlee::Crawlers::HttpCrawler.new

# 创建统计记录器
stats = {
  start_time: Time.now,
  requests: { total: 0, success: 0, failed: 0 },
  data_items: 0
}

# 设置定时统计任务
stats_task = Concurrent::TimerTask.new(execution_interval: 30) do
  elapsed = Time.now - stats[:start_time]
  memory_usage = `ps -o rss= -p #{Process.pid}`.to_i / 1024
  
  logger.info("STATS: requests_total=#{stats[:requests][:total]}, "
             "requests_success=#{stats[:requests][:success]}, "
             "requests_failed=#{stats[:requests][:failed]}, "
             "data_items=#{stats[:data_items]}, "
             "memory_mb=#{memory_usage}, "
             "elapsed_sec=#{elapsed.to_i}, "
             "req_per_min=#{'%.2f' % (stats[:requests][:total] / (elapsed / 60))}")
end

# 设置路由处理器
crawler.router.default do |context|
  request_id = SecureRandom.uuid
  start_time = Time.now
  url = context.request.url
  
  logger.debug("[请求 #{request_id}] 开始处理: #{url}")
  
  begin
    # 更新请求统计
    stats[:requests][:total] += 1
    
    # 提取数据
    title = context.query_selector('title')&.text&.strip
    description = context.query_selector('meta[name="description"]')&.[]('content')
    
    logger.info("[请求 #{request_id}] 页面标题: #{title}")
    
    # 保存数据
    data = {
      url: url,
      title: title,
      description: description,
      crawled_at: Time.now.to_i,
      request_id: request_id
    }
    
    context.save_data(data)
    stats[:data_items] += 1
    
    # 提取链接
    link_count = context.enqueue_links('a.internal-link')
    logger.debug("[请求 #{request_id}] 添加了 #{link_count} 个链接到队列")
    
    # 更新成功统计
    stats[:requests][:success] += 1
    
    # 记录处理时间
    processing_time = Time.now - start_time
    logger.info("[请求 #{request_id}] 完成处理: #{url}, 耗时: #{'%.2f' % processing_time}s")
    
  rescue => e
    # 更新失败统计
    stats[:requests][:failed] += 1
    
    logger.error("[请求 #{request_id}] 处理页面时出错: #{url}, 错误: #{e.message}")
    logger.debug("[请求 #{request_id}] 堆栈跟踪:\n#{e.backtrace.join("\n")}")
  end
end

# 运行爬虫
begin
  logger.info("爬虫启动: id=#{ENV['CRAWLER_ID']}, env=#{ENV['CRAWLEE_ENV']}, start_url=#{crawler.start_urls.join(', ')}")
  
  # 启动统计任务
  stats_task.execute
  
  # 运行爬虫
  crawler.run
  
  # 记录最终统计
  elapsed = Time.now - stats[:start_time]
  logger.info("爬虫完成: 总请求=#{stats[:requests][:total]}, "
             "成功=#{stats[:requests][:success]}, "
             "失败=#{stats[:requests][:failed]}, "
             "数据项=#{stats[:data_items]}, "
             "总耗时=#{'%.2f' % elapsed}s")
  
rescue => e
  logger.fatal("爬虫崩溃: #{e.message}")
  logger.fatal(e.backtrace.join("\n"))
ensure
  # 停止统计任务
  stats_task.shutdown if stats_task.running?
end
