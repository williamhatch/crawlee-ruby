# Storage

`Storage` 是 Crawlee Ruby 框架的存储系统，用于管理请求队列、数据集和键值存储。它提供了一个统一的接口来访问这些存储组件，支持持久化数据到文件系统。

## 初始化

```ruby
storage = Crawlee::Storage.open(dir, options = {})
```

### 参数

- `dir` (String): 存储目录路径
- `options` (Hash): 存储选项
  - `name` (String): 存储名称，默认为 'default'

## 类方法

### open

打开一个存储实例。

```ruby
Crawlee::Storage.open(dir, options = {})
```

参数:
- `dir` (String): 存储目录路径
- `options` (Hash): 存储选项
  - `name` (String): 存储名称，默认为 'default'

返回:
- (Crawlee::Storage): 存储实例

## 实例方法

### dataset

获取数据集存储实例。

```ruby
storage.dataset(name = 'default')
```

参数:
- `name` (String): 数据集名称，默认为 'default'

返回:
- (Crawlee::DatasetStorage): 数据集存储实例

### request_queue

获取请求队列存储实例。

```ruby
storage.request_queue(name = 'default')
```

参数:
- `name` (String): 请求队列名称，默认为 'default'

返回:
- (Crawlee::RequestQueueStorage): 请求队列存储实例

### key_value_store

获取键值存储实例。

```ruby
storage.key_value_store(name = 'default')
```

参数:
- `name` (String): 键值存储名称，默认为 'default'

返回:
- (Crawlee::KeyValueStorage): 键值存储实例

## DatasetStorage

`DatasetStorage` 用于存储爬取的数据，支持添加、获取和清空数据操作。

### 初始化

```ruby
dataset = Crawlee::DatasetStorage.new(storage_dir, name = 'default')
```

参数:
- `storage_dir` (String): 存储目录路径
- `name` (String): 数据集名称，默认为 'default'

### 属性

#### name

数据集名称。

```ruby
dataset.name
```

### 方法

#### push_data

添加数据到数据集。

```ruby
dataset.push_data(data)
```

参数:
- `data` (Hash): 要添加的数据

返回:
- (Hash): 添加的数据，包含自动生成的 ID 和时间戳

#### get_data

获取数据集中的所有数据。

```ruby
dataset.get_data
```

返回:
- (Array<Hash>): 数据集中的所有数据

#### clear

清空数据集。

```ruby
dataset.clear
```

返回:
- (Boolean): 操作是否成功

## RequestQueueStorage

`RequestQueueStorage` 用于管理爬虫的请求队列，支持添加、获取、标记处理和清空请求操作。

### 初始化

```ruby
queue = Crawlee::RequestQueueStorage.new(storage_dir, name = 'default')
```

参数:
- `storage_dir` (String): 存储目录路径
- `name` (String): 请求队列名称，默认为 'default'

### 属性

#### name

请求队列名称。

```ruby
queue.name
```

#### size

请求队列中的请求数量。

```ruby
queue.size
```

### 方法

#### add

添加请求到队列。

```ruby
queue.add(request)
```

参数:
- `request` (Crawlee::Request): 要添加的请求

返回:
- (Boolean): 是否成功添加（如果请求已存在则返回 false）

#### batch_add

批量添加请求到队列。

```ruby
queue.batch_add(requests)
```

参数:
- `requests` (Array<Crawlee::Request>): 要添加的请求数组

返回:
- (Integer): 成功添加的请求数量

#### fetch

获取下一个待处理的请求。

```ruby
queue.fetch
```

返回:
- (Crawlee::Request): 下一个待处理的请求，如果队列为空则返回 nil

#### mark_handled

标记请求为已处理。

```ruby
queue.mark_handled(request)
```

参数:
- `request` (Crawlee::Request): 要标记的请求

返回:
- (Boolean): 操作是否成功

#### is_handled?

检查请求是否已处理。

```ruby
queue.is_handled?(request)
```

参数:
- `request` (Crawlee::Request): 要检查的请求

返回:
- (Boolean): 请求是否已处理

#### clear

清空请求队列。

```ruby
queue.clear
```

返回:
- (Boolean): 操作是否成功

## KeyValueStorage

`KeyValueStorage` 用于存储键值对数据，支持设置、获取和删除操作。

### 初始化

```ruby
store = Crawlee::KeyValueStorage.new(storage_dir, name = 'default')
```

参数:
- `storage_dir` (String): 存储目录路径
- `name` (String): 键值存储名称，默认为 'default'

### 属性

#### name

键值存储名称。

```ruby
store.name
```

### 方法

#### set

设置键值对。

```ruby
store.set(key, value)
```

参数:
- `key` (String): 键
- `value` (Object): 值（会被序列化为 JSON）

返回:
- (Boolean): 操作是否成功

#### get

获取键对应的值。

```ruby
store.get(key)
```

参数:
- `key` (String): 键

返回:
- (Object): 值（从 JSON 反序列化），如果键不存在则返回 nil

#### delete

删除键值对。

```ruby
store.delete(key)
```

参数:
- `key` (String): 键

返回:
- (Boolean): 操作是否成功

#### keys

获取所有键。

```ruby
store.keys
```

返回:
- (Array<String>): 所有键

#### clear

清空键值存储。

```ruby
store.clear
```

返回:
- (Boolean): 操作是否成功

## 示例

### 基本用法

```ruby
# 打开存储
storage = Crawlee::Storage.open('./storage')

# 获取数据集
dataset = storage.dataset

# 添加数据
dataset.push_data({
  title: '示例标题',
  url: 'https://example.com'
})

# 获取所有数据
all_data = dataset.get_data
puts "数据集中有 #{all_data.size} 条数据"

# 获取请求队列
queue = storage.request_queue

# 添加请求
request = Crawlee::Request.new('https://example.com')
queue.add(request)

# 获取下一个请求
next_request = queue.fetch
puts "下一个请求: #{next_request.url}"

# 标记请求为已处理
queue.mark_handled(next_request)

# 获取键值存储
store = storage.key_value_store

# 设置键值对
store.set('config', {
  max_depth: 3,
  follow_links: true
})

# 获取值
config = store.get('config')
puts "最大深度: #{config['max_depth']}"
```

### 使用多个存储

```ruby
# 打开存储
storage = Crawlee::Storage.open('./storage')

# 使用不同名称的数据集
products_dataset = storage.dataset('products')
categories_dataset = storage.dataset('categories')

# 分别存储不同类型的数据
products_dataset.push_data({
  name: '手机',
  price: 1999.00,
  brand: '小米'
})

categories_dataset.push_data({
  name: '电子产品',
  parent: '数码'
})

# 使用不同名称的请求队列
products_queue = storage.request_queue('products_urls')
categories_queue = storage.request_queue('categories_urls')

# 使用不同名称的键值存储
products_store = storage.key_value_store('products_config')
categories_store = storage.key_value_store('categories_config')
```

### 数据集高级用法

```ruby
require 'crawlee'
require 'json'

# 创建爬虫实例
crawler = Crawlee::Crawlers::HttpCrawler.new

# 设置路由处理器
crawler.router.default do |context|
  # 提取产品数据
  products = context.query_selector_all('.product').map do |product|
    {
      title: product.at_css('.title')&.text&.strip,
      price: product.at_css('.price')&.text&.gsub(/[^\d.]/, '').to_f,
      url: context.request.url,
      timestamp: Time.now.to_i
    }
  end
  
  # 批量保存数据
  products.each do |product|
    context.save_data(product)
  end
  
  # 提取下一页链接
  next_page = context.query_selector('.pagination .next')
  if next_page && next_page['href']
    context.enqueue(next_page['href'])
  end
end

# 添加起始 URL
crawler.enqueue('https://example.com/products')

# 运行爬虫
crawler.run

# 爬取完成后处理数据
all_products = crawler.dataset.get_data

# 数据分析
total_price = all_products.sum { |p| p[:price] }
average_price = total_price / all_products.size

puts "共爬取了 #{all_products.size} 个产品"
puts "平均价格: #{average_price.round(2)}"

# 将数据导出为 JSON 文件
File.write('products.json', JSON.pretty_generate(all_products))
```

### 请求队列高级用法

```ruby
require 'crawlee'

# 创建爬虫实例
crawler = Crawlee::Crawlers::HttpCrawler.new

# 直接访问请求队列
queue = crawler.request_queue

# 批量添加请求
urls = [
  'https://example.com/page1',
  'https://example.com/page2',
  'https://example.com/page3'
]

requests = urls.map do |url|
  Crawlee::Request.new(url, {
    # 添加元数据
    metadata: {
      source: 'seed',
      depth: 0,
      category: 'main'
    },
    # 设置自定义头部
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8'
    }
  })
end

# 批量添加请求
added_count = queue.batch_add(requests)
puts "成功添加 #{added_count} 个请求"

# 设置路由处理器
crawler.router.default do |context|
  puts "处理页面: #{context.request.url}"
  puts "页面元数据: #{context.metadata.inspect}"
  
  # 提取链接
  links = context.query_selector_all('a').map { |a| a['href'] }.compact
  
  # 仅当深度小于 2 时添加新链接
  if context.metadata[:depth] < 2
    links.each do |link|
      context.enqueue(link, {
        metadata: {
          source: context.request.url,
          depth: context.metadata[:depth] + 1,
          parent_category: context.metadata[:category]
        }
      })
    end
  end
end

# 运行爬虫
crawler.run

# 检查队列状态
puts "队列中还有 #{queue.size} 个未处理的请求"
```

### 键值存储高级用法

```ruby
require 'crawlee'
require 'json'

# 创建爬虫实例
crawler = Crawlee::Crawlers::HttpCrawler.new

# 获取键值存储
store = crawler.key_value_store

# 存储爬虫配置
store.set('crawler_config', {
  max_depth: 3,
  follow_external_links: false,
  allowed_domains: ['example.com', 'sub.example.com'],
  user_agents: [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  ],
  request_delay: 1000, # 毫秒
  last_run: Time.now.to_i
})

# 存储缓存的页面
store.set('homepage_cache', {
  url: 'https://example.com',
  content: '<html>...</html>',
  timestamp: Time.now.to_i,
  expires_at: Time.now.to_i + 3600 # 1 小时后过期
})

# 设置路由处理器
crawler.router.default do |context|
  # 获取爬虫配置
  config = store.get('crawler_config')
  
  # 检查是否应该追踪链接
  should_follow_links = context.metadata[:depth] < config['max_depth']
  
  if should_follow_links
    # 提取链接
    links = context.query_selector_all('a').map { |a| a['href'] }.compact
    
    # 过滤链接
    links.each do |link|
      begin
        uri = URI.parse(link)
        # 检查是否在允许的域名内
        if config['allowed_domains'].include?(uri.host)
          context.enqueue(link)
        end
      rescue URI::InvalidURIError
        # 忽略无效的 URI
      end
    end
  end
  
  # 更新爬虫状态
  store.set('crawler_status', {
    last_url: context.request.url,
    processed_count: (store.get('crawler_status')&.[]('processed_count') || 0) + 1,
    last_updated: Time.now.to_i
  })
  
  # 随机选择用户代理
  user_agent = config['user_agents'].sample
  puts "使用用户代理: #{user_agent}"
  
  # 模拟请求延迟
  sleep(config['request_delay'] / 1000.0)
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run

# 运行结束后导出爬虫状态
crawler_status = store.get('crawler_status')
File.write('crawler_status.json', JSON.pretty_generate(crawler_status))
```

# 添加数据到不同的数据集
products_dataset.push_data({
  name: '产品1',
  price: 99.99
})

categories_dataset.push_data({
  name: '电子产品',
  count: 100
})

# 使用不同名称的请求队列
products_queue = storage.request_queue('products')
categories_queue = storage.request_queue('categories')

# 添加请求到不同的队列
products_queue.add(Crawlee::Request.new('https://example.com/products'))
categories_queue.add(Crawlee::Request.new('https://example.com/categories'))
```

### 在爬虫中使用存储

```ruby
require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  storage_dir: './storage'
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 保存数据到数据集
  context.save_data({
    url: context.request.url,
    title: context.query_selector('title')&.text
  })
  
  # 使用键值存储保存配置
  crawler.key_value_store.set('last_run', Time.now.to_i)
  
  # 提取并跟踪链接
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

## 最佳实践

以下是使用 Crawlee Ruby 存储系统的一些最佳实践，可以帮助您更高效地管理爬虫数据和请求。

### 1. 数据集最佳实践

#### 使用结构化数据

在存储数据时，始终使用结构化的格式，并保持一致的字段名称。

```ruby
# 好的做法
dataset.push_data({
  title: '产品标题',
  price: 99.99,
  currency: 'CNY',
  available: true,
  url: 'https://example.com/product/123',
  timestamp: Time.now.to_i
})

# 避免使用不一致的字段名称
# 不好的做法
dataset.push_data({
  'Product Title': '产品标题',
  'product_price': 99.99,
  'Currency': 'CNY'
})
```

#### 包含元数据

始终在数据中包含有用的元数据，如源 URL、爬取时间和版本信息。

```ruby
dataset.push_data({
  title: '产品标题',
  price: 99.99,
  # 元数据
  url: context.request.url,
  crawled_at: Time.now.to_i,
  crawlee_version: Crawlee::VERSION
})
```

#### 定期导出数据

对于大型爬虫，定期导出数据并清空数据集，以避免内存问题。

```ruby
# 在路由处理器中
crawler.router.default do |context|
  # 处理页面...
  
  # 每处理 1000 个页面导出一次数据
  processed_count = (crawler.key_value_store.get('processed_count') || 0) + 1
  crawler.key_value_store.set('processed_count', processed_count)
  
  if processed_count % 1000 == 0
    # 导出数据
    data = crawler.dataset.get_data
    File.write("data_batch_#{processed_count / 1000}.json", JSON.generate(data))
    
    # 清空数据集
    crawler.dataset.clear
    
    puts "已导出数据批次 #{processed_count / 1000}"
  end
end
```

### 2. 请求队列最佳实践

#### 使用元数据传递上下文

在请求中使用元数据传递上下文信息，而不是依赖全局状态。

```ruby
# 添加请求时包含元数据
crawler.enqueue('https://example.com/category/electronics', {
  metadata: {
    category: 'electronics',
    depth: 0,
    parent_url: nil
  }
})

# 在路由处理器中使用元数据
crawler.router.default do |context|
  category = context.metadata[:category]
  depth = context.metadata[:depth]
  
  puts "处理分类: #{category}, 深度: #{depth}"
  
  # 在子请求中传递更新的元数据
  context.enqueue_links('.subcategory', {
    metadata: {
      category: category,
      depth: depth + 1,
      parent_url: context.request.url
    }
  })
end
```

#### 优化请求队列大小

避免将过多请求添加到队列中，这可能会导致内存问题。使用过滤器和限制来控制队列大小。

```ruby
# 在路由处理器中
crawler.router.default do |context|
  # 获取当前队列大小
  queue_size = crawler.request_queue.size
  
  # 如果队列太大，只添加高优先级的链接
  if queue_size > 10000
    puts "警告: 队列大小超过 10000，只添加高优先级链接"
    # 只添加重要的链接，如产品页面
    product_links = context.query_selector_all('.product-link').map { |a| a['href'] }.compact
    context.enqueue_links(product_links)
  else
    # 正常添加所有链接
    context.enqueue_links('a')
  end
end
```

#### 使用批量操作

尽可能使用批量操作而不是单个请求操作，以提高性能。

```ruby
# 批量添加请求
urls = ['https://example.com/page1', 'https://example.com/page2', 'https://example.com/page3']
requests = urls.map { |url| Crawlee::Request.new(url) }
crawler.request_queue.batch_add(requests)
```

### 3. 键值存储最佳实践

#### 使用键值存储进行配置

将爬虫配置存储在键值存储中，而不是硬编码在代码中，便于调整和管理。

```ruby
# 存储配置
crawler.key_value_store.set('config', {
  max_depth: 3,
  follow_external_links: false,
  user_agent: 'Crawlee-Ruby/1.0',
  request_delay: 1000
})

# 在路由处理器中使用配置
crawler.router.default do |context|
  config = crawler.key_value_store.get('config')
  
  # 使用配置参数
  if context.metadata[:depth] < config['max_depth']
    # 添加链接...
  end
  
  # 模拟请求延迟
  sleep(config['request_delay'] / 1000.0) if config['request_delay']
end
```

#### 使用键值存储跟踪状态

使用键值存储跟踪爬虫的运行状态，便于监控和恢复。

```ruby
# 在爬虫开始时初始化状态
crawler.key_value_store.set('crawler_state', {
  start_time: Time.now.to_i,
  status: 'running',
  processed_urls: 0,
  failed_urls: 0
})

# 在路由处理器中更新状态
crawler.router.default do |context|
  # 获取当前状态
  state = crawler.key_value_store.get('crawler_state')
  
  # 更新状态
  state['processed_urls'] += 1
  state['last_url'] = context.request.url
  state['last_processed_time'] = Time.now.to_i
  
  # 保存更新后的状态
  crawler.key_value_store.set('crawler_state', state)
  
  # 处理页面...
end

# 在爬虫结束时更新状态
begin
  crawler.run
  
  # 更新状态为完成
  state = crawler.key_value_store.get('crawler_state')
  state['status'] = 'completed'
  state['end_time'] = Time.now.to_i
  state['duration'] = state['end_time'] - state['start_time']
  crawler.key_value_store.set('crawler_state', state)
rescue => e
  # 更新状态为失败
  state = crawler.key_value_store.get('crawler_state')
  state['status'] = 'failed'
  state['error'] = e.message
  state['end_time'] = Time.now.to_i
  crawler.key_value_store.set('crawler_state', state)
  raise
end
```

### 4. 存储系统通用最佳实践

#### 使用有意义的命名

为数据集、请求队列和键值存储使用有意义的名称，便于组织和管理。

```ruby
# 好的命名方式
products_dataset = storage.dataset('electronics_products')
review_dataset = storage.dataset('product_reviews')

product_queue = storage.request_queue('product_pages')
review_queue = storage.request_queue('review_pages')

config_store = storage.key_value_store('crawler_config')
state_store = storage.key_value_store('crawler_state')

# 避免使用模糊的名称
# 不好的命名方式
dataset1 = storage.dataset('data1')
dataset2 = storage.dataset('data2')
```

#### 定期清理存储

定期清理不再需要的存储，以节省磁盘空间。

```ruby
# 在爬虫完成后清理临时存储
if crawler.key_value_store.get('crawler_state')['status'] == 'completed'
  # 导出最终数据
  final_data = crawler.dataset.get_data
  File.write('final_results.json', JSON.generate(final_data))
  
  # 清理临时存储
  crawler.key_value_store.delete('temp_data')
  crawler.key_value_store.delete('processing_state')
  
  # 清空请求队列
  crawler.request_queue.clear
end
```

#### 实现数据备份机制

定期备份重要数据，防止意外丢失。

```ruby
# 定期备份数据
def backup_data(crawler)
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  
  # 备份数据集
  data = crawler.dataset.get_data
  File.write("backup/dataset_#{timestamp}.json", JSON.generate(data))
  
  # 备份爬虫状态
  state = crawler.key_value_store.get('crawler_state')
  File.write("backup/state_#{timestamp}.json", JSON.generate(state))
  
  puts "数据已备份到 backup 目录"
end

# 每处理 5000 个页面备份一次
crawler.router.default do |context|
  # 处理页面...
  
  # 获取当前状态
  state = crawler.key_value_store.get('crawler_state') || { 'processed_urls' => 0 }
  state['processed_urls'] += 1
  crawler.key_value_store.set('crawler_state', state)
  
  # 每 5000 个页面备份一次
  if state['processed_urls'] % 5000 == 0
    backup_data(crawler)
  end
end
```
