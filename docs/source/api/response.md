# Response

`Response` 类表示一个 HTTP 响应，包含状态码、头部、正文等信息。它是 Crawlee Ruby 框架中的核心类之一，用于处理和解析服务器返回的响应数据。

## 初始化

```ruby
response = Crawlee::Response.new(request, options = {})
```

### 参数

- `request` (Crawlee::Request): 对应的请求对象
- `options` (Hash): 响应选项
  - `status_code` (Integer): HTTP 状态码，默认为 200
  - `headers` (Hash): 响应头
  - `body` (String): 响应体
  - `url` (String): 响应的 URL，默认为请求的 URL
  - `request_time` (Float): 请求耗时（秒）

## 属性

### request

对应的请求对象。

```ruby
response.request
```

### status_code

HTTP 状态码。

```ruby
response.status_code
```

### headers

响应头。

```ruby
response.headers
```

### body

响应体。

```ruby
response.body
```

### url

响应的 URL。

```ruby
response.url
```

### request_time

请求耗时（秒）。

```ruby
response.request_time
```

## 方法

### success?

检查响应是否成功（状态码在 200-299 之间）。

```ruby
response.success?
```

返回:
- (Boolean): 如果状态码在 200-299 之间，则返回 true

### error?

检查响应是否为错误（状态码在 400-599 之间）。

```ruby
response.error?
```

返回:
- (Boolean): 如果状态码在 400-599 之间，则返回 true

### client_error?

检查响应是否为客户端错误（状态码在 400-499 之间）。

```ruby
response.client_error?
```

返回:
- (Boolean): 如果状态码在 400-499 之间，则返回 true

### server_error?

检查响应是否为服务器错误（状态码在 500-599 之间）。

```ruby
response.server_error?
```

返回:
- (Boolean): 如果状态码在 500-599 之间，则返回 true

### html?

检查响应是否为 HTML 内容。

```ruby
response.html?
```

返回:
- (Boolean): 如果 Content-Type 头部包含 "text/html"，则返回 true

### json?

检查响应是否为 JSON 内容。

```ruby
response.json?
```

返回:
- (Boolean): 如果 Content-Type 头部包含 "application/json"，则返回 true

### xml?

检查响应是否为 XML 内容。

```ruby
response.xml?
```

返回:
- (Boolean): 如果 Content-Type 头部包含 "application/xml" 或 "text/xml"，则返回 true

### text?

检查响应是否为文本内容。

```ruby
response.text?
```

返回:
- (Boolean): 如果 Content-Type 头部包含 "text/"，则返回 true

### binary?

检查响应是否为二进制内容。

```ruby
response.binary?
```

返回:
- (Boolean): 如果响应不是文本内容，则返回 true

### json

将响应体解析为 JSON 对象。

```ruby
response.json
```

返回:
- (Hash, Array): 解析后的 JSON 对象

异常:
- (JSON::ParserError): 如果响应体不是有效的 JSON

### xml

将响应体解析为 XML 对象。

```ruby
response.xml
```

返回:
- (Nokogiri::XML::Document): 解析后的 XML 对象

### html

将响应体解析为 HTML 对象。

```ruby
response.html
```

返回:
- (Nokogiri::HTML::Document): 解析后的 HTML 对象

### query_selector

查询 HTML 响应中的单个元素。

```ruby
response.query_selector(selector)
```

参数:
- `selector` (String): CSS 选择器

返回:
- (Nokogiri::XML::Element): 元素对象，如果未找到则返回 nil

### query_selector_all

查询 HTML 响应中的多个元素。

```ruby
response.query_selector_all(selector)
```

参数:
- `selector` (String): CSS 选择器

返回:
- (Array<Nokogiri::XML::Element>): 元素对象数组

## 示例

### 基本用法

```ruby
# 创建一个请求
request = Crawlee::Request.new('https://example.com')

# 创建一个响应
response = Crawlee::Response.new(request, 
  status_code: 200,
  headers: {
    'Content-Type' => 'text/html; charset=UTF-8'
  },
  body: '<html><head><title>示例页面</title></head><body><h1>Hello World</h1></body></html>'
)

# 检查响应状态
puts "响应成功: #{response.success?}"
puts "状态码: #{response.status_code}"

# 检查内容类型
puts "是 HTML: #{response.html?}"
puts "是 JSON: #{response.json?}"

# 解析 HTML
if response.html?
  html = response.html
  title = html.at_css('title').text
  puts "页面标题: #{title}"
end
```

### 使用选择器

```ruby
# 使用 query_selector 和 query_selector_all 方法
title = response.query_selector('title')
puts "页面标题: #{title.text}" if title

headings = response.query_selector_all('h1, h2, h3')
puts "找到 #{headings.size} 个标题:"
headings.each do |heading|
  puts "- #{heading.name}: #{heading.text}"
end
```

### 处理 JSON 响应

```ruby
# 创建一个 JSON 响应
json_response = Crawlee::Response.new(request, 
  status_code: 200,
  headers: {
    'Content-Type' => 'application/json; charset=UTF-8'
  },
  body: '{"name": "Crawlee", "version": "0.2.0", "features": ["http", "browser"]}'
)

# 检查内容类型
puts "是 JSON: #{json_response.json?}"

# 解析 JSON
if json_response.json?
  data = json_response.json
  puts "名称: #{data['name']}"
  puts "版本: #{data['version']}"
  puts "功能: #{data['features'].join(', ')}"
end
```

### 处理错误响应

```ruby
# 创建一个错误响应
error_response = Crawlee::Response.new(request, 
  status_code: 404,
  headers: {
    'Content-Type' => 'text/html; charset=UTF-8'
  },
  body: '<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1></body></html>'
)

# 检查错误状态
puts "响应成功: #{error_response.success?}"
puts "响应错误: #{error_response.error?}"
puts "客户端错误: #{error_response.client_error?}"
puts "服务器错误: #{error_response.server_error?}"

# 根据状态码处理不同情况
case error_response.status_code
when 404
  puts "页面不存在"
when 403
  puts "访问被禁止"
when 500..599
  puts "服务器错误"
else
  puts "其他错误: #{error_response.status_code}"
end
```
