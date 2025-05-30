# Router 类

Router 类是 Crawlee Ruby 框架中的核心组件之一，负责根据 URL 模式将请求路由到相应的处理器函数。本文档详细介绍了 Router 类的功能、方法和使用示例。

## 概述

Router 类允许您为不同的 URL 模式定义不同的处理逻辑，使爬虫代码更加模块化和可维护。您可以使用正则表达式或字符串模式来匹配 URL，并为每个匹配的模式定义一个处理器函数。

Router 类是 BaseCrawler 的内部类，通常通过爬虫实例的 `router` 属性访问。

## 方法

### 初始化

```ruby
def initialize
  @routes = {}
  @default_handler = nil
end
```

创建一个新的 Router 实例。通常不需要直接调用此方法，因为爬虫实例会自动创建一个 Router 实例。

### add

```ruby
def add(pattern, &handler)
  @routes[pattern] = handler
  self
end
```

添加一个新的路由规则。

**参数：**
- `pattern` (Regexp, String): 用于匹配 URL 的模式。可以是正则表达式或字符串。
- `handler` (Proc): 处理匹配 URL 的回调函数。接收一个 Context 对象作为参数。

**返回值：**
- `self` (Router): 返回 Router 实例本身，支持链式调用。

**示例：**
```ruby
# 使用正则表达式匹配
crawler.router.add(/\/product\/\d+/) do |context|
  # 处理产品页面
  puts "处理产品页面: #{context.request.url}"
end

# 使用字符串匹配
crawler.router.add('/category') do |context|
  # 处理分类页面
  puts "处理分类页面: #{context.request.url}"
end
```

### default

```ruby
def default(&handler)
  @default_handler = handler
  self
end
```

设置默认处理器，当没有匹配的路由规则时使用。

**参数：**
- `handler` (Proc): 默认处理器函数。接收一个 Context 对象作为参数。

**返回值：**
- `self` (Router): 返回 Router 实例本身，支持链式调用。

**示例：**
```ruby
crawler.router.default do |context|
  # 默认处理逻辑
  puts "默认处理: #{context.request.url}"
end
```

### default_handler

```ruby
def default_handler(&handler)
  @default_handler = handler
end
```

设置默认处理器的另一种方式。功能与 `default` 方法相同，但不返回 Router 实例。

**参数：**
- `handler` (Proc): 默认处理器函数。接收一个 Context 对象作为参数。

**示例：**
```ruby
crawler.router.default_handler do |context|
  # 默认处理逻辑
  puts "默认处理: #{context.request.url}"
end
```

### route

```ruby
def route(context)
  # 实现细节
end
```

根据请求的 URL 路由到相应的处理器。

**参数：**
- `context` (Crawlee::Context): 请求上下文对象。

**说明：**
此方法会遍历所有已注册的路由规则，找到第一个匹配当前 URL 的规则，并调用相应的处理器函数。如果没有匹配的规则，则调用默认处理器（如果已设置）。

通常不需要直接调用此方法，因为爬虫会在处理请求时自动调用它。

## 路由匹配规则

Router 类支持两种类型的路由模式：

1. **正则表达式**：使用正则表达式匹配 URL。这是最灵活的匹配方式，可以匹配复杂的 URL 模式。

   ```ruby
   # 匹配所有以 /product/ 开头，后跟数字的 URL
   crawler.router.add(/\/product\/\d+/) do |context|
     # 处理逻辑
   end
   ```

2. **字符串**：使用字符串匹配 URL。如果 URL 包含指定的字符串，则认为匹配成功。

   ```ruby
   # 匹配所有包含 '/category' 的 URL
   crawler.router.add('/category') do |context|
     # 处理逻辑
   end
   ```

## 路由优先级

路由规则按照添加的顺序进行匹配。当多个规则可能匹配同一个 URL 时，将使用第一个匹配的规则。

```ruby
# 这个规则会先匹配
crawler.router.add('/product') do |context|
  puts "匹配产品页面"
end

# 如果 URL 同时包含 '/product' 和 '/special'，这个规则不会被触发
crawler.router.add('/product/special') do |context|
  puts "匹配特殊产品页面"
end
```

为了避免这种情况，可以调整规则的添加顺序，将更具体的规则放在前面：

```ruby
# 先添加更具体的规则
crawler.router.add('/product/special') do |context|
  puts "匹配特殊产品页面"
end

# 再添加更通用的规则
crawler.router.add('/product') do |context|
  puts "匹配产品页面"
end
```

## 完整示例

以下是一个使用 Router 类的完整示例：

```ruby
require 'crawlee'

# 创建爬虫实例
crawler = Crawlee::Crawlers::HttpCrawler.new

# 添加路由规则
crawler.router.add(/\/product\/\d+/) do |context|
  # 提取产品信息
  title = context.query_selector('.product-title')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    price: price
  })
end

crawler.router.add('/category') do |context|
  # 提取产品链接并添加到队列
  context.enqueue_links('.product-link')
end

# 设置默认处理器
crawler.router.default do |context|
  puts "处理页面: #{context.request.url}"
  
  # 提取所有链接并添加到队列
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

## 高级用法

### 使用元数据传递信息

您可以在请求中添加元数据，并在路由处理器中使用它：

```ruby
# 添加带元数据的请求
crawler.enqueue('https://example.com/category/electronics', {
  metadata: {
    category: 'electronics',
    depth: 1,
    parent_url: 'https://example.com'
  }
})

# 在路由处理器中使用元数据
crawler.router.add('/category/') do |context|
  category = context.metadata[:category]
  depth = context.metadata[:depth] || 0
  
  puts "处理分类: #{category}, 深度: #{depth}"
  
  # 如果深度不超过限制，继续爬取子页面
  if depth < 3
    context.query_selector_all('.subcategory-link').each do |element|
      subcategory_url = element['href']
      subcategory_name = element.text.strip
      
      # 将元数据传递给下一个请求
      context.enqueue(subcategory_url, {
        metadata: {
          category: subcategory_name,
          depth: depth + 1,
          parent_url: context.request.url
        }
      })
    end
  end
end
```

### 条件路由

您可以在路由处理器中实现条件路由，根据页面内容决定如何处理：

```ruby
crawler.router.add('/product/') do |context|
  # 检查页面是否存在
  if context.response.status_code == 404
    puts "产品页面不存在: #{context.request.url}"
    return
  end
  
  # 检查是否是有效的产品页面
  product_title = context.query_selector('.product-title')
  if product_title.nil?
    puts "非标准产品页面: #{context.request.url}"
    return
  end
  
  # 检查产品是否有货
  in_stock = context.query_selector('.in-stock')
  if in_stock.nil?
    puts "产品缺货: #{context.request.url}"
    context.save_data({
      url: context.request.url,
      title: product_title.text.strip,
      status: 'out_of_stock'
    })
    return
  end
  
  # 处理正常产品
  price = context.query_selector('.price')&.text&.strip
  description = context.query_selector('.description')&.text&.strip
  
  context.save_data({
    url: context.request.url,
    title: product_title.text.strip,
    price: price,
    description: description,
    status: 'in_stock'
  })
end
```

### 定义路由模块

对于复杂的爬虫，您可以将路由处理逻辑组织成模块：

```ruby
# 产品页面处理模块
module ProductPageHandler
  def self.handle(context)
    title = context.query_selector('.product-title')&.text&.strip
    price = context.query_selector('.price')&.text&.strip
    
    context.save_data({
      url: context.request.url,
      title: title,
      price: price,
      type: 'product'
    })
  end
end

# 分类页面处理模块
module CategoryPageHandler
  def self.handle(context)
    category_name = context.query_selector('h1')&.text&.strip
    
    # 保存分类信息
    context.save_data({
      url: context.request.url,
      category: category_name,
      type: 'category'
    })
    
    # 提取产品链接
    context.enqueue_links('.product-link')
    
    # 提取分页链接
    context.enqueue_links('.pagination a')
  end
end

# 在路由中使用模块
crawler.router.add(/\/product\/\d+/) do |context|
  ProductPageHandler.handle(context)
end

crawler.router.add('/category') do |context|
  CategoryPageHandler.handle(context)
end
```

### 使用正则表达式捕获参数

您可以使用正则表达式捕获 URL 中的参数：

```ruby
# 使用正则表达式捕获产品 ID
crawler.router.add(/\/product\/(\d+)/) do |context|
  # 获取 URL
  url = context.request.url
  
  # 使用正则表达式提取产品 ID
  product_id = url.match(/\/product\/(\d+)/)[1]
  
  puts "处理产品 ID: #{product_id}"
  
  # 使用产品 ID 获取更多信息
  context.save_data({
    url: url,
    product_id: product_id,
    title: context.query_selector('.product-title')&.text&.strip
  })
end
```

## 最佳实践

1. **组织路由规则**：将相关的路由规则组织在一起，使代码更易于理解和维护。

2. **使用具体的匹配模式**：尽量使用具体的匹配模式，避免过于宽泛的模式导致意外匹配。

3. **注意规则顺序**：更具体的规则应该放在更通用的规则之前。

4. **始终设置默认处理器**：设置默认处理器可以确保所有请求都能得到处理，即使没有匹配的规则。

5. **在处理器中使用适当的错误处理**：在处理器函数中使用 `begin/rescue` 块捕获异常，确保一个页面的处理错误不会影响整个爬虫的运行。

   ```ruby
   crawler.router.default do |context|
     begin
       # 处理逻辑
     rescue => e
       puts "处理 #{context.request.url} 时出错: #{e.message}"
     end
   end
   ```

6. **使用元数据传递上下文信息**：利用请求的元数据字段传递上下文信息，如爬取深度、父页面等。

7. **分离关注点**：将数据提取、页面导航和数据存储逻辑分开，使处理器函数更清晰。

8. **使用注释说明路由目的**：为每个路由规则添加注释，说明其目的和处理的页面类型。
