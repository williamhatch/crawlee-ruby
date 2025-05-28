# 高级爬虫技巧

本指南介绍了使用 Crawlee Ruby 进行高级爬虫开发的技巧和最佳实践。

## 处理分页

许多网站使用分页来展示大量数据。以下是处理分页的示例：

```ruby
crawler.router.default_handler do |context|
  # 处理当前页面数据
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
  
  # 查找下一页链接
  next_page = context.query_selector('a.next-page')
  if next_page && next_page['href']
    # 将下一页添加到队列
    context.enqueue(next_page['href'])
  end
end
```

## 处理登录和会话

有些网站需要登录才能访问某些内容。以下是处理登录的示例：

```ruby
# 创建爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new

# 登录处理器
crawler.router.add(/\/login/) do |context|
  # 提交登录表单
  login_url = 'https://example.com/login'
  
  crawler.enqueue(login_url, {
    method: :post,
    payload: {
      username: 'your_username',
      password: 'your_password'
    },
    metadata: {
      type: 'login'
    }
  })
end

# 登录成功后的处理器
crawler.router.add(/\/dashboard/) do |context|
  # 现在已经登录，可以访问受保护的内容
  puts "成功登录，当前页面: #{context.request.url}"
  
  # 提取并访问受保护的链接
  context.enqueue_links('.protected-content a')
end

# 添加登录页面作为起始点
crawler.enqueue('https://example.com/login')
```

## 处理 AJAX 和动态内容

对于包含 AJAX 和动态内容的网站，可以使用 `BrowserCrawler`：

```ruby
# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  headless: true,  # 无头模式
  launch_options: {
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
)

# 设置路由处理器
crawler.router.default_handler do |context|
  # 等待动态内容加载
  context.page.wait_for_selector('.dynamic-content')
  
  # 现在可以提取动态加载的内容
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
    load_more.click
    # 等待新内容加载
    context.page.wait_for_selector('.item:nth-child(20)')
    # 递归处理当前页面
    context.router.route(context)
  end
end
```

## 使用代理

为了避免 IP 被封禁，可以使用代理：

```ruby
# 创建爬虫并配置代理
crawler = Crawlee::Crawlers::HttpCrawler.new(
  proxy_configuration: {
    proxies: [
      'http://proxy1.example.com:8080',
      'http://proxy2.example.com:8080'
    ]
  }
)
```

## 错误处理和重试

Crawlee Ruby 内置了错误处理和重试机制：

```ruby
# 创建爬虫并配置重试
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_retries: 5,  # 最大重试次数
  retry_delay: 1000  # 重试延迟（毫秒）
)

# 自定义错误处理
crawler.router.default_handler do |context|
  begin
    # 处理逻辑
  rescue => e
    puts "处理 #{context.request.url} 时出错: #{e.message}"
    # 可以决定是否重试
    if e.is_a?(Timeout::Error)
      context.request.retry_count = 0  # 重置重试计数
      crawler.enqueue(context.request)
    end
  end
end
```

## 限制爬取范围

为了避免爬虫无限制地爬取，可以限制爬取范围：

```ruby
crawler.router.default_handler do |context|
  # 只处理特定域名的 URL
  domain = URI.parse(context.request.url).host
  
  # 提取链接
  links = context.query_selector_all('a').map { |a| a['href'] }.compact
  
  # 过滤链接，只保留同一域名的链接
  same_domain_links = links.select do |link|
    begin
      link_domain = URI.parse(link).host
      link_domain == domain
    rescue URI::InvalidURIError
      false
    end
  end
  
  # 将过滤后的链接添加到队列
  same_domain_links.each do |link|
    context.enqueue(link)
  end
end
```

## 数据后处理

爬取完成后，可以对数据进行后处理：

```ruby
# 运行爬虫
crawler.run

# 获取数据集
dataset = crawler.dataset

# 读取所有数据
all_data = dataset.get_data

# 数据处理
processed_data = all_data.map do |item|
  # 处理每个数据项
  item[:processed_at] = Time.now.to_i
  item
end

# 导出为 CSV
require 'csv'

CSV.open('output.csv', 'wb') do |csv|
  # 添加表头
  csv << processed_data.first.keys
  
  # 添加数据行
  processed_data.each do |item|
    csv << item.values
  end
end

puts "数据已导出到 output.csv"
```

## 性能优化

提高爬虫性能的一些技巧：

1. **调整并发数**：根据目标网站的承受能力和您的网络带宽调整并发请求数。

   ```ruby
   crawler = Crawlee::Crawlers::HttpCrawler.new(max_concurrency: 10)
   ```

2. **使用缓存**：缓存已访问的页面，避免重复请求。

   ```ruby
   # 使用键值存储作为缓存
   key_value_store = crawler.key_value_store
   
   crawler.router.default_handler do |context|
     url = context.request.url
     cache_key = "cache:#{Digest::MD5.hexdigest(url)}"
     
     # 尝试从缓存获取
     cached_data = key_value_store.get(cache_key)
     if cached_data
       puts "使用缓存数据: #{url}"
       return
     end
     
     # 处理页面并缓存结果
     data = {
       url: url,
       title: context.query_selector('title')&.text,
       timestamp: Time.now.to_i
     }
     
     key_value_store.set(cache_key, data)
     context.save_data(data)
   end
   ```

3. **使用适当的爬虫类型**：对于简单的静态页面，使用 `HttpCrawler`；对于复杂的动态页面，使用 `BrowserCrawler`。

4. **限制请求深度**：避免无限递归，限制爬取深度。

   ```ruby
   crawler.router.default_handler do |context|
     # 获取当前深度
     depth = context.request.metadata[:depth] || 0
     
     # 如果深度超过限制，则不再继续
     return if depth >= 3
     
     # 处理页面...
     
     # 提取链接并设置深度
     context.enqueue_links('a', {
       metadata: {
         depth: depth + 1
       }
     })
   end
   ```

通过应用这些高级技巧，您可以构建更强大、更高效的爬虫应用程序。
