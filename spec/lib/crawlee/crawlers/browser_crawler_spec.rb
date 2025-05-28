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
  end
  
  describe '#initialize' do
    it '创建一个浏览器爬虫实例' do
      expect(crawler).to be_a(Crawlee::Crawlers::BrowserCrawler)
      expect(crawler).to be_a(Crawlee::Crawlers::BaseCrawler)
    end
    
    it '使用自定义选项初始化' do
      custom_crawler = Crawlee::Crawlers::BrowserCrawler.new(
        max_concurrency: 3,
        headless: true,
        launch_options: {
          args: ['--no-sandbox', '--disable-setuid-sandbox']
        }
      )
      
      options = custom_crawler.instance_variable_get(:@options)
      expect(options[:max_concurrency]).to eq(3)
      expect(options[:headless]).to eq(true)
      expect(options[:launch_options][:args]).to include('--no-sandbox')
    end
  end
  
  describe '#enqueue' do
    it '将 URL 添加到请求队列' do
      expect(crawler.request_queue).to receive(:add).with(
        an_instance_of(Crawlee::Request)
      ).and_call_original
      
      crawler.enqueue(test_url)
      
      # 检查请求队列
      queue = crawler.request_queue.instance_variable_get(:@queue)
      expect(queue.size).to eq(1)
      expect(queue.first.url).to eq(test_url)
    end
    
    it '将请求对象添加到请求队列' do
      request = Crawlee::Request.new(test_url, method: :post)
      
      crawler.enqueue(request)
      
      # 检查请求队列
      queue = crawler.request_queue.instance_variable_get(:@queue)
      expect(queue.size).to eq(1)
      expect(queue.first).to eq(request)
    end
  end
  
  describe '#run' do
    it '处理队列中的所有请求' do
      # 添加测试 URL 到队列
      crawler.enqueue(test_url)
      
      # 运行爬虫
      crawler.run
      
      # 检查统计信息
      stats = crawler.stats
      expect(stats[:requests_total]).to eq(1)
      expect(stats[:requests_successful]).to eq(1)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '处理嵌套的请求' do
      # 设置路由处理器
      crawler.router.default_handler do |context|
        # 提取并跟踪链接
        context.enqueue_links('a')
      end
      
      # 添加测试 URL 到队列
      crawler.enqueue(test_url)
      
      # 运行爬虫
      crawler.run
      
      # 检查统计信息
      stats = crawler.stats
      expect(stats[:requests_total]).to eq(3) # 主页 + 2个子页面
      expect(stats[:requests_successful]).to eq(3)
      expect(stats[:requests_failed]).to eq(0)
    end
  end
  
  describe '#launch_browser' do
    it '启动浏览器' do
      expect(crawler).to receive(:launch_browser).and_call_original
      
      # 添加测试 URL 到队列
      crawler.enqueue(test_url)
      
      # 运行爬虫
      crawler.run
    end
    
    it '使用无头模式启动浏览器' do
      headless_crawler = Crawlee::Crawlers::BrowserCrawler.new(
        headless: true
      )
      
      expect(headless_crawler).to receive(:launch_browser).with(
        hash_including(headless: true)
      ).and_call_original
      
      # 添加测试 URL 到队列
      headless_crawler.enqueue(test_url)
      
      # 运行爬虫
      headless_crawler.run
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
    
    it '提供页面操作方法' do
      expect(context).to respond_to(:page)
      expect(context).to respond_to(:query_selector)
      expect(context).to respond_to(:query_selector_all)
      expect(context).to respond_to(:evaluate)
    end
    
    it '可以查询页面元素' do
      title = context.query_selector('title')
      expect(title).not_to be_nil
      expect(title.text).to eq('测试页面')
    end
    
    it '可以查询多个页面元素' do
      links = context.query_selector_all('a')
      expect(links.size).to eq(2)
      expect(links.first['href']).to eq('https://example.com/page1')
      expect(links.last['href']).to eq('https://example.com/page2')
    end
    
    it '可以执行 JavaScript' do
      result = context.evaluate('document.title')
      expect(result).to eq('测试页面')
    end
    
    it '可以保存数据' do
      expect(crawler.dataset).to receive(:push_data).with(
        hash_including(title: '测试标题')
      )
      
      context.save_data({ title: '测试标题' })
    end
  end
end
