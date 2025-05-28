# BrowserCrawler

`BrowserCrawler` 是一个基于浏览器的爬虫类，用于抓取需要 JavaScript 渲染的网页内容。它继承自 `BaseCrawler`，提供了浏览器自动化功能，可以处理动态加载的内容、AJAX 请求和其他客户端渲染的元素。

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

## BrowserContext

`BrowserContext` 是 `BrowserCrawler` 提供的上下文对象，包含了当前请求、响应和页面对象，以及一系列用于操作页面的方法。

### 属性

- `request` (Crawlee::Request): 当前请求对象
- `response` (Crawlee::Response): 当前响应对象
- `page` (Page): 当前页面对象
- `crawler` (Crawlee::Crawlers::BrowserCrawler): 爬虫实例

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

## 示例

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  max_concurrency: 2,
  headless: true,
  launch_options: {
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 等待页面加载完成
  context.wait_for_selector('.content')
  
  # 获取页面标题
  title = context.query_selector('title')&.text
  puts "页面标题: #{title}"
  
  # 提取动态加载的内容
  items = context.query_selector_all('.item').map do |item|
    {
      title: item.at_css('.title')&.text&.strip,
      price: item.at_css('.price')&.text&.strip
    }
  end
  
  # 保存数据
  items.each do |item|
    context.save_data(item)
  end
  
  # 点击"加载更多"按钮
  load_more = context.query_selector('button.load-more')
  if load_more
    context.click('button.load-more')
    # 等待新内容加载
    context.wait_for_selector('.item:nth-child(20)')
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
