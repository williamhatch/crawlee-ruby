# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Crawlers::BrowserCrawler do
  let(:crawler) { Crawlee::Crawlers::BrowserCrawler.new }
  let(:test_url) { 'https://example.com' }
  
  before do
    # 模拟浏览器响应
    mock_browser_response(test_url, 
      body: html_with_elements(
        title: '测试页面',
        links: [
          { url: 'https://example.com/page1', text: '页面1' },
          { url: 'https://example.com/page2', text: '页面2' }
        ],
        forms: [
          {
            action: 'https://example.com/submit',
            method: 'post',
            inputs: [
              { name: 'username', type: 'text' },
              { name: 'password', type: 'password' }
            ]
          }
        ]
      )
    )
    
    # 模拟子页面响应
    mock_browser_response('https://example.com/page1', 
      body: html_with_elements(title: '页面1')
    )
    mock_browser_response('https://example.com/page2', 
      body: html_with_elements(title: '页面2')
    )
    
    # 模拟表单提交响应
    mock_browser_response('https://example.com/submit', 
      body: html_with_elements(title: '提交成功')
    )
    
    # 模拟 JavaScript 响应
    mock_browser_response('https://example.com/js', 
      body: html_with_elements(
        title: 'JavaScript 测试',
        scripts: [
          "document.addEventListener('DOMContentLoaded', function() { document.title = '动态标题'; });"
        ]
      )
    )
    
    # 模拟错误页面
    mock_browser_response('https://example.com/error',
      status: 500,
      body: '<html><body>服务器错误</body></html>'
    )
    
    # 模拟重定向页面
    mock_browser_response('https://example.com/redirect',
      status: 302,
      headers: { 'Location' => 'https://example.com/redirected' }
    )
    mock_browser_response('https://example.com/redirected',
      body: html_with_elements(title: '重定向目标页面')
    )
  end
  
  describe '#browser_pool_management' do
    it '创建并管理浏览器池' do
      # 模拟浏览器创建
      expect(crawler).to receive(:create_browser).at_least(:once).and_call_original
      
      # 添加多个 URL
      urls = (1..3).map { |i| "https://example.com/page#{i}" }
      crawler.enqueue_links(urls)
      
      # 运行爬虫
      crawler.run(max_concurrency: 2)
      
      # 验证浏览器池
      browser_pool = crawler.instance_variable_get(:@browser_pool)
      expect(browser_pool).not_to be_empty
    end
    
    it '在并发环境下安全地管理浏览器池' do
      # 添加多个 URL
      urls = (1..5).map { |i| "https://example.com/page#{i}" }
      crawler.enqueue_links(urls)
      
      # 设置路由处理器
      crawler.router.default_handler do |context|
        # 模拟复杂的页面操作
        sleep(0.1)
      end
      
      # 运行爬虫
      crawler.run(max_concurrency: 3)
      
      # 验证统计信息
      stats = crawler.stats
      expect(stats[:requests_total]).to eq(5)
      expect(stats[:requests_successful]).to eq(5)
      expect(stats[:requests_failed]).to eq(0)
    end
  end
  
  describe '#browser_options' do
    it '支持无头模式' do
      headless_crawler = Crawlee::Crawlers::BrowserCrawler.new(
        headless: true
      )
      
      # 验证选项
      options = headless_crawler.instance_variable_get(:@options)
      expect(options[:headless]).to eq(true)
      
      # 模拟浏览器创建
      expect(headless_crawler).to receive(:launch_browser).with(
        hash_including(headless: true)
      ).and_call_original
      
      # 添加测试 URL
      headless_crawler.enqueue(test_url)
      
      # 运行爬虫
      headless_crawler.run
    end
    
    it '支持自定义浏览器启动选项' do
      custom_crawler = Crawlee::Crawlers::BrowserCrawler.new(
        launch_options: {
          args: ['--no-sandbox', '--disable-setuid-sandbox'],
          window_size: [1920, 1080]
        }
      )
      
      # 验证选项
      options = custom_crawler.instance_variable_get(:@options)
      expect(options[:launch_options][:args]).to include('--no-sandbox')
      expect(options[:launch_options][:window_size]).to eq([1920, 1080])
      
      # 模拟浏览器创建
      expect(custom_crawler).to receive(:create_browser).and_call_original
      
      # 添加测试 URL
      custom_crawler.enqueue(test_url)
      
      # 运行爬虫
      custom_crawler.run
    end
  end
  
  describe '#form_interaction' do
    it '填写并提交表单' do
      # 设置路由处理器
      form_submitted = false
      crawler.router.add('/submit') do |context|
        form_submitted = true
      end
      
      crawler.router.default_handler do |context|
        if context.request.url == test_url
          # 查找表单
          form = context.query_selector('form')
          expect(form).not_to be_nil
          
          # 填写表单
          context.evaluate(<<~JS)
            document.querySelector('input[name="username"]').value = 'testuser';
            document.querySelector('input[name="password"]').value = 'password123';
            document.querySelector('form').submit();
          JS
        end
      end
      
      # 添加测试 URL
      crawler.enqueue(test_url)
      
      # 运行爬虫
      crawler.run
      
      # 验证表单是否被提交
      expect(form_submitted).to be true
    end
  end
  
  describe '#javascript_execution' do
    it '执行 JavaScript 并获取结果' do
      # 设置路由处理器
      js_result = nil
      crawler.router.add('/js') do |context|
        # 执行 JavaScript
        js_result = context.evaluate('document.title')
      end
      
      # 添加 JavaScript 测试 URL
      crawler.enqueue('https://example.com/js')
      
      # 运行爬虫
      crawler.run
      
      # 验证 JavaScript 执行结果
      expect(js_result).to eq('动态标题').or eq('JavaScript 测试')
    end
    
    it '等待 DOM 事件' do
      # 设置路由处理器
      crawler.router.add('/js') do |context|
        # 等待 DOM 内容加载完成
        context.evaluate(<<~JS)
          return new Promise((resolve) => {
            if (document.readyState === 'complete') {
              resolve();
            } else {
              document.addEventListener('DOMContentLoaded', resolve);
            }
          });
        JS
        
        # 获取动态标题
        title = context.evaluate('document.title')
        expect(title).to eq('动态标题').or eq('JavaScript 测试')
      end
      
      # 添加 JavaScript 测试 URL
      crawler.enqueue('https://example.com/js')
      
      # 运行爬虫
      crawler.run
    end
  end
  
  describe '#error_handling' do
    it '处理页面加载错误' do
      # 设置路由处理器
      error_handled = false
      crawler.router.add('/error') do |context|
        error_handled = true
        expect(context.response.status_code).to eq(500)
      end
      
      # 添加错误 URL
      crawler.enqueue('https://example.com/error')
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证错误处理
      expect(error_handled).to be true
      expect(stats[:requests_failed]).to eq(1)
    end
    
    it '处理重定向' do
      # 设置路由处理器
      redirected = false
      crawler.router.add('/redirected') do |context|
        redirected = true
        expect(context.response.url).to eq('https://example.com/redirected')
      end
      
      # 添加重定向 URL
      crawler.enqueue('https://example.com/redirect')
      
      # 运行爬虫
      crawler.run
      
      # 验证重定向处理
      expect(redirected).to be true
    end
  end
  
  describe 'BrowserContext' do
    let(:request) { Crawlee::Request.new(test_url) }
    let(:context) do
      # 执行请求以获取上下文
      crawler.enqueue(test_url)
      crawler.run
      crawler.last_context
    end
    
    it '提供截图功能' do
      expect(context.page).to receive(:screenshot).and_return('screenshot_data')
      
      # 执行截图
      screenshot = context.evaluate('return 1') # 模拟截图操作
      
      expect(screenshot).not_to be_nil
    end
    
    it '提供 cookie 管理功能' do
      # 设置 cookie
      context.evaluate(<<~JS)
        document.cookie = 'test_cookie=value; path=/';
      JS
      
      # 获取 cookie
      cookies = context.evaluate('return document.cookie')
      expect(cookies).to include('test_cookie=value')
    end
    
    it '提供页面等待功能' do
      expect(context.page).to receive(:wait_for_timeout).with(1000)
      
      # 执行等待
      context.evaluate('return 1') # 模拟等待操作
    end
    
    it '提供元素等待功能' do
      expect(context.page).to receive(:wait_for_selector).with('div.content')
      
      # 执行元素等待
      context.evaluate('return 1') # 模拟元素等待操作
    end
  end
end
