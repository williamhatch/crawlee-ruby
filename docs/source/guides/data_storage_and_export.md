# 数据存储和导出指南

Crawlee Ruby 提供了强大的数据存储和导出功能，帮助你高效地管理爬取的数据。本指南将介绍如何使用 Crawlee 的存储系统保存、管理和导出数据。

## 目录

- [存储系统概述](#存储系统概述)
- [数据集（Dataset）](#数据集dataset)
  - [保存数据](#保存数据)
  - [获取数据](#获取数据)
  - [管理多个数据集](#管理多个数据集)
- [请求队列（Request Queue）](#请求队列request-queue)
  - [添加请求](#添加请求)
  - [处理请求](#处理请求)
  - [队列状态管理](#队列状态管理)
- [键值存储（Key-Value Store）](#键值存储key-value-store)
  - [存储配置和状态](#存储配置和状态)
  - [缓存数据](#缓存数据)
- [数据库集成](#数据库集成)
  - [关系型数据库](#关系型数据库)
  - [NoSQL 数据库](#nosql-数据库)
  - [自定义存储适配器](#自定义存储适配器)
- [数据导出](#数据导出)
  - [导出为 JSON](#导出为-json)
  - [导出为 CSV](#导出为-csv)
  - [导出为 Excel](#导出为-excel)
  - [增量导出](#增量导出)
- [数据处理](#数据处理)
  - [数据验证和清洗](#数据验证和清洗)
  - [数据去重](#数据去重)
  - [增量爬取和存储](#增量爬取和存储)
- [存储优化](#存储优化)
  - [性能优化](#性能优化)
  - [存储空间管理](#存储空间管理)
  - [并发数据处理](#并发数据处理)
- [数据监控和报告](#数据监控和报告)
- [最佳实践](#最佳实践)

## 存储系统概述

Crawlee Ruby 的存储系统包含三个主要组件：

1. **数据集（Dataset）**：用于存储爬取的结构化数据
2. **请求队列（Request Queue）**：管理待处理和已处理的请求
3. **键值存储（Key-Value Store）**：存储配置、状态和其他键值对数据

所有存储组件默认使用文件系统作为后端，数据以 JSON 格式保存在指定目录中。

## 数据集（Dataset）

数据集用于存储爬取的结构化数据，如产品信息、文章内容等。

### 保存数据

在爬虫处理器中保存数据：

```ruby
crawler.router.default_handler do |context|
  # 提取页面数据
  title = context.query_selector('h1')&.text&.strip
  price = context.query_selector('.price')&.text&.strip
  description = context.query_selector('.description')&.text&.strip
  
  # 保存到数据集
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    description: description,
    crawled_at: Time.now.to_i
  })
end
```

每条保存的数据会自动添加 `id` 和 `createdAt` 字段。

### 获取数据

获取数据集中的所有数据：

```ruby
# 获取默认数据集中的所有数据
data = crawler.dataset.get_data

# 处理数据
data.each do |item|
  puts "ID: #{item[:id]}, Title: #{item[:title]}"
end
```

获取数据集信息：

```ruby
info = crawler.dataset.get_info
puts "数据集包含 #{info[:count]} 条记录"
puts "创建时间: #{Time.at(info[:created_at])}"
puts "最后修改时间: #{Time.at(info[:modified_at])}"
```

### 管理多个数据集

创建和使用多个数据集：

```ruby
# 在爬虫初始化时指定数据集
crawler = Crawlee::Crawlers::HttpCrawler.new(
  dataset_name: 'products'
)

# 或者直接通过存储访问
storage = Crawlee::Storage.new
products_dataset = storage.dataset('products')
reviews_dataset = storage.dataset('reviews')

# 保存到不同的数据集
products_dataset.push_data({ name: 'Product 1', price: 99.99 })
reviews_dataset.push_data({ product_id: 'xyz', rating: 5, comment: 'Great!' })
```

## 请求队列（Request Queue）

请求队列管理爬虫的待处理和已处理的 URL。

### 添加请求

添加单个请求：

```ruby
# 添加简单 URL
crawler.enqueue('https://example.com/page1')

# 添加带选项的请求
crawler.enqueue('https://example.com/page2', {
  method: :post,
  payload: { query: 'test' },
  headers: { 'Custom-Header': 'value' },
  max_retries: 3
})

# 添加请求对象
request = Crawlee::Request.new(
  'https://example.com/page3',
  method: :get,
  headers: { 'User-Agent': 'Custom Agent' },
  metadata: { category: 'electronics' }
)
crawler.enqueue(request)
```

批量添加请求：

```ruby
urls = [
  'https://example.com/page1',
  'https://example.com/page2',
  'https://example.com/page3'
]

# 批量添加
crawler.enqueue_links(urls)
```

从页面提取并添加链接：

```ruby
crawler.router.default_handler do |context|
  # 提取并添加所有链接
  context.enqueue_links('a')
  
  # 提取并添加特定链接
  context.enqueue_links('a.product-link')
  
  # 带选项的链接提取
  context.enqueue_links('a.next-page', {
    base_url: 'https://example.com',
    transform_request: ->(request) {
      request.headers['Referer'] = context.request.url
      request
    }
  })
end
```

### 处理请求

请求处理流程：

1. 爬虫从队列获取下一个请求
2. 执行请求并获取响应
3. 创建上下文对象
4. 路由到相应的处理器
5. 标记请求为已处理

查看队列状态：

```ruby
queue_info = crawler.request_queue.get_info
puts "待处理请求数: #{queue_info[:pending_count]}"
puts "已处理请求数: #{queue_info[:handled_count]}"
```

### 队列状态管理

重置队列状态（重新处理所有 URL）：

```ruby
# 重置整个队列
crawler.request_queue.clear

# 或者通过存储直接操作
storage = Crawlee::Storage.new
storage.clear(:request_queue)
```

## 键值存储（Key-Value Store）

键值存储用于保存配置、状态和其他非结构化数据。

### 存储配置和状态

保存和获取配置：

```ruby
# 获取键值存储
key_value_store = crawler.storage.key_value('config')

# 保存配置
key_value_store.set('api_key', 'your-api-key')
key_value_store.set('last_run', Time.now.to_i)
key_value_store.set('settings', {
  max_pages: 100,
  allowed_domains: ['example.com', 'example.org']
})

# 获取配置
api_key = key_value_store.get('api_key')
settings = key_value_store.get('settings')
```

### 缓存数据

使用键值存储作为缓存：

```ruby
# 获取缓存存储
cache_store = crawler.storage.key_value('cache')

# 检查缓存
cache_key = "page_#{Digest::MD5.hexdigest(url)}"
cached_data = cache_store.get(cache_key)

if cached_data
  # 使用缓存数据
  process_data(cached_data)
else
  # 获取新数据并缓存
  data = fetch_data(url)
  cache_store.set(cache_key, data, expires_in: 3600) # 1小时过期
  process_data(data)
end
```

## 数据库集成

Crawlee Ruby 可以与各种数据库系统集成，以满足更复杂的数据存储需求。

### 关系型数据库

使用 ActiveRecord 集成 MySQL、PostgreSQL 等关系型数据库：

```ruby
# 使用 ActiveRecord 集成 MySQL 数据库
require 'active_record'

# 配置数据库连接
ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  host: 'localhost',
  username: 'root',
  password: 'password',
  database: 'crawlee_data'
)

# 定义模型
class Product < ActiveRecord::Base
  # 假设 products 表有 url, title, price, description 等字段
end

# 在爬虫中使用
crawler.router.default_handler do |context|
  # 提取数据
  title = context.query_selector('h1')&.text&.strip
  price = context.query_selector('.price')&.text&.strip&.to_f
  description = context.query_selector('.description')&.text&.strip
  
  # 保存到数据库
  Product.create(
    url: context.request.url,
    title: title,
    price: price,
    description: description,
    crawled_at: Time.now
  )
  
  # 同时保存到 Crawlee 数据集（可选）
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    description: description
  })
end
```

### NoSQL 数据库

使用 MongoDB 等 NoSQL 数据库存储爬取的数据：

```ruby
# 使用 Mongo Ruby Driver 集成 MongoDB
require 'mongo'

# 配置 MongoDB 客户端
mongo_client = Mongo::Client.new(['127.0.0.1:27017'], database: 'crawlee_data')
products_collection = mongo_client[:products]

# 在爬虫中使用
crawler.router.default_handler do |context|
  # 提取数据
  data = {
    url: context.request.url,
    title: context.query_selector('h1')&.text&.strip,
    price: context.query_selector('.price')&.text&.strip,
    description: context.query_selector('.description')&.text&.strip,
    created_at: Time.now
  }
  
  # 保存到 MongoDB
  products_collection.insert_one(data)
end
```

### 自定义存储适配器

创建自定义存储适配器，以支持其他数据库或存储系统：

```ruby
# 创建自定义存储适配器
class CustomDatabaseStorage
  def initialize(options = {})
    @db_connection = establish_connection(options)
    @table_name = options[:table_name] || 'crawled_data'
  end
  
  def save_data(data)
    # 实现数据保存逻辑
    keys = data.keys.join(', ')
    placeholders = Array.new(data.keys.size, '?').join(', ')
    
    @db_connection.execute(
      "INSERT INTO #{@table_name} (#{keys}) VALUES (#{placeholders})",
      *data.values
    )
  end
  
  def get_data(query = {})
    # 实现数据查询逻辑
    if query.empty?
      @db_connection.execute("SELECT * FROM #{@table_name}")
    else
      conditions = query.map { |k, v| "#{k} = ?" }.join(' AND ')
      @db_connection.execute(
        "SELECT * FROM #{@table_name} WHERE #{conditions}",
        *query.values
      )
    end
  end
  
  private
  
  def establish_connection(options)
    # 实现数据库连接逻辑
    # 这里以 SQLite 为例
    require 'sqlite3'
    SQLite3::Database.new(options[:database] || 'crawlee_data.db')
  end
end

# 在爬虫中使用
custom_storage = CustomDatabaseStorage.new(
  database: 'my_crawler.db',
  table_name: 'products'
)

crawler.router.default_handler do |context|
  data = extract_data(context)
  custom_storage.save_data(data)
end
```

## 数据导出

### 导出为 JSON

将数据集导出为 JSON 文件：

```ruby
require 'json'

# 获取数据
data = crawler.dataset.get_data

# 导出为 JSON 文件
File.write('products.json', JSON.pretty_generate(data))
```

### 导出为 CSV

将数据集导出为 CSV 文件：

```ruby
require 'csv'

# 获取数据
data = crawler.dataset.get_data

# 确定 CSV 列
headers = data.first.keys

# 创建 CSV
CSV.open('products.csv', 'w') do |csv|
  # 写入表头
  csv << headers
  
  # 写入数据行
  data.each do |item|
    csv << headers.map { |header| item[header] }
  end
end
```

### 导出为 Excel

将数据集导出为 Excel 文件：

```ruby
require 'axlsx'

# 获取数据
data = crawler.dataset.get_data

# 创建 Excel 工作簿
package = Axlsx::Package.new
workbook = package.workbook

# 添加工作表
workbook.add_worksheet(name: "Products") do |sheet|
  # 添加表头
  headers = data.first.keys
  sheet.add_row headers
  
  # 添加数据行
  data.each do |item|
    sheet.add_row headers.map { |header| item[header] }
  end
end

# 保存文件
package.serialize('products.xlsx')
```

### 增量导出

实现增量数据导出：

```ruby
# 获取键值存储
state_store = crawler.storage.key_value('export_state')

# 获取上次导出时间
last_export_time = state_store.get('last_export_time') || 0

# 获取数据集
data = crawler.dataset.get_data

# 筛选新数据
new_data = data.select { |item| item[:createdAt] > last_export_time }

if new_data.any?
  # 导出新数据
  export_data(new_data)
  
  # 更新导出状态
  state_store.set('last_export_time', Time.now.to_i)
  state_store.set('last_export_count', new_data.size)
end
```

## 数据处理

### 数据验证和清洗

在保存数据前进行验证和清洗，确保数据质量：

```ruby
# 数据清洗和标准化
def clean_product_data(data)
  # 标准化价格
  if data[:price].is_a?(String)
    # 移除货币符号和空格，转换为数字
    data[:price] = data[:price].gsub(/[^\d.]/, '').to_f
  end
  
  # 标准化标题
  if data[:title]
    # 移除多余空格
    data[:title] = data[:title].strip.gsub(/\s+/, ' ')
  end
  
  # 标准化 URL
  if data[:url]
    # 确保 URL 是绝对路径
    data[:url] = data[:url].start_with?('http') ? data[:url] : "https://example.com#{data[:url]}"
  end
  
  # 添加数据来源和时间戳
  data[:source] = 'web_crawler'
  data[:crawled_at] ||= Time.now.to_i
  
  data
end

# 在爬虫中使用
crawler.router.default_handler do |context|
  # 提取原始数据
  raw_data = {
    url: context.request.url,
    title: context.query_selector('h1')&.text,
    price: context.query_selector('.price')&.text,
    description: context.query_selector('.description')&.text
  }
  
  # 清洗数据
  clean_data = clean_product_data(raw_data)
  
  # 验证数据
  if validate_product_data(clean_data)
    # 保存有效数据
    context.save_data(clean_data)
  else
    Crawlee.logger.warn("Invalid data for URL: #{context.request.url}")
  end
end

# 数据验证
def validate_product_data(data)
  # 验证必填字段
  required_fields = [:title, :price, :url]
  missing_fields = required_fields.select { |field| data[field].nil? || data[field].to_s.empty? }
  
  if missing_fields.any?
    Crawlee.logger.warn("Data missing required fields: #{missing_fields.join(', ')}")
    return false
  end
  
  # 验证数据类型
  unless data[:price].is_a?(Numeric) || data[:price].to_s =~ /^\d+(\.\d+)?$/
    Crawlee.logger.warn("Invalid price format: #{data[:price]}")
    return false
  end
  
  true
end
```

### 数据去重

在处理大量数据时，去除重复项很重要：

```ruby
# 数据去重
def deduplicate_data(data_array, key_field = :url)
  # 使用哈希表跟踪已见项目
  seen = {}
  unique_data = []
  
  data_array.each do |item|
    key = item[key_field]
    next if seen[key] # 跳过重复项
    
    seen[key] = true
    unique_data << item
  end
  
  unique_data
end

# 使用示例
def export_unique_data(crawler, output_file)
  # 获取所有数据
  all_data = crawler.dataset.get_data
  
  # 去除重复项
  unique_data = deduplicate_data(all_data)
  
  # 导出去重后的数据
  File.write(output_file, JSON.pretty_generate(unique_data))
  
  puts "Exported #{unique_data.size} unique items (removed #{all_data.size - unique_data.size} duplicates)"
end
```

### 增量爬取和存储

增量爬取可以提高效率，只处理新内容：

```ruby
# 增量爬取和存储
def incremental_crawl(crawler, start_url, last_run_time = nil)
  # 获取上次运行时间
  key_value_store = crawler.storage.key_value('crawler_state')
  last_run_time ||= key_value_store.get('last_run_time')
  
  # 配置爬虫
  crawler.router.default_handler do |context|
    # 提取页面时间戳（假设页面有更新时间）
    page_updated_at = extract_page_timestamp(context)
    
    # 只处理新内容或更新的内容
    if !last_run_time || page_updated_at > last_run_time
      # 处理并保存数据
      data = extract_and_save_data(context)
      
      # 提取并添加新链接
      context.enqueue_links('a.product-link')
    end
  end
  
  # 添加起始 URL
  crawler.enqueue(start_url)
  
  # 运行爬虫
  crawler.run
  
  # 更新状态
  key_value_store.set('last_run_time', Time.now.to_i)
end

# 从页面提取时间戳
def extract_page_timestamp(context)
  # 从页面元数据或内容中提取时间
  timestamp_element = context.query_selector('meta[property="article:published_time"]')
  if timestamp_element
    # 从元标签提取时间
    time_str = timestamp_element['content']
    return Time.parse(time_str).to_i rescue Time.now.to_i
  end
  
  # 如果没有元标签，尝试从页面内容提取
  date_element = context.query_selector('.article-date, .post-date, .published-date')
  if date_element
    time_str = date_element.text.strip
    return Time.parse(time_str).to_i rescue Time.now.to_i
  end
  
  # 默认返回当前时间
  Time.now.to_i
end
```

## 存储优化

### 性能优化

优化数据集性能：

```ruby
# 批量保存数据，减少 I/O 操作
items_to_save = []

crawler.router.default_handler do |context|
  # 提取数据
  item = extract_data(context)
  items_to_save << item
  
  # 当积累足够数据时批量保存
  if items_to_save.size >= 50
    items_to_save.each { |data| crawler.dataset.push_data(data) }
    items_to_save.clear
  end
end

# 确保最后的数据也被保存
crawler.on_finish do
  items_to_save.each { |data| crawler.dataset.push_data(data) }
end
```

### 存储空间管理

管理存储空间：

```ruby
# 定期清理旧数据
def cleanup_old_data(crawler, days_to_keep = 30)
  cutoff_time = Time.now.to_i - (days_to_keep * 86400)
  
  # 获取数据
  data = crawler.dataset.get_data
  
  # 筛选要保留的数据
  data_to_keep = data.select { |item| item[:createdAt] >= cutoff_time }
  
  # 清空并重新保存数据
  crawler.storage.clear(:dataset)
  data_to_keep.each { |item| crawler.dataset.push_data(item) }
end
```

### 并发数据处理

使用并发处理提高数据处理效率：

```ruby
# 使用并发处理数据
require 'concurrent'

def process_data_concurrently(data, worker_count = 4)
  # 创建线程池
  pool = Concurrent::FixedThreadPool.new(worker_count)
  
  # 分割数据
  chunk_size = (data.size.to_f / worker_count).ceil
  data_chunks = data.each_slice(chunk_size).to_a
  
  # 并发处理
  futures = data_chunks.map do |chunk|
    Concurrent::Future.execute(executor: pool) do
      process_chunk(chunk)
    end
  end
  
  # 等待所有处理完成
  results = futures.map(&:value)
  
  # 关闭线程池
  pool.shutdown
  pool.wait_for_termination
  
  # 合并结果
  results.flatten
end

# 处理数据块
def process_chunk(chunk)
  processed_data = []
  
  chunk.each do |item|
    # 这里执行处理逻辑，例如数据清洗、转换等
    processed_item = transform_data(item)
    processed_data << processed_item
  end
  
  processed_data
end

# 使用示例
def transform_and_export_data(crawler, output_file)
  # 获取数据
  data = crawler.dataset.get_data
  
  # 并发处理
  processed_data = process_data_concurrently(data)
  
  # 导出处理后的数据
  File.write(output_file, JSON.pretty_generate(processed_data))
  
  puts "Processed and exported #{processed_data.size} items"
end
```

## 数据监控和报告

监控爬虫运行和数据采集情况：

```ruby
# 生成爬取报告
def generate_crawl_report(crawler)
  # 获取爬虫统计信息
  stats = crawler.stats
  
  # 获取数据集信息
  dataset_info = crawler.dataset.get_info
  
  # 生成报告
  report = {
    crawl_time: Time.now.to_s,
    duration: stats[:duration],
    requests: {
      total: stats[:requests_total],
      successful: stats[:requests_successful],
      failed: stats[:requests_failed],
      retried: stats[:requests_retried]
    },
    data: {
      total_items: dataset_info[:count],
      first_item_time: Time.at(dataset_info[:created_at]).to_s,
      last_item_time: Time.at(dataset_info[:modified_at]).to_s
    }
  }
  
  # 保存报告
  File.write('crawl_report.json', JSON.pretty_generate(report))
  
  # 可选：发送报告
  # send_report_email(report)
  
  report
end

# 监控爬取进度
def monitor_crawl_progress(crawler, interval = 10)
  Thread.new do
    while crawler.running?
      # 获取当前统计信息
      current_stats = crawler.stats
      queue_info = current_stats[:queue_info]
      
      # 计算进度
      total_urls = queue_info[:pending_count] + queue_info[:handled_count]
      progress = total_urls > 0 ? (queue_info[:handled_count].to_f / total_urls * 100).round(2) : 0
      
      # 输出进度信息
      puts "[#{Time.now}] Progress: #{progress}% (#{queue_info[:handled_count]}/#{total_urls})"
      puts "  Successful: #{current_stats[:requests_successful]}, Failed: #{current_stats[:requests_failed]}, Retried: #{current_stats[:requests_retried]}"
      
      # 等待一段时间
      sleep(interval)
    end
  end
end

# 使用示例
def run_monitored_crawl(crawler, start_url)
  # 添加起始 URL
  crawler.enqueue(start_url)
  
  # 启动监控
  monitor_thread = monitor_crawl_progress(crawler)
  
  # 运行爬虫
  crawler.run
  
  # 等待监控线程结束
  monitor_thread.join(1)
  
  # 生成报告
  generate_crawl_report(crawler)
end
```
```

## 最佳实践

1. **规划数据结构**：在开始爬取前，规划好数据结构，确保一致性。

2. **使用多个数据集**：根据数据类型使用不同的数据集，避免混合不相关的数据。

3. **定期备份**：定期将重要数据导出并备份到外部存储。

   ```ruby
   # 定期备份脚本
   def backup_datasets(storage_dir, backup_dir)
     # 确保备份目录存在
     FileUtils.mkdir_p(backup_dir)
     
     # 备份文件名（包含时间戳）
     timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
     backup_file = File.join(backup_dir, "crawlee_backup_#{timestamp}.tar.gz")
     
     # 创建备份
     system("tar -czf #{backup_file} -C #{File.dirname(storage_dir)} #{File.basename(storage_dir)}")
     
     puts "备份已创建: #{backup_file}"
   end
   ```

4. **增量处理**：对于大型数据集，实现增量处理和导出机制。

5. **错误处理**：实现健壮的错误处理，确保数据存储操作失败不会导致整个爬虫崩溃。

   ```ruby
   def safe_save_data(context, data)
     begin
       context.save_data(data)
     rescue => e
       Crawlee.logger.error("数据保存失败: #{e.message}")
       # 可以实现重试逻辑或备用存储
     end
   end
   ```

6. **数据验证**：在保存前验证数据完整性和正确性。

   ```ruby
   def validate_and_save(context, data)
     # 验证必填字段
     required_fields = [:title, :price, :url]
     missing_fields = required_fields.select { |field| data[field].nil? || data[field].to_s.empty? }
     
     if missing_fields.any?
       Crawlee.logger.warn("数据缺少必填字段 #{missing_fields.join(', ')}: #{context.request.url}")
       return false
     end
     
     # 验证数据类型
     unless data[:price].is_a?(Numeric) || data[:price].to_s =~ /^\d+(\.\d+)?$/
       Crawlee.logger.warn("价格格式无效: #{data[:price]}")
       # 尝试修正
       data[:price] = data[:price].to_s.scan(/\d+\.?\d*/).first.to_f if data[:price].to_s =~ /\d+/
     end
     
     # 保存验证后的数据
     context.save_data(data)
     true
   end
   ```

通过合理使用 Crawlee Ruby 的存储系统，你可以高效地管理爬取的数据，并轻松地将数据导出为各种格式。根据项目需求选择合适的存储策略，可以大大提高爬虫的可靠性和效率。
