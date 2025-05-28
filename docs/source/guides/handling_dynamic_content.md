# 处理动态内容

现代网站大量使用 JavaScript 动态加载内容，这给传统的 HTTP 爬虫带来了挑战。本指南将介绍如何使用 Crawlee Ruby 框架处理动态内容，确保您能够爬取到完整的网页数据。

## 动态内容的挑战

传统的 HTTP 爬虫只能获取服务器返回的初始 HTML，无法执行 JavaScript 代码，因此无法获取动态加载的内容。常见的动态内容包括：

1. AJAX 加载的数据
2. 无限滚动加载的内容
3. 点击按钮后显示的内容
4. 延迟加载的图片和媒体
5. 单页应用程序 (SPA) 的内容

## 使用 BrowserCrawler

Crawlee Ruby 提供了 `BrowserCrawler` 类，它基于浏览器自动化技术，可以执行 JavaScript 并获取动态加载的内容。

### 基本用法

```ruby
require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  max_concurrency: 2,  # 设置最大并发请求数
  headless: true       # 使用无头模式
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 等待页面加载完成
  context.wait_for_selector('.content')
  
  # 获取动态加载的内容
  title = context.query_selector('title')&.text
  content = context.query_selector('.content')&.text
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    title: title,
    content: content
  })
end

# 添加起始 URL
crawler.enqueue('https://example.com')

# 运行爬虫
crawler.run
```

### 等待内容加载

处理动态内容的关键是确保内容已经加载完成。Crawlee Ruby 提供了多种方法来等待内容加载：

#### 等待选择器

```ruby
# 等待特定元素出现
context.wait_for_selector('.content')

# 设置超时时间（毫秒）
context.wait_for_selector('.content', timeout: 10000)

# 等待元素可见
context.wait_for_selector('.content', visible: true)
```

#### 等待函数

```ruby
# 等待页面加载完成
context.page.wait_for_load_state('load')

# 等待网络空闲
context.page.wait_for_load_state('networkidle')
```

#### 等待时间

```ruby
# 等待固定时间（秒）
sleep 2
```

### 处理无限滚动

许多网站使用无限滚动加载更多内容。以下是处理无限滚动的示例：

```ruby
crawler.router.default_handler do |context|
  # 等待初始内容加载
  context.wait_for_selector('.item')
  
  # 初始化已加载的项目数
  items_count = 0
  
  # 滚动加载更多内容，直到没有新内容或达到最大滚动次数
  5.times do |i|
    # 获取当前项目数
    current_items = context.query_selector_all('.item').size
    
    # 如果没有新项目，则停止滚动
    break if current_items == items_count
    
    # 更新项目数
    items_count = current_items
    puts "已加载 #{items_count} 个项目，继续滚动..."
    
    # 滚动到页面底部
    context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
    
    # 等待新内容加载
    sleep 2
  end
  
  # 提取所有加载的项目
  items = context.query_selector_all('.item').map do |item|
    {
      title: item.at_css('.title')&.text&.strip,
      description: item.at_css('.description')&.text&.strip
    }
  end
  
  # 保存数据
  items.each do |item|
    context.save_data(item)
  end
  
  puts "共爬取 #{items.size} 个项目"
end
```

### 点击交互

有些内容需要点击按钮或链接才能显示。以下是处理点击交互的示例：

```ruby
crawler.router.default_handler do |context|
  # 等待页面加载完成
  context.wait_for_selector('.content')
  
  # 点击"加载更多"按钮
  if context.query_selector('.load-more')
    context.click('.load-more')
    
    # 等待新内容加载
    context.wait_for_selector('.item:nth-child(10)')
  end
  
  # 点击标签切换内容
  if context.query_selector('.tab')
    # 点击第二个标签
    context.click('.tab:nth-child(2)')
    
    # 等待标签内容加载
    context.wait_for_selector('.tab-content')
  end
  
  # 提取内容
  # ...
end
```

### 处理弹窗和对话框

有些网站会显示弹窗或对话框，需要处理它们才能继续爬取：

```ruby
# 设置对话框处理器
context.page.on('dialog') do |dialog|
  puts "检测到对话框: #{dialog.message}"
  
  # 接受对话框（点击确定）
  dialog.accept
  
  # 或者拒绝对话框（点击取消）
  # dialog.dismiss
end

# 处理 Cookie 同意弹窗
if context.query_selector('.cookie-consent')
  context.click('.cookie-consent .accept')
  context.wait_for_selector('.cookie-consent', state: 'hidden')
end
```

### 填写表单

有些内容需要填写表单才能访问：

```ruby
crawler.router.add(/\/login/) do |context|
  # 等待表单加载
  context.wait_for_selector('form')
  
  # 填写表单
  context.type('#username', 'your_username')
  context.type('#password', 'your_password')
  
  # 提交表单
  context.click('button[type="submit"]')
  
  # 等待登录成功
  context.wait_for_selector('.dashboard')
end
```

## 优化策略

### 使用选择性渲染

有时不需要对所有页面都使用浏览器爬虫，可以根据需要选择性地使用：

```ruby
# 创建自适应爬虫
crawler = Crawlee::Crawlers::AdaptiveCrawler.new

# 对于需要 JavaScript 渲染的页面使用浏览器爬虫
crawler.router.add(/dynamic-page/) do |context|
  # 使用浏览器模式
  context.use_browser_mode
  
  # 等待动态内容加载
  context.wait_for_selector('.dynamic-content')
  
  # 提取内容
  # ...
end

# 对于静态页面使用 HTTP 爬虫
crawler.router.add(/static-page/) do |context|
  # 使用 HTTP 模式
  context.use_http_mode
  
  # 提取内容
  # ...
end
```

### 缓存策略

对于频繁访问的动态页面，可以实现缓存策略：

```ruby
crawler.router.default_handler do |context|
  url = context.request.url
  cache_key = "cache:#{Digest::MD5.hexdigest(url)}"
  
  # 尝试从缓存获取
  cached_data = crawler.key_value_store.get(cache_key)
  if cached_data && Time.now.to_i - cached_data['timestamp'] < 3600  # 缓存有效期 1 小时
    puts "使用缓存数据: #{url}"
    return
  end
  
  # 等待动态内容加载
  context.wait_for_selector('.content')
  
  # 提取内容
  title = context.query_selector('title')&.text
  content = context.query_selector('.content')&.text
  
  # 保存数据
  data = {
    url: url,
    title: title,
    content: content,
    timestamp: Time.now.to_i
  }
  
  context.save_data(data)
  
  # 更新缓存
  crawler.key_value_store.set(cache_key, data)
end
```

## 处理常见问题

### 处理延迟加载的图片

```ruby
crawler.router.default_handler do |context|
  # 等待页面加载完成
  context.wait_for_selector('.content')
  
  # 滚动页面以触发图片懒加载
  context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
  
  # 等待图片加载
  context.wait_for_selector('img[src]')
  
  # 提取图片
  images = context.query_selector_all('img[src]').map do |img|
    img['src']
  end
  
  # 保存数据
  context.save_data({
    url: context.request.url,
    images: images
  })
end
```

### 处理 SPA 路由

```ruby
crawler.router.default_handler do |context|
  # 等待 SPA 应用加载完成
  context.wait_for_selector('.app')
  
  # 获取所有导航链接
  nav_links = context.query_selector_all('nav a').map do |link|
    link['href']
  end
  
  # 点击每个导航链接并提取内容
  nav_links.each do |link|
    # 点击链接
    context.click("nav a[href='#{link}']")
    
    # 等待内容加载
    context.wait_for_selector('.content')
    
    # 提取内容
    title = context.query_selector('h1')&.text
    content = context.query_selector('.content')&.text
    
    # 保存数据
    context.save_data({
      url: "#{context.request.url}#{link}",
      title: title,
      content: content
    })
  end
end
```

### 处理 iframe

```ruby
crawler.router.default_handler do |context|
  # 等待 iframe 加载
  context.wait_for_selector('iframe')
  
  # 获取所有 iframe
  iframes = context.query_selector_all('iframe')
  
  # 处理每个 iframe
  iframes.each_with_index do |iframe, index|
    # 切换到 iframe
    frame = context.page.frame(iframe)
    next unless frame
    
    # 在 iframe 中提取内容
    title = frame.query_selector('title')&.text
    content = frame.query_selector('.content')&.text
    
    # 保存数据
    context.save_data({
      url: context.request.url,
      iframe_index: index,
      title: title,
      content: content
    })
  end
end
```

## 性能考虑

使用浏览器爬虫处理动态内容会消耗更多资源，因此需要注意以下几点：

1. **限制并发数**：浏览器爬虫的并发数应该比 HTTP 爬虫小，通常设置为 2-5 个
2. **使用无头模式**：无头模式可以减少资源消耗
3. **关闭不必要的功能**：如禁用图片加载、禁用 CSS 等
4. **及时关闭浏览器**：使用完毕后及时关闭浏览器释放资源
5. **选择性渲染**：只对需要 JavaScript 渲染的页面使用浏览器爬虫

## 示例：爬取动态加载的商品列表

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

# 商品列表页面处理器
crawler.router.add(/\/products/) do |context|
  puts "处理商品列表页面: #{context.request.url}"
  
  # 等待页面加载完成
  context.wait_for_selector('.product-grid')
  
  # 初始化已加载的商品数
  products_count = 0
  
  # 滚动加载更多商品，直到没有新商品或达到最大滚动次数
  5.times do |i|
    # 获取当前商品数
    current_products = context.query_selector_all('.product-item').size
    
    # 如果没有新商品，则停止滚动
    break if current_products == products_count
    
    # 更新商品数
    products_count = current_products
    puts "已加载 #{products_count} 个商品，继续滚动..."
    
    # 滚动到页面底部
    context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
    
    # 等待新商品加载
    sleep 2
  end
  
  # 提取所有加载的商品
  products = context.query_selector_all('.product-item').map do |product|
    {
      title: product.at_css('.product-title')&.text&.strip,
      price: product.at_css('.product-price')&.text&.strip,
      image: product.at_css('.product-image img')&.[]('src'),
      url: product.at_css('.product-title a')&.[]('href')
    }
  end
  
  # 保存商品数据
  products.each do |product|
    context.save_data(product)
  end
  
  puts "共爬取 #{products.size} 个商品"
  
  # 如果有下一页按钮，点击进入下一页
  next_button = context.query_selector('.pagination .next')
  if next_button
    next_url = next_button['href']
    
    # 确保 URL 是绝对路径
    if next_url
      next_url = "https://example.com#{next_url}" if next_url.start_with?('/')
      
      # 添加下一页到队列
      crawler.enqueue(next_url)
      puts "已添加下一页: #{next_url}"
    end
  end
end

# 添加起始 URL
crawler.enqueue('https://example.com/products')

# 运行爬虫
crawler.run
```

## 总结

处理动态内容是现代网页爬虫的重要能力。通过使用 Crawlee Ruby 的 `BrowserCrawler` 类，您可以轻松处理各种动态加载的内容，包括 AJAX 请求、无限滚动、点击交互等。关键是要确保内容已经加载完成，并根据具体情况选择合适的等待策略。

同时，由于浏览器爬虫会消耗更多资源，应该合理设置并发数和使用无头模式，以及实现缓存策略来提高性能。对于不需要 JavaScript 渲染的页面，可以继续使用更高效的 HTTP 爬虫。
