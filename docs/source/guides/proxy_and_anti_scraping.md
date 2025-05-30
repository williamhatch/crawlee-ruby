# 代理和反爬虫指南

在进行网络爬虫开发时，处理网站的反爬虫机制是一项重要的工作。本指南将介绍如何使用 Crawlee Ruby 框架配置代理服务器和应对常见的反爬虫技术。

## 目录

- [代理服务器配置](#代理服务器配置)
  - [配置单个代理](#配置单个代理)
  - [配置代理池](#配置代理池)
  - [代理轮换策略](#代理轮换策略)
- [应对常见反爬虫技术](#应对常见反爬虫技术)
  - [请求频率限制](#请求频率限制)
  - [用户代理（User-Agent）管理](#用户代理管理)
  - [Cookie 和会话管理](#cookie-和会话管理)
  - [浏览器指纹处理](#浏览器指纹处理)
- [高级技巧](#高级技巧)
  - [IP 封禁检测与处理](#ip-封禁检测与处理)
  - [验证码处理](#验证码处理)
  - [登录和认证](#登录和认证)
- [最佳实践](#最佳实践)

## 代理服务器配置

代理服务器是绕过 IP 封禁和请求限制的有效方法。Crawlee Ruby 提供了灵活的代理配置选项。

### 配置单个代理

使用单个代理服务器的最简单方法是在全局配置中设置：

```ruby
Crawlee.configure do |config|
  config.configure_proxy(['http://username:password@proxy.example.com:8080'])
end
```

或者在创建爬虫实例时配置：

```ruby
crawler = Crawlee::Crawlers::HttpCrawler.new(
  proxy_configuration: {
    urls: ['http://username:password@proxy.example.com:8080'],
    rotation: :default
  }
)
```

### 配置代理池

对于大规模爬取，建议使用多个代理服务器组成的代理池：

```ruby
Crawlee.configure do |config|
  config.configure_proxy([
    'http://username:password@proxy1.example.com:8080',
    'http://username:password@proxy2.example.com:8080',
    'http://username:password@proxy3.example.com:8080'
  ], rotation: :round_robin)
end
```

### 代理轮换策略

Crawlee Ruby 支持多种代理轮换策略：

- `:default`：使用第一个代理
- `:round_robin`：轮流使用每个代理
- `:random`：随机选择代理

```ruby
# 随机选择代理
Crawlee.configure do |config|
  config.configure_proxy(proxy_urls, rotation: :random)
end
```

## 应对常见反爬虫技术

### 请求频率限制

控制请求频率可以避免触发网站的反爬虫机制：

```ruby
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2,  # 限制并发请求数
  request_handler_timeout: 5  # 请求之间的延迟（秒）
)
```

实现自定义请求延迟：

```ruby
crawler.router.default_handler do |context|
  # 随机延迟 1-5 秒
  sleep(1 + rand(4))
  # 处理页面...
end
```

### 用户代理管理

定期轮换用户代理可以模拟不同的浏览器和设备：

```ruby
# 用户代理列表
user_agents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36'
]

# 在请求处理器中轮换用户代理
crawler.router.default_handler do |context|
  next_url = context.extract_url_from_page
  if next_url
    crawler.enqueue(next_url, headers: {
      'User-Agent' => user_agents.sample
    })
  end
end
```

### Cookie 和会话管理

Crawlee Ruby 自动管理 Cookie 和会话，但有时需要手动控制：

```ruby
# 获取会话
session = crawler.session_pool.get_session('example.com')

# 添加自定义 Cookie
session[:cookies]['session_id'] = 'your_session_id'
session[:cookies]['user_preference'] = 'dark_mode'

# 使用会话发送请求
crawler.enqueue('https://example.com/dashboard', session: session)
```

### 浏览器指纹处理

使用 BrowserCrawler 时，可以配置浏览器参数来改变指纹：

```ruby
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  launch_options: {
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--disable-gpu',
      '--window-size=1920,1080'
    ],
    ignoreHTTPSErrors: true
  }
)
```

## 高级技巧

### IP 封禁检测与处理

检测 IP 是否被封禁并自动切换代理：

```ruby
crawler.router.default_handler do |context|
  if ip_is_banned?(context)
    # 标记当前代理为已封禁
    mark_proxy_as_banned(context.request.proxy_url)
    
    # 使用新代理重新入队
    new_request = context.request.clone
    new_request.retry_count = 0  # 重置重试计数
    crawler.enqueue(new_request, use_new_proxy: true)
    return
  end
  
  # 正常处理页面...
end

def ip_is_banned?(context)
  # 检查页面内容或状态码判断是否被封
  context.response.status_code == 403 ||
    context.html.css('body').text.include?('访问受限') ||
    context.html.css('title').text.include?('安全验证')
end

# 实现代理管理类
def mark_proxy_as_banned(proxy_url)
  # 将代理添加到被封禁列表
  banned_proxies = Crawlee.storage.key_value('proxy_management').get('banned_proxies') || []
  banned_proxies << proxy_url unless banned_proxies.include?(proxy_url)
  Crawlee.storage.key_value('proxy_management').set('banned_proxies', banned_proxies)
  
  # 记录封禁时间
  Crawlee.logger.warn("代理 #{proxy_url} 被封禁，已添加到黑名单")
  
  # 可以设置定时任务清理过期的封禁代理
  # 比如 24 小时后解封
  Thread.new do
    sleep(24 * 60 * 60)
    unban_proxy(proxy_url)
  end
end

def unban_proxy(proxy_url)
  banned_proxies = Crawlee.storage.key_value('proxy_management').get('banned_proxies') || []
  banned_proxies.delete(proxy_url)
  Crawlee.storage.key_value('proxy_management').set('banned_proxies', banned_proxies)
  Crawlee.logger.info("代理 #{proxy_url} 已从黑名单中移除")
end
```

### 验证码处理

对于简单验证码，可以使用 OCR 服务：

```ruby
require 'tesseract-ocr'

crawler.router.add('/captcha-page') do |context|
  # 下载验证码图片
  captcha_img = context.query_selector('img#captcha')
  img_src = captcha_img['src']
  img_data = download_image(img_src)
  
  # 使用 OCR 识别验证码
  engine = Tesseract::Engine.new
  captcha_text = engine.text_for(img_data).strip
  
  # 提交表单
  context.evaluate(<<~JS)
    document.querySelector('input#captcha').value = '#{captcha_text}';
    document.querySelector('form').submit();
  JS
end

# 下载图片的辅助方法
def download_image(url)
  require 'open-uri'
  require 'tempfile'
  
  tempfile = Tempfile.new(['captcha', '.png'])
  begin
    # 下载图片
    URI.open(url) do |image|
      tempfile.binmode
      tempfile.write(image.read)
      tempfile.rewind
    end
    
    return tempfile.path
  rescue => e
    Crawlee.logger.error("下载验证码图片失败: #{e.message}")
    tempfile.close
    tempfile.unlink
    return nil
  end
end
```

对于复杂验证码（如 reCAPTCHA），可以使用专业的验证码解决服务：

```ruby
require 'anti_captcha'

crawler.router.add('/recaptcha-page') do |context|
  # 获取 reCAPTCHA 的 site_key
  site_key = context.evaluate(<<~JS)
    document.querySelector('.g-recaptcha').getAttribute('data-sitekey');
  JS
  
  # 使用验证码解决服务
  client = AntiCaptcha::Client.new('your_api_key')
  solution = client.solve_recaptcha_v2(
    site_key: site_key,
    page_url: context.request.url
  )
  
  if solution && solution['g-recaptcha-response']
    # 将解决方案注入页面
    context.evaluate(<<~JS, solution['g-recaptcha-response'])
      document.getElementById('g-recaptcha-response').innerHTML = arguments[0];
      document.querySelector('form').submit();
    JS
  else
    Crawlee.logger.error("验证码解决失败")
  end
end
```

### 登录和认证

处理需要登录的网站：

```ruby
# 创建登录管理器
class LoginManager
  def initialize(crawler)
    @crawler = crawler
    @storage = crawler.storage.key_value('auth')
    @session_valid_until = nil
  end
  
  def login
    # 检查是否已有有效会话
    session_data = @storage.get('session_data')
    if session_data && session_data['expires_at'] && Time.now.to_i < session_data['expires_at']
      @session_valid_until = session_data['expires_at']
      Crawlee.logger.info("使用缓存的会话信息，有效期至 #{Time.at(@session_valid_until)}")
      return true
    end
    
    # 需要重新登录
    Crawlee.logger.info("开始登录过程")
    
    # 添加登录请求
    login_request = Crawlee::Request.new(
      url: 'https://example.com/login',
      method: :post,
      payload: {
        username: ENV['SITE_USERNAME'] || 'your_username',
        password: ENV['SITE_PASSWORD'] || 'your_password'
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      },
      metadata: { is_login: true }
    )
    
    # 处理登录响应
    response = @crawler.http_client.fetch(login_request)
    
    # 检查登录是否成功
    if login_successful?(response)
      # 提取会话 cookie
      cookies = extract_cookies(response)
      
      # 计算过期时间（例如 24 小时后）
      @session_valid_until = Time.now.to_i + 24 * 60 * 60
      
      # 保存会话数据
      @storage.set('session_data', {
        cookies: cookies,
        expires_at: @session_valid_until
      })
      
      Crawlee.logger.info("登录成功，会话有效期至 #{Time.at(@session_valid_until)}")
      return true
    else
      Crawlee.logger.error("登录失败")
      return false
    end
  end
  
  def apply_session_to_request(request)
    # 将会话信息应用到请求
    session_data = @storage.get('session_data')
    return request unless session_data && session_data['cookies']
    
    # 添加 Cookie 头
    request.headers['Cookie'] = session_data['cookies']
    request
  end
  
  private
  
  def login_successful?(response)
    # 根据响应判断登录是否成功
    response.status_code == 302 && 
      (response.headers['Location'] == '/dashboard' ||
       response.body.include?('登录成功'))
  end
  
  def extract_cookies(response)
    # 从响应中提取 Cookie
    cookies = []
    if response.headers['Set-Cookie']
      if response.headers['Set-Cookie'].is_a?(Array)
        cookies = response.headers['Set-Cookie']
      else
        cookies = [response.headers['Set-Cookie']]
      end
    end
    cookies.join('; ')
  end
end

# 使用登录管理器
login_manager = LoginManager.new(crawler)

# 在爬虫启动前登录
login_manager.login

# 在请求处理器中检查登录状态
crawler.router.default_handler do |context|
  # 检查是否需要重新登录
  if !is_logged_in?(context)
    Crawlee.logger.warn("检测到未登录状态，尝试重新登录")
    if login_manager.login
      # 重新入队当前请求
      crawler.enqueue(context.request.url)
    else
      Crawlee.logger.error("重新登录失败，无法继续爬取")
    end
    return
  end
  
  # 正常处理页面...
end

def is_logged_in?(context)
  # 检查登录状态的逻辑
  !context.html.css('.login-button').any? &&
    (context.html.css('.user-profile').any? ||
     context.html.css('.logout-button').any? ||
     context.response.headers['Set-Cookie']&.include?('session_id'))
end
```

## 最佳实践

1. **尊重网站规则**：始终查看并遵守目标网站的 robots.txt 文件和使用条款。

2. **限制请求频率**：控制爬取速度，避免对目标服务器造成过大负担。

3. **错误处理与重试**：实现健壮的错误处理机制，对临时性错误进行合理重试。

4. **分布式爬取**：对于大规模爬取任务，考虑使用多台服务器分布式执行。

5. **定期更新策略**：反爬虫技术在不断发展，定期更新你的爬虫策略以适应变化。

6. **数据本地缓存**：缓存已爬取的数据，避免重复请求相同的页面。

```ruby
# 检查是否已缓存
key_value_store = crawler.storage.key_value('cache')
cache_key = "page_#{Digest::MD5.hexdigest(url)}"

cached_data = key_value_store.get(cache_key)
if cached_data
  # 使用缓存数据
  process_data(cached_data)
else
  # 爬取并缓存
  crawler.enqueue(url)
end

# 在处理器中缓存数据
crawler.router.default_handler do |context|
  data = extract_data(context)
  
  # 缓存数据
  cache_key = "page_#{Digest::MD5.hexdigest(context.request.url)}"
  key_value_store.set(cache_key, data, expires_in: 86400)  # 24小时过期
  
  # 处理数据...
end
```

通过合理使用代理服务器和反爬虫技术，你可以构建更加健壮和高效的网络爬虫。记住，良好的爬虫不仅是技术上的成功，也应该尊重网站所有者的权利和服务器资源。
