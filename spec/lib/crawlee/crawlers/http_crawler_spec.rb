# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Crawlers::HttpCrawler do
  let(:crawler) { Crawlee::Crawlers::HttpCrawler.new }
  let(:test_url) { 'https://example.com' }
  
  before do
    # 模拟 HTTP 响应
    mock_http_response(test_url, 
      body: html_with_elements(
        title: '测试页面',
        links: [
          { url: 'https://example.com/page1', text: '页面1' },
          { url: 'https://example.com/page2', text: '页面2' }
        ]
      )
    )
    
    # 模拟子页面响应
    mock_http_response('https://example.com/page1', 
      body: html_with_elements(title: '页面1')
    )
    mock_http_response('https://example.com/page2', 
      body: html_with_elements(title: '页面2')
    )
  end
  
  describe '#initialize' do
    it '创建一个 HTTP 爬虫实例' do
      expect(crawler).to be_a(Crawlee::Crawlers::HttpCrawler)
      expect(crawler).to be_a(Crawlee::Crawlers::BaseCrawler)
    end
    
    it '使用自定义选项初始化' do
      custom_crawler = Crawlee::Crawlers::HttpCrawler.new(
        max_concurrency: 3,
        request_timeout: 60,
        max_retries: 5
      )
      
      options = custom_crawler.instance_variable_get(:@options)
      expect(options[:max_concurrency]).to eq(3)
      expect(options[:request_timeout]).to eq(60)
      expect(options[:max_retries]).to eq(5)
    end
  end
  
  describe '#enqueue' do
    it '将 URL 添加到请求队列' do
      crawler.enqueue(test_url)
      
      request_queue = crawler.instance_variable_get(:@request_queue)
      queue_info = request_queue.get_info
      
      expect(queue_info[:pending_count]).to eq(1)
      expect(queue_info[:handled_count]).to eq(0)
    end
    
    it '将请求对象添加到请求队列' do
      request = Crawlee::Request.new(test_url, headers: { 'Custom' => 'Header' })
      crawler.enqueue(request)
      
      request_queue = crawler.instance_variable_get(:@request_queue)
      queue_info = request_queue.get_info
      
      expect(queue_info[:pending_count]).to eq(1)
    end
  end
  
  describe '#enqueue_links' do
    it '批量添加 URL 到请求队列' do
      urls = ['https://example.com/page1', 'https://example.com/page2']
      count = crawler.enqueue_links(urls)
      
      request_queue = crawler.instance_variable_get(:@request_queue)
      queue_info = request_queue.get_info
      
      expect(count).to eq(2)
      expect(queue_info[:pending_count]).to eq(2)
    end
  end
  
  describe '#run' do
    it '处理请求队列中的所有请求' do
      # 设置路由处理器
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
        
        # 提取并跟踪链接
        if context.request.url == test_url
          context.enqueue_links('a')
        end
      end
      
      # 添加起始 URL
      crawler.enqueue(test_url)
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果
      expect(processed_urls).to include(test_url, 'https://example.com/page1', 'https://example.com/page2')
      expect(stats[:requests_total]).to eq(3)
      expect(stats[:requests_successful]).to eq(3)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '处理请求失败和重试' do
      # 模拟失败的请求
      stub_request(:get, 'https://example.com/error')
        .to_return(status: 500, body: 'Server Error')
        .then
        .to_return(status: 200, body: '<html><body>Success</body></html>')
      
      # 设置路由处理器
      crawler.router.default_handler do |context|
        # 不执行任何操作
      end
      
      # 添加失败的 URL
      crawler.enqueue('https://example.com/error')
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果
      expect(stats[:requests_total]).to eq(2)  # 原始请求 + 一次重试
      expect(stats[:requests_successful]).to eq(1)
      expect(stats[:requests_failed]).to eq(0)
      expect(stats[:requests_retried]).to eq(1)
    end
  end
  
  describe 'HttpContext' do
    let(:request) { Crawlee::Request.new(test_url) }
    let(:response) do
      # 执行请求以获取响应
      crawler.send(:do_request, request)
    end
    let(:context) { crawler.send(:create_context, request, response) }
    
    it '提供对请求和响应的访问' do
      expect(context.request).to eq(request)
      expect(context.response).to eq(response)
    end
    
    it '提供 HTML 解析功能' do
      expect(context.html).to be_a(Nokogiri::HTML::Document)
      expect(context.query_selector('title').text).to eq('测试页面')
    end
    
    it '提供元素选择功能' do
      links = context.query_selector_all('a')
      expect(links.size).to eq(2)
      expect(links[0]['href']).to eq('https://example.com/page1')
      expect(links[0].text).to eq('页面1')
    end
    
    it '提供链接提取和跟踪功能' do
      count = context.enqueue_links('a')
      
      request_queue = crawler.instance_variable_get(:@request_queue)
      queue_info = request_queue.get_info
      
      expect(count).to eq(2)
      expect(queue_info[:pending_count]).to eq(2)
    end
    
    it '提供数据保存功能' do
      data = { url: test_url, title: '测试页面' }
      saved_data = context.save_data(data)
      
      expect(saved_data).to include(data)
      expect(saved_data[:id]).not_to be_nil
      expect(saved_data[:createdAt]).not_to be_nil
      
      dataset = crawler.instance_variable_get(:@dataset)
      all_data = dataset.get_data
      
      expect(all_data.size).to eq(1)
      expect(all_data.first[:url]).to eq(test_url)
    end
  end
end
