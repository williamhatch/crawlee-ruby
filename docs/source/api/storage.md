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
