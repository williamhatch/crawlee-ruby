# Request

`Request` 类表示一个 HTTP 请求，包含 URL、方法、头部、负载等信息。它是 Crawlee Ruby 框架中的核心类之一，用于定义爬虫需要处理的请求。

## 初始化

```ruby
request = Crawlee::Request.new(url, options = {})
```

### 参数

- `url` (String): 请求的 URL
- `options` (Hash): 请求选项
  - `method` (Symbol): HTTP 方法，如 `:get`, `:post` 等，默认为 `:get`
  - `headers` (Hash): 请求头
  - `payload` (Hash, String): 请求体
  - `metadata` (Hash): 元数据，可用于存储与请求相关的自定义数据
  - `retry_count` (Integer): 当前重试次数，默认为 0
  - `max_retries` (Integer): 最大重试次数，默认为 3
  - `id` (String): 请求的唯一标识符，如果不提供则自动生成
  - `fingerprint` (String): 请求的指纹，用于去重，如果不提供则自动生成

## 属性

### url

请求的 URL。

```ruby
request.url
```

### method

HTTP 方法，如 `:get`, `:post` 等。

```ruby
request.method
```

### headers

请求头。

```ruby
request.headers
```

### payload

请求体。

```ruby
request.payload
```

### metadata

元数据，可用于存储与请求相关的自定义数据。

```ruby
request.metadata
```

### retry_count

当前重试次数。

```ruby
request.retry_count
```

### max_retries

最大重试次数。

```ruby
request.max_retries
```

### id

请求的唯一标识符。

```ruby
request.id
```

### fingerprint

请求的指纹，用于去重。

```ruby
request.fingerprint
```

## 方法

### to_h

将请求转换为哈希表示。

```ruby
request.to_h
```

返回:
- (Hash): 请求的哈希表示

### can_retry?

检查请求是否可以重试。

```ruby
request.can_retry?
```

返回:
- (Boolean): 如果 `retry_count` 小于 `max_retries`，则返回 true

### retry!

增加重试计数。

```ruby
request.retry!
```

返回:
- (Integer): 新的重试计数

### ==(other)

比较两个请求是否相等。

```ruby
request == other_request
```

参数:
- `other` (Crawlee::Request): 要比较的另一个请求

返回:
- (Boolean): 如果两个请求的指纹相同，则返回 true

## 示例

### 创建基本请求

```ruby
# 创建一个简单的 GET 请求
request = Crawlee::Request.new('https://example.com')

# 创建一个带有自定义头部的 GET 请求
request = Crawlee::Request.new('https://example.com', 
  headers: {
    'User-Agent' => 'Crawlee Ruby/0.2.0',
    'Accept-Language' => 'zh-CN,zh;q=0.9'
  }
)
```

### 创建 POST 请求

```ruby
# 创建一个 POST 请求，带有表单数据
request = Crawlee::Request.new('https://example.com/login', 
  method: :post,
  headers: {
    'Content-Type' => 'application/x-www-form-urlencoded'
  },
  payload: {
    username: 'user',
    password: 'pass'
  }
)

# 创建一个 POST 请求，带有 JSON 数据
request = Crawlee::Request.new('https://api.example.com/data', 
  method: :post,
  headers: {
    'Content-Type' => 'application/json'
  },
  payload: {
    query: 'crawlee',
    limit: 10
  }.to_json
)
```

### 使用元数据

```ruby
# 创建一个带有元数据的请求
request = Crawlee::Request.new('https://example.com/product/123', 
  metadata: {
    category: 'electronics',
    product_id: 123,
    depth: 2
  }
)

# 在路由处理器中使用元数据
crawler.router.default_handler do |context|
  request = context.request
  
  # 获取元数据
  category = request.metadata[:category]
  product_id = request.metadata[:product_id]
  depth = request.metadata[:depth]
  
  puts "处理产品页面: #{product_id}，分类: #{category}，深度: #{depth}"
  
  # 更新元数据并添加新请求
  crawler.enqueue('https://example.com/related', 
    metadata: {
      parent_id: product_id,
      depth: depth + 1
    }
  )
end
```

### 处理重试

```ruby
# 手动处理请求重试
begin
  response = http_client.request(request)
rescue => e
  if request.can_retry?
    puts "请求失败，正在重试 (#{request.retry_count + 1}/#{request.max_retries})"
    request.retry!
    retry
  else
    puts "请求失败，已达到最大重试次数"
    raise e
  end
end
```
