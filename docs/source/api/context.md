# Context 类

Context 类是 Crawlee Ruby 框架中的核心组件之一，用于在处理请求时提供上下文信息和操作方法。Crawlee 框架提供了两种主要的上下文类：HttpContext 和 BrowserContext，分别用于 HttpCrawler 和 BrowserCrawler。本文档详细介绍了这两种上下文类的功能、方法和使用示例。

## 概述

Context 对象在路由处理器中作为参数传递，包含了当前请求和响应的信息，以及用于操作页面内容、提取数据、添加新请求等方法。Context 对象是爬虫与网页交互的主要接口。

### 为什么使用 Context

Context 对象提供了多种便利的功能，使爬虫开发更加高效和简洁：

1. **封装复杂性**：Context 封装了请求、响应和爬虫实例之间的交互，简化了 API。

2. **统一接口**：无论是 HTTP 爬虫还是浏览器爬虫，都提供了类似的接口，使代码更容易维护和迁移。

3. **方便的数据提取**：提供了简单直观的方法来查询和操作 DOM。

4. **请求管理**：提供了添加新请求和提取链接的方法。

5. **数据存储**：直接集成了数据存储功能。

## HttpContext 类

HttpContext 类用于 HttpCrawler，提供了处理 HTTP 请求和响应的方法。HttpContext 是路由处理器中最常用的对象，它封装了对网页内容的访问和操作。

### 属性

#### request

```ruby
attr_reader :request
```

获取当前请求对象。

**返回值：**
- `Crawlee::Request`: 当前请求对象。

**示例：**
```ruby
crawler.router.default do |context|
  puts "处理 URL: #{context.request.url}"
  puts "请求方法: #{context.request.method}"
  puts "请求头: #{context.request.headers}"
end
```

#### response

```ruby
attr_reader :response
```

获取当前响应对象。

**返回值：**
- `Crawlee::Response`: 当前响应对象。

**示例：**
```ruby
crawler.router.default do |context|
  puts "状态码: #{context.response.status_code}"
  puts "响应头: #{context.response.headers}"
  puts "响应体大小: #{context.response.body.size} 字节"
end
```

#### metadata

```ruby
attr_reader :metadata
```

获取请求的元数据。元数据是一个哈希表，可以在请求之间传递信息。

**返回值：**
- `Hash`: 请求的元数据。

**示例：**
```ruby
crawler.router.default do |context|
  # 获取元数据
  page_type = context.metadata[:page_type]
  
  # 根据页面类型处理
  case page_type
  when 'product'
    # 处理产品页面
  when 'category'
    # 处理分类页面
  end
end
```

### 方法

#### html

```ruby
def html
  @response.html
end
```

获取响应的 HTML 文档。

**返回值：**
- `Nokogiri::HTML::Document`: 解析后的 HTML 文档。

**示例：**
```ruby
crawler.router.default do |context|
  # 获取 HTML 文档
  doc = context.html
  
  # 使用 Nokogiri 方法操作文档
  title = doc.at_css('title').text
  puts "页面标题: #{title}"
end
```

#### query_selector_all

```ruby
def query_selector_all(selector)
  html.css(selector)
end
```

查找所有匹配 CSS 选择器的 HTML 元素。

**参数：**
- `selector` (String): CSS 选择器。

**返回值：**
- `Nokogiri::XML::NodeSet`: 匹配的元素集合。

**示例：**
```ruby
crawler.router.default do |context|
  # 查找所有产品元素
  products = context.query_selector_all('.product')
  
  # 遍历产品元素
  products.each do |product|
    title = product.at_css('.title').text.strip
    price = product.at_css('.price').text.strip
    
    # 保存数据
    context.save_data({
      title: title,
      price: price
    })
  end
end
```

#### query_selector

```ruby
def query_selector(selector)
  html.at_css(selector)
end
```

查找第一个匹配 CSS 选择器的 HTML 元素。

**参数：**
- `selector` (String): CSS 选择器。

**返回值：**
- `Nokogiri::XML::Element, nil`: 匹配的元素，如果没有匹配则返回 nil。

**示例：**
```ruby
crawler.router.default do |context|
  # 查找页面标题
  title_element = context.query_selector('h1.page-title')
  
  if title_element
    puts "页面标题: #{title_element.text.strip}"
  else
    puts "未找到页面标题"
  end
end
```

#### enqueue_links

```ruby
def enqueue_links(selector = 'a', options = {})
  # 实现细节
end
```

从页面提取链接并添加到请求队列。

**参数：**
- `selector` (String): CSS 选择器，默认为 'a'。
- `options` (Hash): 请求选项，将应用于所有提取的链接。

**返回值：**
- `Integer`: 添加到队列的链接数量。

**示例：**
```ruby
crawler.router.default do |context|
  # 提取所有产品链接
  context.enqueue_links('.product-link', {
    label: 'product',
    metadata: {
      page_type: 'product'
    }
  })
end
```

#### save_data

```ruby
def save_data(data)
  @crawler.save_data(data)
end
```

保存数据到数据集。

**参数：**
- `data` (Hash): 要保存的数据。

**返回值：**
- `Hash`: 带有 ID 的数据。

**示例：**
```ruby
crawler.router.default do |context|
  # 提取产品信息
  title = context.query_selector('.product-title')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    timestamp: Time.now
  })
end
```

#### enqueue

```ruby
def enqueue(url_or_request, options = {})
  @crawler.enqueue(url_or_request, options)
end
```

添加请求到队列。

**参数：**
- `url_or_request` (String, Crawlee::Request): URL 或请求对象。
- `options` (Hash): 请求选项。

**返回值：**
- `Boolean`: 是否成功添加。

**示例：**
```ruby
crawler.router.default do |context|
  # 添加下一页到队列
  next_page = context.query_selector('.pagination .next')
  
  if next_page && next_page['href']
    context.enqueue(next_page['href'], {
      metadata: {
        page_type: 'listing',
        page_number: context.metadata[:page_number].to_i + 1
      }
    })
  end
end
```

### 高级用法

#### 使用 XPath 选择器

除了使用 CSS 选择器外，您还可以使用 XPath 选择器来定位元素：

```ruby
crawler.router.default do |context|
  # 使用 XPath 选择器查找元素
  product_names = context.html.xpath('//div[@class="product"]//h2[@class="name"]').map(&:text)
  
  # 使用 XPath 查找包含特定文本的元素
  sale_items = context.html.xpath('//div[contains(text(), "特价商品")]')
  
  # 使用 XPath 查找具有特定属性的元素
  featured_products = context.html.xpath('//div[@data-featured="true"]')
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    product_names: product_names,
    sale_items_count: sale_items.size,
    featured_products_count: featured_products.size
  })
end
```

#### 处理动态生成的内容

对于使用 JavaScript 动态生成的内容，您可能需要使用 BrowserCrawler。但在某些情况下，您可以使用 HttpContext 处理简单的 JSON 响应：

```ruby
crawler.router.add('/api/products') do |context|
  # 处理 JSON API 响应
  begin
    json_data = JSON.parse(context.response.body)
    
    # 提取产品数据
    products = json_data['products'] || []
    
    # 保存每个产品
    products.each do |product|
      context.save_data({
        id: product['id'],
        name: product['name'],
        price: product['price'],
        category: product['category'],
        url: "#{context.request.url.split('?').first}/#{product['id']}"
      })
    end
    
    # 处理分页
    if json_data['pagination'] && json_data['pagination']['next_page']
      next_page_url = "#{context.request.url.split('?').first}?page=#{json_data['pagination']['next_page']}"
      context.enqueue(next_page_url, { metadata: context.metadata })
    end
  rescue JSON::ParserError => e
    Crawlee.logger.error("JSON 解析错误: #{e.message}")
  end
end
```

#### 使用正则表达式提取数据

当 CSS 选择器不足以精确提取数据时，可以使用正则表达式：

```ruby
crawler.router.default do |context|
  # 获取页面内容
  content = context.response.body
  
  # 使用正则表达式提取价格
  price_match = content.match(/\b\u4ef7\u683c[\s:]*([\d,.]+)\s*\u5143\b/i)
  price = price_match ? price_match[1].gsub(/[^\d.]/, '') : nil
  
  # 使用正则表达式提取电话号码
  phone_match = content.match(/\b(1[3-9]\d{9})\b/)
  phone = phone_match ? phone_match[1] : nil
  
  # 使用正则表达式提取电子邮箱
  email_match = content.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/)
  email = email_match ? email_match[0] : nil
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    price: price,
    phone: phone,
    email: email
  })
end
```

#### 处理多种页面类型

使用元数据来区分和处理不同类型的页面：

```ruby
# 设置路由处理器
crawler.router.default do |context|
  # 获取页面类型
  page_type = context.metadata[:page_type] || detect_page_type(context)
  
  # 根据页面类型处理
  case page_type
  when 'listing'
    process_listing_page(context)
  when 'product'
    process_product_page(context)
  when 'category'
    process_category_page(context)
  else
    process_unknown_page(context)
  end
end

# 检测页面类型
def detect_page_type(context)
  if context.query_selector('.product-list')
    'listing'
  elsif context.query_selector('.product-detail')
    'product'
  elsif context.query_selector('.category-list')
    'category'
  else
    'unknown'
  end
end

# 处理列表页
def process_listing_page(context)
  # 提取产品链接
  product_links = context.query_selector_all('.product-item a')
  
  product_links.each do |link|
    context.enqueue(link['href'], {
      metadata: { page_type: 'product' }
    })
  end
  
  # 处理分页
  next_page = context.query_selector('.pagination .next')
  if next_page && next_page['href']
    context.enqueue(next_page['href'], {
      metadata: { page_type: 'listing' }
    })
  end
end

# 处理产品页
def process_product_page(context)
  # 提取产品信息
  title = context.query_selector('h1.product-title')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  description = context.query_selector('.product-description')&.text&.strip
  
  # 保存产品数据
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    description: description,
    type: 'product'
  })
end
```

## BrowserContext 类

BrowserContext 类用于 BrowserCrawler，提供了处理浏览器页面的方法。BrowserContext 继承了 HttpContext 的所有方法，并添加了一些特定于浏览器操作的方法。

BrowserContext 特别适合爬取需要执行 JavaScript 的动态网页，如单页应用、需要登录的网站或需要交互的网页。

### 属性

BrowserContext 继承了 HttpContext 的所有属性（request, response, metadata），并添加了以下特定属性：

#### page

```ruby
attr_reader :page
```

获取当前浏览器页面对象。

**返回值：**
- `Puppeteer::Page`: 当前浏览器页面对象。

**示例：**
```ruby
crawler.router.default do |context|
  # 使用 page 对象执行浏览器操作
  context.page.click('.button')
  context.page.type('.input', 'Hello, World!')
end
```

### 方法

除了继承自 HttpContext 的方法外，BrowserContext 还提供了以下特定方法：

#### wait_for_selector

```ruby
def wait_for_selector(selector, options = {})
  page.wait_for_selector(selector, options)
end
```

等待指定的选择器出现在页面上。

**参数：**
- `selector` (String): CSS 选择器。
- `options` (Hash): 等待选项，如 timeout。

**返回值：**
- `Puppeteer::ElementHandle`: 匹配的元素句柄。

**示例：**
```ruby
crawler.router.default do |context|
  # 等待产品列表加载
  context.wait_for_selector('.product-list', { timeout: 10000 })
  
  # 现在可以安全地提取产品信息
  products = context.query_selector_all('.product')
  # ...
end
```

#### click

```ruby
def click(selector, options = {})
  page.click(selector, options)
end
```

点击页面上的元素。

**参数：**
- `selector` (String): CSS 选择器。
- `options` (Hash): 点击选项，如 button, clickCount。

**示例：**
```ruby
crawler.router.default do |context|
  # 点击"加载更多"按钮
  context.click('.load-more-button')
  
  # 等待新内容加载
  context.wait_for_selector('.product:nth-child(20)')
  
  # 提取新加载的内容
  # ...
end
```

#### type

```ruby
def type(selector, text, options = {})
  page.type(selector, text, options)
end
```

在输入框中输入文本。

**参数：**
- `selector` (String): CSS 选择器。
- `text` (String): 要输入的文本。
- `options` (Hash): 输入选项，如 delay。

**示例：**
```ruby
crawler.router.default do |context|
  # 在搜索框中输入关键词
  context.type('.search-input', '手机', { delay: 100 })
  
  # 点击搜索按钮
  context.click('.search-button')
  
  # 等待搜索结果加载
  context.wait_for_selector('.search-results')
end
```

#### evaluate

```ruby
def evaluate(script, *args)
  page.evaluate(script, *args)
end
```

在页面上下文中执行 JavaScript 代码。

**参数：**
- `script` (String, Proc): 要执行的 JavaScript 代码或函数。
- `*args`: 传递给脚本的参数。

**返回值：**
- 脚本执行的结果。

**示例：**
```ruby
crawler.router.default do |context|
  # 获取页面上的所有图片 URL
  image_urls = context.evaluate(<<-JS)
    Array.from(document.querySelectorAll('img')).map(img => img.src)
  JS
  
  # 保存图片 URL
  image_urls.each do |url|
    context.save_data({ image_url: url })
  end
end
```

#### screenshot

```ruby
def screenshot(options = {})
  page.screenshot(options)
end
```

截取页面截图。

**参数：**
- `options` (Hash): 截图选项，如 path, fullPage。

**返回值：**
- `String`: 截图的二进制数据。

**示例：**
```ruby
crawler.router.default do |context|
  # 截取全页面截图
  context.screenshot({
    path: "screenshots/#{Time.now.to_i}.png",
    full_page: true
  })
end
```

### 高级用法

#### 处理单页应用 (SPA)

对于使用 React、Vue 或 Angular 等框架构建的单页应用，可以使用 BrowserContext 有效地爬取动态内容：

```ruby
crawler.router.default do |context|
  # 等待内容加载
  context.wait_for_selector('.content-loaded', { timeout: 10000 })
  
  # 模拟用户交互，如点击“加载更多”按钮
  load_more_button = context.query_selector('.load-more-button')
  if load_more_button
    # 点击加载更多按钮 3 次
    3.times do
      context.click('.load-more-button')
      # 等待新内容加载
      sleep(1)
    end
  end
  
  # 现在提取所有加载的内容
  items = context.query_selector_all('.item')
  items.each do |item|
    title = item.at_css('.title')&.text&.strip
    description = item.at_css('.description')&.text&.strip
    
    context.save_data({
      title: title,
      description: description
    })
  end
  
  # 使用 JavaScript 提取隐藏数据
  hidden_data = context.evaluate(<<-JS)
    // 获取存储在全局变量中的数据
    window.__INITIAL_DATA__ || {}
  JS
  
  if hidden_data.is_a?(Hash) && !hidden_data.empty?
    context.save_data(hidden_data)
  end
end
```

#### 处理登录和认证

对于需要登录的网站，可以使用 BrowserContext 模拟登录过程：

```ruby
# 创建一个登录处理器
crawler.router.add('/login') do |context|
  # 等待登录表单加载
  context.wait_for_selector('form')
  
  # 输入用户名和密码
  context.type('#username', 'your_username')
  context.type('#password', 'your_password')
  
  # 点击登录按钮
  context.click('#login-button')
  
  # 等待登录成功，可能是重定向到主页或出现特定元素
  context.wait_for_selector('.dashboard', { timeout: 10000 })
  
  # 登录成功后，添加需要爬取的受保护页面
  context.enqueue('https://example.com/dashboard')
  context.enqueue('https://example.com/profile')
  context.enqueue('https://example.com/settings')
end

# 处理仪表板页面
crawler.router.add('/dashboard') do |context|
  # 等待页面加载
  context.wait_for_selector('.dashboard-content')
  
  # 提取用户信息
  username = context.query_selector('.user-name')&.text&.strip
  account_type = context.query_selector('.account-type')&.text&.strip
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    username: username,
    account_type: account_type,
    page_type: 'dashboard'
  })
end
```

#### 处理无限滚动页面

对于使用无限滚动加载更多内容的页面：

```ruby
crawler.router.default do |context|
  # 等待初始内容加载
  context.wait_for_selector('.items-container')
  
  # 设置最大滚动次数
  max_scrolls = 5
  current_scrolls = 0
  
  # 记录已经看到的项目数量
  previous_items_count = 0
  
  # 滚动并加载更多内容
  while current_scrolls < max_scrolls
    # 获取当前项目数量
    items_count = context.evaluate('document.querySelectorAll(".item").length')
    
    # 如果没有新项目加载，停止滚动
    break if items_count == previous_items_count
    
    previous_items_count = items_count
    
    # 滚动到页面底部
    context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
    
    # 等待新内容加载
    sleep(2)
    
    current_scrolls += 1
  end
  
  # 提取所有加载的项目
  items = context.query_selector_all('.item')
  
  puts "共加载了 #{items.size} 个项目"
  
  # 提取和保存数据
  items.each do |item|
    title = item.at_css('.title')&.text&.strip
    link = item.at_css('a')&.[]('href')
    
    context.save_data({
      title: title,
      link: link,
      url: context.request.url
    })
  end
end
```

#### 处理复杂的交互元素

对于需要复杂交互的页面，如下拉菜单、模态窗口、拖放操作等：

```ruby
crawler.router.default do |context|
  # 等待页面加载
  context.wait_for_selector('.interactive-element')
  
  # 处理下拉菜单
  context.click('.dropdown-toggle')
  context.wait_for_selector('.dropdown-menu')
  context.click('.dropdown-item:nth-child(2)')
  
  # 处理模态窗口
  context.click('.open-modal-button')
  context.wait_for_selector('.modal-content')
  
  # 在模态窗口中填写表单
  context.type('.modal-input', 'Test input')
  context.click('.modal-submit')
  
  # 等待模态窗口关闭
  context.wait_for_selector('.modal-content', { state: 'hidden' })
  
  # 使用高级 JavaScript 执行复杂操作
  context.evaluate(<<-JS)
    // 模拟拖放操作
    const source = document.querySelector('.draggable-item');
    const target = document.querySelector('.drop-zone');
    
    if (source && target) {
      // 创建拖放事件
      const dragStartEvent = new MouseEvent('dragstart');
      const dragOverEvent = new MouseEvent('dragover');
      const dropEvent = new MouseEvent('drop');
      
      // 设置数据传输
      Object.defineProperty(dragStartEvent, 'dataTransfer', {
        value: { setData: () => {}, getData: () => {} }
      });
      
      Object.defineProperty(dropEvent, 'dataTransfer', {
        value: { setData: () => {}, getData: () => {} }
      });
      
      // 触发事件
      source.dispatchEvent(dragStartEvent);
      target.dispatchEvent(dragOverEvent);
      target.dispatchEvent(dropEvent);
    }
  JS
end
```

## 完整示例

### HttpContext 示例

```ruby
require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 设置路由处理器
crawler.router.default do |context|
  # 提取产品信息
  products = context.query_selector_all('.product')
  
  products.each do |product|
    title = product.at_css('.title')&.text&.strip
    price = product.at_css('.price')&.text&.strip
    url = product.at_css('a')['href']
    
    # 保存数据
    context.save_data({
      title: title,
      price: price,
      url: url
    })
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
```

### BrowserContext 示例

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  headless: true,
  launch_options: {
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
)

# 设置路由处理器
crawler.router.default do |context|
  # 等待产品列表加载
  context.wait_for_selector('.product-list')
  
  # 点击"加载更多"按钮，直到没有更多产品
  loop do
    load_more = context.query_selector('.load-more-button')
    break unless load_more && load_more.visible?
    
    context.click('.load-more-button')
    sleep 1  # 等待内容加载
  end
  
  # 提取所有产品信息
  products = context.query_selector_all('.product')
  
  products.each do |product|
    title = product.at_css('.title')&.text&.strip
    price = product.at_css('.price')&.text&.strip
    
    # 保存数据
    context.save_data({
      title: title,
      price: price,
      url: context.request.url
    })
  end
  
  # 提取分类链接
  context.enqueue_links('.category-link', {
    metadata: {
      page_type: 'category'
    }
  })
end

# 添加起始 URL
crawler.enqueue('https://example.com/products')

# 运行爬虫
crawler.run
```

## 最佳实践

1. **使用元数据传递信息**：使用请求的元数据在不同的请求之间传递信息，如页面类型、页码等。

   ```ruby
   # 在列表页中传递元数据到产品页
   context.enqueue(product_url, {
     metadata: {
       category: current_category,
       list_page: context.request.url,
       position: index
     }
   })
   ```

2. **错误处理**：在处理器中使用 `begin/rescue` 块捕获异常，确保一个页面的处理错误不会影响整个爬虫的运行。

   ```ruby
   crawler.router.default do |context|
     begin
       # 处理逻辑
     rescue => e
       puts "处理 #{context.request.url} 时出错: #{e.message}"
       Crawlee.logger.error(e.backtrace.join("\n"))
     end
   end
   ```

3. **等待动态内容**：在使用 BrowserContext 时，确保在提取内容之前等待页面完全加载。

   ```ruby
   # 设置足够的超时时间，处理慢速加载的页面
   context.wait_for_selector('.content-loaded', { timeout: 15000 })
   ```

4. **限制爬取范围**：使用 `enqueue_links` 的选择器参数限制爬取范围，只提取需要的链接。

   ```ruby
   # 只提取产品链接，并跳过已处理的链接
   context.enqueue_links('.product-link:not(.visited)')
   ```

5. **保存有用的元数据**：在保存数据时，包含有用的元数据，如 URL、时间戳等。

   ```ruby
   context.save_data({
     title: title,
     price: price,
     url: context.request.url,
     timestamp: Time.now.to_i,
     crawl_id: context.metadata[:crawl_id] || SecureRandom.uuid
   })
   ```

6. **使用选择器链**：使用选择器链精确定位元素，减少错误。

   ```ruby
   # 好的做法
   product.at_css('.product-info .title')
   
   # 不好的做法
   product.at_css('.title')
   ```

7. **使用空值处理**：在提取数据时使用安全的空值处理，避免空指针异常。

   ```ruby
   # 使用 &. 操作符和默认值
   title = context.query_selector('.title')&.text&.strip || 'Unknown Title'
   price = context.query_selector('.price')&.text&.strip || 'N/A'
   ```

8. **模块化处理逻辑**：将复杂的处理逻辑分解为小型、可重用的函数。

   ```ruby
   # 将数据提取逻辑分离
   def extract_product_data(context, product_element)
     {
       title: product_element.at_css('.title')&.text&.strip,
       price: product_element.at_css('.price')&.text&.strip,
       image: product_element.at_css('img')&.[]('src'),
       url: product_element.at_css('a')&.[]('href')
     }
   end
   
   # 在路由处理器中使用
   crawler.router.default do |context|
     products = context.query_selector_all('.product')
     products.each do |product|
       data = extract_product_data(context, product)
       context.save_data(data)
     end
   end
   ```

9. **使用条件检查处理特殊情况**：在处理不同类型的页面或内容时，使用条件检查确保处理逻辑的适用性。

   ```ruby
   # 检查页面类型并适当处理
   if context.query_selector('.out-of-stock')
     # 处理缺货产品
     context.save_data({ status: 'out_of_stock', url: context.request.url })
   elsif context.query_selector('.sale-item')
     # 处理特价商品
     # ...
   else
     # 处理普通商品
     # ...
   end
   ```

10. **避免过度爬取**：使用限制和过滤器避免爬取过多页面，尤其是在测试阶段。

    ```ruby
    # 限制爬取深度
    if (context.metadata[:depth] || 0) < 3
      context.enqueue_links('.next-page', {
        metadata: {
          depth: (context.metadata[:depth] || 0) + 1
        }
      })
    end
    ```
