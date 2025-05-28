# frozen_string_literal: true

require 'ferrum'

module Crawlee
  module Crawlers
    # 浏览器爬虫类，用于处理需要 JavaScript 渲染的网页
    class BrowserCrawler < BaseCrawler
      # 初始化浏览器爬虫
      # @param options [Hash] 爬虫选项
      def initialize(options = {})
        super(options)
        @browser_options = options[:browser_options] || {}
        @browser_pool = []
        @browser_pool_mutex = Mutex.new
      end
      
      protected
      
      # 执行浏览器请求
      # @param request [Crawlee::Request] 请求对象
      # @return [Crawlee::Response] 响应对象
      def do_request(request)
        start_time = Time.now
        
        # 获取会话
        session = @session_pool.get_session(request.domain)
        
        # 获取浏览器实例
        browser = acquire_browser
        
        begin
          # 导航到 URL
          browser.goto(request.url)
          
          # 等待页面加载完成
          wait_for_page_load(browser)
          
          # 提取响应信息
          status_code = browser.network.status || 200
          headers = extract_response_headers(browser)
          body = browser.body
          url = browser.url
          
          # 计算请求时间
          end_time = Time.now
          timing = {
            start_time: start_time.to_f,
            end_time: end_time.to_f,
            duration: (end_time - start_time) * 1000
          }
          
          # 更新会话 Cookie
          cookies = extract_cookies(browser)
          @session_pool.update_cookies(request.domain, cookies)
          
          # 创建响应对象
          Crawlee::Response.new(
            request,
            status_code,
            headers,
            body,
            url,
            timing
          )
        rescue => e
          Crawlee.logger.error("浏览器请求错误: #{e.message}")
          
          # 创建错误响应
          Crawlee::Response.new(
            request,
            0,
            {},
            e.message,
            request.url,
            { error: e.message }
          )
        ensure
          # 释放浏览器实例
          release_browser(browser)
        end
      end
      
      # 创建浏览器上下文
      # @param request [Crawlee::Request] 请求对象
      # @param response [Crawlee::Response] 响应对象
      # @return [BrowserContext] 浏览器上下文对象
      def create_context(request, response)
        BrowserContext.new(self, request, response)
      end
      
      private
      
      # 获取浏览器实例
      # @return [Ferrum::Browser] 浏览器实例
      def acquire_browser
        @browser_pool_mutex.synchronize do
          # 如果池中有可用的浏览器实例，则返回
          return @browser_pool.pop unless @browser_pool.empty?
          
          # 否则创建新的浏览器实例
          create_browser
        end
      end
      
      # 释放浏览器实例
      # @param browser [Ferrum::Browser] 浏览器实例
      def release_browser(browser)
        @browser_pool_mutex.synchronize do
          # 如果池已满，则关闭浏览器
          if @browser_pool.size >= @options[:max_concurrency]
            browser.quit
          else
            # 否则将浏览器放回池中
            @browser_pool.push(browser)
          end
        end
      end
      
      # 创建新的浏览器实例
      # @return [Ferrum::Browser] 浏览器实例
      def create_browser
        options = {
          headless: true,
          timeout: @options[:request_timeout],
          process_timeout: @options[:request_timeout] * 2
        }.merge(@browser_options)
        
        # 添加代理配置
        if @options[:proxy_configuration]
          proxy_url = select_proxy
          options[:browser_options] ||= {}
          options[:browser_options]['proxy-server'] = proxy_url if proxy_url
        end
        
        Ferrum::Browser.new(options)
      end
      
      # 等待页面加载完成
      # @param browser [Ferrum::Browser] 浏览器实例
      def wait_for_page_load(browser)
        browser.network.wait_for_idle
        browser.execute('document.readyState === "complete" || document.readyState === "interactive"')
      end
      
      # 提取响应头
      # @param browser [Ferrum::Browser] 浏览器实例
      # @return [Hash] 响应头
      def extract_response_headers(browser)
        # 尝试从网络请求中获取响应头
        headers = {}
        
        begin
          # 获取最后一个请求的响应头
          last_request = browser.network.traffic.last
          if last_request && last_request[:response]
            headers = last_request[:response][:headers] || {}
          end
        rescue => e
          Crawlee.logger.warn("提取响应头失败: #{e.message}")
        end
        
        headers
      end
      
      # 提取 Cookie
      # @param browser [Ferrum::Browser] 浏览器实例
      # @return [Array<Hash>] Cookie 数组
      def extract_cookies(browser)
        browser.cookies.all.map do |cookie|
          {
            name: cookie[:name],
            value: cookie[:value],
            domain: cookie[:domain],
            path: cookie[:path],
            expires: cookie[:expires]&.to_i,
            httponly: cookie[:httpOnly],
            secure: cookie[:secure],
            expired: false
          }
        end
      end
      
      # 选择代理
      # @return [String, nil] 代理 URL 或 nil
      def select_proxy
        return nil unless @options[:proxy_configuration]
        
        proxy_urls = @options[:proxy_configuration][:urls]
        return nil if proxy_urls.empty?
        
        case @options[:proxy_configuration][:rotation]
        when :round_robin
          # 轮询选择代理
          @proxy_index ||= 0
          proxy = proxy_urls[@proxy_index % proxy_urls.size]
          @proxy_index += 1
          proxy
        when :random
          # 随机选择代理
          proxy_urls.sample
        else
          # 默认使用第一个代理
          proxy_urls.first
        end
      end
    end
    
    # 浏览器上下文类
    class BrowserContext
      # 初始化浏览器上下文
      # @param crawler [BrowserCrawler] 爬虫实例
      # @param request [Crawlee::Request] 请求对象
      # @param response [Crawlee::Response] 响应对象
      def initialize(crawler, request, response)
        @crawler = crawler
        @request = request
        @response = response
        @metadata = request.metadata.dup
      end
      
      # 获取请求对象
      # @return [Crawlee::Request] 请求对象
      attr_reader :request
      
      # 获取响应对象
      # @return [Crawlee::Response] 响应对象
      attr_reader :response
      
      # 获取元数据
      # @return [Hash] 元数据
      attr_reader :metadata
      
      # 获取 HTML 文档
      # @return [Nokogiri::HTML::Document] HTML 文档
      def html
        @response.html
      end
      
      # 查找 HTML 元素
      # @param selector [String] CSS 选择器
      # @return [Nokogiri::XML::NodeSet] 元素集合
      def query_selector_all(selector)
        html.css(selector)
      end
      
      # 查找单个 HTML 元素
      # @param selector [String] CSS 选择器
      # @return [Nokogiri::XML::Element, nil] 元素或 nil
      def query_selector(selector)
        html.at_css(selector)
      end
      
      # 从页面提取链接并添加到队列
      # @param selector [String] CSS 选择器
      # @param options [Hash] 请求选项
      # @return [Integer] 添加的链接数量
      def enqueue_links(selector = 'a', options = {})
        links = query_selector_all(selector).map do |element|
          href = element['href']
          next if href.nil? || href.empty? || href.start_with?('#')
          
          # 构建完整 URL
          begin
            URI.join(@response.url, href).to_s
          rescue URI::InvalidURIError
            nil
          end
        end.compact
        
        @crawler.enqueue_links(links, options)
      end
      
      # 保存数据到数据集
      # @param data [Hash] 要保存的数据
      # @return [Hash] 带有 ID 的数据
      def save_data(data)
        @crawler.save_data(data)
      end
      
      # 添加请求到队列
      # @param url_or_request [String, Crawlee::Request] URL 或请求对象
      # @param options [Hash] 请求选项
      # @return [Boolean] 是否成功添加
      def enqueue(url_or_request, options = {})
        @crawler.enqueue(url_or_request, options)
      end
    end
  end
end
