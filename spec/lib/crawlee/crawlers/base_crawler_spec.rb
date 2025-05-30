# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Crawlers::BaseCrawler do
  # 创建一个 BaseCrawler 的具体实现用于测试
  class TestCrawler < Crawlee::Crawlers::BaseCrawler
    attr_reader :last_context, :request_queue
    
    def do_request(request)
      # 模拟请求处理
      if request.url.include?('/error')
        if request.retry_count < 1
          # 首次请求失败
          Crawlee::Response.new(
            request,
            500,
            {},
            'Error page',
            request.url,
            { error: 'Test error' }
          )
        else
          # 重试成功
          Crawlee::Response.new(
            request,
            200,
            { 'Content-Type' => 'text/html' },
            '<html><body>Retry success</body></html>',
            request.url,
            {}
          )
        end
      else
        # 正常请求
        Crawlee::Response.new(
          request,
          200,
          { 'Content-Type' => 'text/html' },
          "<html><body>Test page for #{request.url}</body></html>",
          request.url,
          {}
        )
      end
    end
    
    # 定义 HttpContext 类，用于测试
    class HttpContext
      attr_reader :request, :response
      
      def initialize(crawler, request, response)
        @crawler = crawler
        @request = request
        @response = response
      end
      
      def save_data(data)
        @crawler.save_data(data)
      end
    end
    
    def create_context(request, response)
      context = HttpContext.new(self, request, response)
      @last_context = context
      context
    end
  end
  
  let(:crawler) { TestCrawler.new }
  let(:test_url) { 'https://example.com' }
  
  describe '#initialize' do
    it '初始化基础爬虫实例' do
      expect(crawler).to be_a(Crawlee::Crawlers::BaseCrawler)
      expect(crawler.router).to be_a(Crawlee::Crawlers::Router)
      expect(crawler.dataset).to be_a(Crawlee::Storage::DatasetStorage)
    end
    
    it '使用自定义选项初始化' do
      custom_crawler = TestCrawler.new(
        max_concurrency: 5,
        request_timeout: 30,
        max_retries: 3,
        storage_dir: './custom_storage',
        request_queue_name: 'custom_queue',
        dataset_name: 'custom_dataset'
      )
      
      options = custom_crawler.instance_variable_get(:@options)
      expect(options[:max_concurrency]).to eq(5)
      expect(options[:request_timeout]).to eq(30)
      expect(options[:max_retries]).to eq(3)
      expect(options[:storage_dir]).to eq('./custom_storage')
      expect(options[:request_queue_name]).to eq('custom_queue')
      expect(options[:dataset_name]).to eq('custom_dataset')
    end
  end
  
  describe '#enqueue' do
    it '将 URL 添加到请求队列' do
      crawler.enqueue(test_url)
      
      request_queue = crawler.request_queue
      queue_info = request_queue.get_info
      
      expect(queue_info[:pending_count]).to eq(1)
      expect(queue_info[:handled_count]).to eq(0)
    end
    
    it '将请求对象添加到请求队列' do
      request = Crawlee::Request.new(test_url, headers: { 'Custom' => 'Header' })
      crawler.enqueue(request)
      
      request_queue = crawler.request_queue
      queue_info = request_queue.get_info
      
      expect(queue_info[:pending_count]).to eq(1)
    end
  end
  
  describe '#enqueue_links' do
    it '批量添加 URL 到请求队列' do
      urls = ['https://example.com/page1', 'https://example.com/page2']
      count = crawler.enqueue_links(urls)
      
      request_queue = crawler.request_queue
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
      end
      
      # 添加起始 URL
      crawler.enqueue(test_url)
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果
      expect(processed_urls).to include(test_url)
      expect(stats[:requests_total]).to eq(1)
      expect(stats[:requests_successful]).to eq(1)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '处理请求失败和重试' do
      # 设置路由处理器
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
      end
      
      # 添加失败的 URL
      crawler.enqueue('https://example.com/error')
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果
      expect(processed_urls).to include('https://example.com/error')
      expect(stats[:requests_total]).to eq(2)  # 原始请求 + 一次重试
      expect(stats[:requests_successful]).to eq(1)
      expect(stats[:requests_failed]).to eq(0)
      expect(stats[:requests_retried]).to eq(1)
    end
    
    it '处理多个并发请求' do
      # 添加多个 URL
      urls = (1..5).map { |i| "https://example.com/page#{i}" }
      crawler.enqueue_links(urls)
      
      # 设置路由处理器
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
        sleep(0.1)  # 模拟处理时间
      end
      
      # 使用较高的并发度运行爬虫
      stats = crawler.run(max_concurrency: 5)
      
      # 验证结果
      expect(processed_urls.size).to eq(5)  # 减少期望的 URL 数量
      expect(stats[:requests_total]).to eq(5)
      expect(stats[:requests_successful]).to eq(5)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '在处理请求时动态添加新请求' do
      # 设置路由处理器
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
        
        # 在处理第一个请求时添加新请求
        if context.request.url == test_url
          crawler.enqueue('https://example.com/dynamic')
        end
      end
      
      # 添加起始 URL
      crawler.enqueue(test_url)
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果
      expect(processed_urls).to include(test_url, 'https://example.com/dynamic')
      expect(stats[:requests_total]).to eq(2)
      expect(stats[:requests_successful]).to eq(2)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '正确处理活跃请求计数器' do
      # 添加多个 URL
      urls = (1..10).map { |i| "https://example.com/page#{i}" }
      crawler.enqueue_links(urls)
      
      # 设置路由处理器，模拟处理延迟
      crawler.router.default_handler do |context|
        # 模拟不同的处理时间
        sleep(rand(0.05..0.2))
      end
      
      # 运行爬虫，限制并发数
      stats = crawler.run(max_concurrency: 3)
      
      # 验证结果
      expect(stats[:requests_total]).to eq(10)
      expect(stats[:requests_successful]).to eq(10)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '在处理过程中添加大量新请求' do
      # 设置路由处理器
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
        
        # 在处理第一个请求时添加大量新请求
        if context.request.url == test_url
          # 添加 20 个新请求
          (1..20).each do |i|
            crawler.enqueue("https://example.com/dynamic/#{i}")
          end
        end
      end
      
      # 添加起始 URL
      crawler.enqueue(test_url)
      
      # 运行爬虫，使用较高的并发度
      stats = crawler.run(max_concurrency: 5)
      
      # 验证结果
      expect(processed_urls.size).to eq(21)  # 起始 URL + 20 个动态添加的 URL
      expect(stats[:requests_total]).to eq(21)
      expect(stats[:requests_successful]).to eq(21)
      expect(stats[:requests_failed]).to eq(0)
    end
    
    it '处理多次重试的请求' do
      # 创建一个自定义的测试爬虫类，模拟多次失败后成功
      custom_crawler = Class.new(TestCrawler) do
        def do_request(request)
          if request.url.include?('/multi-retry')
            if request.retry_count < 3
              # 前三次请求失败
              Crawlee::Response.new(
                request,
                500,
                {},
                'Error page',
                request.url,
                { error: 'Test error' }
              )
            else
              # 第四次请求成功
              Crawlee::Response.new(
                request,
                200,
                { 'Content-Type' => 'text/html' },
                '<html><body>Success after multiple retries</body></html>',
                request.url,
                {}
              )
            end
          else
            super
          end
        end
      end.new(max_retries: 3)
      
      # 设置路由处理器
      processed_urls = []
      custom_crawler.router.default_handler do |context|
        processed_urls << context.request.url
      end
      
      # 添加需要多次重试的 URL
      custom_crawler.enqueue('https://example.com/multi-retry')
      
      # 运行爬虫
      stats = custom_crawler.run
      
      # 验证结果
      expect(processed_urls).to include('https://example.com/multi-retry')
      expect(stats[:requests_total]).to eq(4)  # 原始请求 + 三次重试
      expect(stats[:requests_successful]).to eq(1)
      expect(stats[:requests_failed]).to eq(0)
      expect(stats[:requests_retried]).to eq(3)
    end
  end
  
  describe '#stop' do
    it '停止爬虫运行' do
      # 设置路由处理器，处理第一个请求后停止爬虫
      crawler.router.default_handler do |context|
        crawler.stop if context.request.url == test_url
      end
      
      # 添加多个 URL
      crawler.enqueue(test_url)
      crawler.enqueue('https://example.com/page1')
      crawler.enqueue('https://example.com/page2')
      
      # 运行爬虫
      stats = crawler.run
      
      # 验证结果 - 只有第一个请求被处理
      expect(stats[:requests_total]).to be >= 1
      expect(stats[:requests_total]).to be < 3
    end
  end
  
  describe '#save_data' do
    it '保存数据到数据集' do
      data = { url: test_url, title: '测试页面' }
      saved_data = crawler.save_data(data)
      
      expect(saved_data).to include(data)
      expect(saved_data[:id]).not_to be_nil
      
      dataset = crawler.dataset
      all_data = dataset.get_data
      
      expect(all_data.size).to eq(1)
      expect(all_data.first[:url]).to eq(test_url)
    end
  end
  
  describe '#stats' do
    it '返回爬虫统计信息' do
      # 添加并处理一个请求
      crawler.router.default_handler do |context|
        # 不执行任何操作
      end
      
      crawler.enqueue(test_url)
      crawler.run
      
      # 获取统计信息
      stats = crawler.stats
      
      expect(stats).to include(:requests_total, :requests_successful, :requests_failed, :requests_retried)
      expect(stats).to include(:queue_info, :dataset_info)
      expect(stats[:requests_total]).to eq(1)
      expect(stats[:requests_successful]).to eq(1)
    end
  end
  
  describe 'Router' do
    let(:router) { crawler.router }
    
    it '根据模式匹配路由请求' do
      # 设置路由处理器
      pattern_matched = false
      router.add('/pattern') do |context|
        pattern_matched = true
      end
      
      # 创建上下文
      request = Crawlee::Request.new('https://example.com/pattern')
      response = crawler.send(:do_request, request)
      context = crawler.send(:create_context, request, response)
      
      # 路由请求
      crawler.send(:route_request, context)
      
      # 验证结果
      expect(pattern_matched).to be true
    end
    
    it '使用默认处理器处理不匹配的请求' do
      # 设置默认处理器
      default_handled = false
      router.default_handler do |context|
        default_handled = true
      end
      
      # 创建上下文
      request = Crawlee::Request.new('https://example.com/no-match')
      response = crawler.send(:do_request, request)
      context = crawler.send(:create_context, request, response)
      
      # 路由请求
      crawler.send(:route_request, context)
      
      # 验证结果
      expect(default_handled).to be true
    end
    
    it '支持正则表达式模式' do
      # 设置正则表达式路由处理器
      regex_matched = false
      router.add(/\/page\d+/) do |context|
        regex_matched = true
      end
      
      # 创建上下文
      request = Crawlee::Request.new('https://example.com/page123')
      response = crawler.send(:do_request, request)
      context = crawler.send(:create_context, request, response)
      
      # 路由请求
      crawler.send(:route_request, context)
      
      # 验证结果
      expect(regex_matched).to be true
    end
  end
  
  # 模拟 WebMock 的响应设置
  def mock_http_response(url, options = {})
    stub_request(:any, url).to_return(
      status: options[:status] || 200,
      body: options[:body] || '',
      headers: options[:headers] || {}
    )
  end
  
  # 生成带有指定元素的 HTML
  def html_with_elements(options = {})
    title = options[:title] || 'Test Page'
    links = options[:links] || []
    
    html = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>#{title}</title>
        </head>
        <body>
    HTML
    
    links.each do |link|
      html << "<a href=\"#{link[:url]}\">#{link[:text]}</a>\n"
    end
    
    html << <<~HTML
        </body>
      </html>
    HTML
    
    html
  end
  
  describe '请求优先级测试' do
    it '根据优先级处理请求队列' do
      # 添加不同优先级的请求
      low_priority_url = 'https://example.com/low-priority'
      high_priority_url = 'https://example.com/high-priority'
      
      # 低优先级请求
      crawler.enqueue(low_priority_url, priority: 0)
      # 高优先级请求
      crawler.enqueue(high_priority_url, priority: 1)
      
      # 记录处理顺序
      processed_urls = []
      crawler.router.default_handler do |context|
        processed_urls << context.request.url
      end
      
      # 运行爬虫，使用低并发度确保顺序性
      crawler.run(max_concurrency: 1)
      
      # 验证高优先级请求先处理
      expect(processed_urls.index(high_priority_url)).to be < processed_urls.index(low_priority_url)
    end
  end
  
  describe '会话管理测试' do
    it '使用会话处理请求' do
      # 创建一个模拟会话管理的测试爬虫
      session_crawler = Class.new(TestCrawler) do
        attr_reader :used_session
        
        def do_request(request)
          # 检查请求是否包含会话信息
          @used_session = request.headers['Cookie'] if request.headers['Cookie']
          super
        end
      end.new
      
      # 创建会话并设置 Cookie
      session = { cookies: 'session_id=12345; user_id=67890' }
      
      # 使用会话发送请求
      session_crawler.enqueue('https://example.com/session-test', headers: { 'Cookie' => session[:cookies] })
      
      # 运行爬虫
      session_crawler.run
      
      # 验证会话信息被正确使用
      expect(session_crawler.used_session).to eq(session[:cookies])
    end
  end
  
  describe '错误处理测试' do
    it '处理超时错误' do
      # 创建一个模拟超时的测试爬虫
      timeout_crawler = Class.new(TestCrawler) do
        def do_request(request)
          if request.url.include?('/timeout')
            raise Timeout::Error, '请求超时'
          else
            super
          end
        end
      end.new(max_retries: 2)
      
      # 添加会超时的 URL
      timeout_crawler.enqueue('https://example.com/timeout')
      
      # 运行爬虫
      stats = timeout_crawler.run
      
      # 验证结果
      expect(stats[:requests_total]).to eq(3)  # 原始请求 + 两次重试
      expect(stats[:requests_failed]).to eq(1)  # 最终失败
      expect(stats[:requests_retried]).to eq(2)  # 重试两次
    end
    
    it '处理网络错误' do
      # 创建一个模拟网络错误的测试爬虫
      network_error_crawler = Class.new(TestCrawler) do
        def do_request(request)
          if request.url.include?('/network-error')
            if request.retry_count < 1
              raise SocketError, '网络连接失败'
            else
              # 重试成功
              super
            end
          else
            super
          end
        end
      end.new(max_retries: 2)
      
      # 添加会出现网络错误的 URL
      network_error_crawler.enqueue('https://example.com/network-error')
      
      # 运行爬虫
      stats = network_error_crawler.run
      
      # 验证结果
      expect(stats[:requests_total]).to eq(2)  # 原始请求 + 一次重试
      expect(stats[:requests_successful]).to eq(1)  # 重试成功
      expect(stats[:requests_retried]).to eq(1)  # 重试一次
    end
  end
  
  describe '统计信息准确性测试' do
    it '正确记录请求统计信息' do
      # 创建混合结果的测试爬虫
      stats_crawler = Class.new(TestCrawler) do
        def do_request(request)
          if request.url.include?('/success')
            # 成功请求
            super
          elsif request.url.include?('/fail')
            # 失败请求，不重试
            request.no_retry = true
            Crawlee::Response.new(
              request,
              404,
              {},
              'Not Found',
              request.url,
              { error: 'Not Found' }
            )
          elsif request.url.include?('/retry-then-success')
            if request.retry_count < 1
              # 第一次失败
              Crawlee::Response.new(
                request,
                500,
                {},
                'Server Error',
                request.url,
                { error: 'Server Error' }
              )
            else
              # 重试成功
              super
            end
          end
        end
      end.new
      
      # 添加不同类型的请求
      stats_crawler.enqueue('https://example.com/success')  # 成功
      stats_crawler.enqueue('https://example.com/fail')     # 失败
      stats_crawler.enqueue('https://example.com/retry-then-success')  # 重试后成功
      
      # 运行爬虫
      stats = stats_crawler.run
      
      # 验证统计信息
      expect(stats[:requests_total]).to eq(4)  # 3 个原始请求 + 1 个重试
      expect(stats[:requests_successful]).to eq(2)  # 2 个成功请求
      expect(stats[:requests_failed]).to eq(1)     # 1 个失败请求
      expect(stats[:requests_retried]).to eq(1)    # 1 个重试请求
    end
    
    it '正确记录队列和数据集统计信息' do
      # 添加请求并保存数据
      crawler.enqueue('https://example.com/stats-test')
      
      crawler.router.default_handler do |context|
        # 保存两条数据
        crawler.save_data({ url: context.request.url, type: 'page' })
        crawler.save_data({ url: context.request.url, type: 'metadata' })
      end
      
      # 运行爬虫
      crawler.run
      
      # 获取统计信息
      stats = crawler.stats
      
      # 验证队列统计信息
      expect(stats[:queue_info][:total_count]).to eq(1)
      expect(stats[:queue_info][:handled_count]).to eq(1)
      expect(stats[:queue_info][:pending_count]).to eq(0)
      
      # 验证数据集统计信息
      expect(stats[:dataset_info][:count]).to eq(2)  # 保存了两条数据
    end
  end
end
