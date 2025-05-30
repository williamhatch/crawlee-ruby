# BrowserCrawler

`BrowserCrawler` 是一个基于浏览器的爬虫类，用于抓取需要 JavaScript 渲染的网页内容。它继承自 `BaseCrawler`，提供了浏览器自动化功能，可以处理动态加载的内容、AJAX 请求和其他客户端渲染的元素。

`BrowserCrawler` 内部使用 Puppeteer 库来控制浏览器，使您能够自动化浏览器操作，如点击按钮、填写表单、滚动页面等，非常适合爬取现代 Web 应用和单页应用（SPA）。

## 初始化

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new(options = {})
```

### 选项

- `max_concurrency` (Integer): 最大并发请求数，默认为 5
- `headless` (Boolean): 是否使用无头模式，默认为 true
- `launch_options` (Hash): 浏览器启动选项
  - `args` (Array<String>): 浏览器启动参数，如 `['--no-sandbox', '--disable-setuid-sandbox']`
  - `executable_path` (String): 浏览器可执行文件路径
  - `timeout` (Integer): 浏览器启动超时时间（毫秒）
- `page_options` (Hash): 页面选项
  - `viewport` (Hash): 视口设置，如 `{ width: 1920, height: 1080 }`
  - `user_agent` (String): 用户代理字符串
  - `timeout` (Integer): 页面加载超时时间（毫秒）
- `max_retries` (Integer): 请求失败时的最大重试次数，默认为 3
- `exit_on_empty_queue` (Boolean): 队列为空时是否退出，默认为 true

### 初始化示例

#### 基本初始化

```ruby
# 创建默认配置的浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new
```

#### 自定义配置

```ruby
# 创建自定义配置的浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  max_concurrency: 10,  # 增加并发数
  headless: false,       # 可视化模式，便于调试
  launch_options: {
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--disable-gpu'
    ],
    timeout: 30000  # 30 秒启动超时
  },
  page_options: {
    viewport: { width: 1920, height: 1080 },  # 全高清分辨率
    user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    timeout: 60000  # 60 秒页面加载超时
  },
  max_retries: 5  # 增加重试次数
)
```

#### 使用代理

```ruby
# 使用代理的浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  launch_options: {
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--proxy-server=http://proxy.example.com:8080'  # 设置代理服务器
    ]
  }
)
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
  - `wait_for` (String, Array<String>): 等待选择器加载
  - `wait_for_timeout` (Integer): 等待选择器的超时时间（毫秒）

返回:
- (Boolean): 是否成功添加

### launch_browser

启动浏览器。通常不需要直接调用此方法，而是通过 `run` 方法自动调用。

```ruby
crawler.launch_browser(options = {})
```

参数:
- `options` (Hash): 浏览器启动选项，同初始化时的 `launch_options`

返回:
- (Browser): 浏览器实例

### close_browser

关闭浏览器。通常不需要直接调用此方法，而是通过 `run` 方法自动调用。

```ruby
crawler.close_browser
```

### goto_page

导航到指定页面。通常不需要直接调用此方法，而是通过 `process_request` 方法自动调用。

```ruby
crawler.goto_page(url, options = {})
```

参数:
- `url` (String): 要导航到的 URL
- `options` (Hash): 页面导航选项
  - `timeout` (Integer): 导航超时时间（毫秒）
  - `wait_until` (Symbol): 等待事件，如 `:load`, `:domcontentloaded`, `:networkidle`

返回:
- (Page): 页面实例

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

### 运行示例

#### 基本运行

```ruby
# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
stats = crawler.run
puts "爬取完成，共处理 #{stats[:requests_total]} 个请求，成功 #{stats[:requests_successful]} 个"
```

#### 处理运行异常

```ruby
begin
  # 添加起始 URL
  crawler.enqueue('https://example.com')
  
  # 运行爬虫
  stats = crawler.run
  puts "爬取完成，共处理 #{stats[:requests_total]} 个请求，成功 #{stats[:requests_successful]} 个"
rescue => e
  puts "爬虫运行出错: #{e.message}"
  puts e.backtrace.join("\n")
ensure
  # 确保浏览器被关闭
  crawler.close_browser rescue nil
end
```

## BrowserContext

`BrowserContext` 是 `BrowserCrawler` 提供的上下文对象，包含了当前请求、响应和页面对象，以及一系列用于操作页面的方法。它在路由处理器中作为参数传递，是您与网页交互的主要接口。

### 属性

- `request` (Crawlee::Request): 当前请求对象
- `response` (Crawlee::Response): 当前响应对象
- `page` (Page): 当前页面对象，Puppeteer 的 Page 实例
- `crawler` (Crawlee::Crawlers::BrowserCrawler): 爬虫实例
- `metadata` (Hash): 请求的元数据，可用于在请求之间传递信息

### 方法

#### query_selector

查询页面中的单个元素。

```ruby
context.query_selector(selector)
```

参数:
- `selector` (String): CSS 选择器

返回:
- (Element): 元素对象，如果未找到则返回 nil

#### query_selector_all

查询页面中的多个元素。

```ruby
context.query_selector_all(selector)
```

参数:
- `selector` (String): CSS 选择器

返回:
- (Array<Element>): 元素对象数组

#### evaluate

在页面上下文中执行 JavaScript 代码。

```ruby
context.evaluate(script, *args)
```

参数:
- `script` (String): JavaScript 代码
- `args` (Array): 传递给脚本的参数

返回:
- (Object): 脚本执行结果

#### save_data

保存数据到数据集。

```ruby
context.save_data(data)
```

参数:
- `data` (Hash): 要保存的数据

返回:
- (Hash): 带有 ID 的数据

#### enqueue_links

提取页面中的链接并添加到请求队列。

```ruby
context.enqueue_links(selector, options = {})
```

参数:
- `selector` (String): CSS 选择器，默认为 'a'
- `options` (Hash): 请求选项，同 `enqueue`

返回:
- (Integer): 成功添加的请求数量

#### wait_for_selector

等待选择器匹配的元素出现。

```ruby
context.wait_for_selector(selector, options = {})
```

参数:
- `selector` (String): CSS 选择器
- `options` (Hash): 等待选项
  - `visible` (Boolean): 是否等待元素可见
  - `hidden` (Boolean): 是否等待元素隐藏
  - `timeout` (Integer): 超时时间（毫秒）

返回:
- (ElementHandle): 元素句柄

示例:
```ruby
# 等待产品列表加载
context.wait_for_selector('.product-list')

# 等待加载动画消失
context.wait_for_selector('.loading-spinner', { hidden: true })

# 设置较长的超时时间
context.wait_for_selector('.slow-loading-element', { timeout: 30000 })
```
- `options` (Hash): 等待选项
  - `timeout` (Integer): 超时时间（毫秒）
  - `visible` (Boolean): 是否等待元素可见

返回:
- (Element): 元素对象

#### click

点击页面中的元素。

```ruby
context.click(selector, options = {})
```

参数:
- `selector` (String): CSS 选择器
- `options` (Hash): 点击选项
  - `button` (Symbol): 鼠标按钮，如 `:left`, `:right`, `:middle`
  - `click_count` (Integer): 点击次数
  - `delay` (Integer): 点击之间的延迟（毫秒）

#### type

在页面中的输入框中输入文本。

```ruby
context.type(selector, text, options = {})
```

参数:
- `selector` (String): CSS 选择器
- `text` (String): 要输入的文本
- `options` (Hash): 输入选项
  - `delay` (Integer): 输入延迟（毫秒）

#### screenshot

截取页面截图。

```ruby
context.screenshot(options = {})
```

参数:
- `options` (Hash): 截图选项
  - `path` (String): 保存路径
  - `full_page` (Boolean): 是否截取整个页面
  - `type` (Symbol): 截图类型，如 `:png`, `:jpeg`
  - `quality` (Integer): 图片质量（仅对 JPEG 有效）

返回:
- (Buffer): 截图数据

## 完整示例

以下是一些使用 `BrowserCrawler` 的完整示例，展示了不同场景下的用法。

### 示例 1: 基本电商网站爬虫

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  headless: true,
  max_concurrency: 5
)

# 设置产品页面处理器
crawler.router.add(/\/product\//) do |context|
  # 等待产品信息加载
  context.wait_for_selector('.product-details')
  
  # 提取产品信息
  title = context.query_selector('.product-title')&.text&.strip
  price = context.query_selector('.product-price')&.text&.strip
  description = context.query_selector('.product-description')&.text&.strip
  
  # 提取图片 URL
  image_urls = context.query_selector_all('.product-image').map do |img|
    img['src']
  end
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    price: price,
    description: description,
    image_urls: image_urls,
    timestamp: Time.now
  })
  
  # 提取相关产品链接
  context.enqueue_links('.related-product a')
end

# 设置分类页面处理器
crawler.router.add(/\/category\//) do |context|
  # 等待产品列表加载
  context.wait_for_selector('.product-list')
  
  # 滚动到页面底部以加载所有产品
  context.evaluate(<<-JS)
    window.scrollTo(0, document.body.scrollHeight);
  JS
  
  # 等待更多产品加载
  sleep 2
  
  # 提取产品链接
  context.enqueue_links('.product-item a')
  
  # 提取下一页链接
  next_page = context.query_selector('.pagination .next')
  if next_page && next_page['href']
    context.enqueue(next_page['href'])
  end
end

# 设置默认处理器
crawler.router.default do |context|
  # 提取所有链接
  context.enqueue_links('a')
end

# 添加起始 URL
crawler.enqueue('https://example.com/category/electronics')

# 运行爬虫
begin
  puts "开始爬取..."
  stats = crawler.run
  puts "爬取完成，共处理 #{stats[:requests_total]} 个请求，成功 #{stats[:requests_successful]} 个"
  
  # 输出爬取的数据
  data = crawler.dataset.get_data
  puts "共爬取 #{data.size} 个产品"
rescue => e
  puts "爬虫运行出错: #{e.message}"
ensure
  crawler.close_browser rescue nil
end
```

### 示例 2: 处理登录和会话

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  headless: true,
  max_concurrency: 2  # 降低并发以减少被封风险
)

# 登录处理器
crawler.router.add(/\/login/) do |context|
  puts "处理登录页面..."
  
  # 等待登录表单加载
  context.wait_for_selector('form.login-form')
  
  # 填写登录表单
  context.type('input[name="username"]', 'your_username')
  context.type('input[name="password"]', 'your_password')
  
  # 点击登录按钮
  context.click('button[type="submit"]')
  
  # 等待登录成功，跳转到仪表盘
  context.wait_for_selector('.dashboard')
  
  puts "登录成功！"
  
  # 导航到目标页面
  context.enqueue('/dashboard/reports')
end

# 报告页面处理器
crawler.router.add(/\/dashboard\/reports/) do |context|
  puts "处理报告页面..."
  
  # 等待报告列表加载
  context.wait_for_selector('.report-list')
  
  # 提取报告数据
  reports = context.query_selector_all('.report-item').map do |item|
    {
      title: item.at_css('.report-title')&.text&.strip,
      date: item.at_css('.report-date')&.text&.strip,
      status: item.at_css('.report-status')&.text&.strip
    }
  end
  
  # 保存数据
  reports.each do |report|
    context.save_data(report)
  end
  
  puts "提取了 #{reports.size} 个报告"
end

# 添加登录页面作为起始点
crawler.enqueue('https://example.com/login')

# 运行爬虫
begin
  puts "开始爬取..."
  crawler.run
  puts "爬取完成"
rescue => e
  puts "爬虫运行出错: #{e.message}"
ensure
  crawler.close_browser rescue nil
end
```

### 示例 3: 处理无限滚动页面

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  headless: true,
  page_options: {
    viewport: { width: 1920, height: 1080 }  # 使用大视口
  }
)

# 设置无限滚动页面处理器
crawler.router.default do |context|
  puts "处理页面: #{context.request.url}"
  
  # 等待内容加载
  context.wait_for_selector('.content-item')
  
  # 初始化计数器
  item_count = 0
  max_items = 100  # 最多爬取的项目数
  last_count = 0
  
  # 循环滚动直到没有新内容或达到最大项目数
  10.times do |i|
    # 获取当前项目数
    items = context.query_selector_all('.content-item')
    item_count = items.size
    
    puts "已加载 #{item_count} 个项目"
    
    # 如果没有新内容或达到最大项目数，则退出循环
    break if item_count >= max_items || item_count == last_count
    
    # 记录当前项目数
    last_count = item_count
    
    # 滚动到页面底部
    context.evaluate(<<-JS)
      window.scrollTo(0, document.body.scrollHeight);
    JS
    
    # 等待新内容加载
    sleep 2
  end
  
  # 提取所有项目数据
  items = context.query_selector_all('.content-item')
  
  items.each do |item|
    # 提取数据
    title = item.at_css('.item-title')&.text&.strip
    description = item.at_css('.item-description')&.text&.strip
    
    # 保存数据
    context.save_data({
      title: title,
      description: description,
      url: context.request.url
    })
  end
  
  puts "共提取 #{items.size} 个项目的数据"
end

# 添加起始 URL
crawler.enqueue('https://example.com/infinite-scroll-page')

# 运行爬虫
crawler.run
```

## 最佳实践

以下是使用 `BrowserCrawler` 的一些最佳实践：

### 1. 合理设置并发数

根据目标网站的承受能力和您的网络带宽调整并发请求数。过高的并发可能导致 IP 被封禁。

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new(max_concurrency: 3)  # 降低并发
```

### 2. 使用无头模式提高性能

在生产环境中使用无头模式可以显著提高性能和减少资源消耗。

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new(headless: true)
```

### 3. 设置合理的超时时间

为浏览器启动和页面加载设置合理的超时时间，避免长时间等待。

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  launch_options: { timeout: 30000 },  # 30 秒浏览器启动超时
  page_options: { timeout: 60000 }     # 60 秒页面加载超时
)
```

### 4. 使用等待选择器确保内容加载

在提取内容前，使用 `wait_for_selector` 确保页面内容已完全加载。

```ruby
context.wait_for_selector('.content-loaded')
```

### 5. 模拟真实用户行为

添加随机延迟、模拟鼠标移动和滚动等操作，使爬虫行为更像真实用户。

```ruby
# 随机延迟
sleep rand(1..3)

# 模拟滚动
context.evaluate(<<-JS)
  window.scrollBy(0, #{rand(100..300)});
JS
```

### 6. 使用代理轮换 IP

使用代理服务轮换 IP 地址，避免被目标网站封禁。

```ruby
proxies = [
  'http://proxy1.example.com:8080',
  'http://proxy2.example.com:8080',
  'http://proxy3.example.com:8080'
]

crawler = Crawlee::Crawlers::BrowserCrawler.new(
  launch_options: {
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      "--proxy-server=#{proxies.sample}"  # 随机选择代理
    ]
  }
)
```

### 7. 合理使用资源

在处理完请求后关闭浏览器，释放资源。

```ruby
begin
  crawler.run
ensure
  crawler.close_browser rescue nil
end
```

### 8. 错误处理和重试

实现健壮的错误处理和重试机制，确保爬虫能够处理各种异常情况。

```ruby
crawler.router.default do |context|
  begin
    # 处理逻辑
  rescue => e
    puts "处理 #{context.request.url} 时出错: #{e.message}"
    
    # 记录错误并决定是否重试
    if context.request.retry_count < 3
      puts "将重试请求..."
      context.enqueue(context.request.url, {
        retry_count: context.request.retry_count + 1
      })
    else
      puts "已达到最大重试次数，放弃请求"
    end
  end
end
```

### 9. 遵守网站规则

尊重网站的 robots.txt 规则和使用条款，设置合理的爬取频率和范围。

```ruby
# 检查 robots.txt
require 'robotstxt'

parser = Robotstxt.parse(URI.open('https://example.com/robots.txt').read)
if parser.allowed?('https://example.com/some-path', 'CrawleeBot')
  crawler.enqueue('https://example.com/some-path')
else
  puts "robots.txt 不允许爬取此路径"
end
```

### 10. 数据验证和清洗

在保存数据前进行验证和清洗，确保数据质量。

```ruby
crawler.router.default do |context|
  # 提取数据
  title = context.query_selector('.title')&.text&.strip
  price = context.query_selector('.price')&.text&.strip
  
  # 数据验证和清洗
  if title.nil? || title.empty?
    puts "警告: 标题为空"
    title = "未知标题"
  end
  
  # 清洗价格数据
  if price
    price = price.gsub(/[^0-9.]/, '')  # 只保留数字和小数点
    price = price.to_f               # 转换为浮点数
  end
  
  # 保存数据
  context.save_data({
    title: title,
    price: price
  })
end
```
    # 递归处理当前页面
    context.router.route(context)
  end
  
  # 提取并跟踪链接
  context.enqueue_links('a.product-link')
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

## 处理登录和认证

```ruby
# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(headless: false)

# 登录处理器
crawler.router.add(/\/login/) do |context|
  # 填写登录表单
  context.type('#username', 'your_username')
  context.type('#password', 'your_password')
  
  # 提交表单
  context.click('button[type="submit"]')
  
  # 等待登录成功
  context.wait_for_selector('.dashboard')
  
  # 保存 Cookie 以便后续使用
  cookies = context.evaluate('document.cookie')
  crawler.key_value_store.set('cookies', cookies)
end

# 添加登录页面作为起始点
crawler.enqueue('https://example.com/login')
```
