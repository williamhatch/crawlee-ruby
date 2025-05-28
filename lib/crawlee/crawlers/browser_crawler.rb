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
        
        # 打印请求详情以便于调试
        Crawlee.logger.info("\n=== 开始执行浏览器请求 ===")
        Crawlee.logger.info("URL: #{request.url}")
        Crawlee.logger.info("Method: #{request.method}")
        
        # 安全获取 domain
        domain = nil
        begin
          domain = request.domain
          Crawlee.logger.info("Domain: #{domain || '未知域名'}")
        rescue => e
          Crawlee.logger.error("\n获取域名时出错: #{e.message}")
          Crawlee.logger.error("URL: #{request.url}")
          # 尝试从 URL 中提取域名
          begin
            uri = URI.parse(request.url)
            domain = uri.host
            Crawlee.logger.info("从 URI 中提取的域名: #{domain}")
          rescue => e2
            Crawlee.logger.error("从 URI 中提取域名也失败: #{e2.message}")
          end
        end
        
        # 如果域名仍然为 nil，使用默认域名
        domain = "default_domain" if domain.nil?
        
        # 获取会话
        Crawlee.logger.info("获取会话: #{domain}")
        session = @session_pool.get_session(domain)
        
        # 获取浏览器实例
        Crawlee.logger.info("获取浏览器实例")
        browser = acquire_browser
        
        begin
          # 检查浏览器实例是否正确初始化
          if browser.nil?
            Crawlee.logger.error("浏览器实例为 nil，尝试创建新的浏览器实例")
            browser = create_browser
            if browser.nil?
              raise "无法创建浏览器实例"
            end
          end
          
          Crawlee.logger.info("导航到 URL: #{request.url}")
          # 导航到 URL
          browser.goto(request.url)
          
          # 等待页面加载完成
          wait_for_page_load(browser)
          
          # 提取响应信息
          Crawlee.logger.info("提取响应信息")
          status_code = browser.network.status || 200
          Crawlee.logger.info("状态码: #{status_code}")
          
          headers = extract_response_headers(browser)
          Crawlee.logger.info("提取到响应头: #{headers.keys.size} 个")
          
          body = browser.body
          Crawlee.logger.info("响应体长度: #{body.length} 字符")
          
          url = browser.url
          Crawlee.logger.info("当前 URL: #{url}")
          
          # 计算请求时间
          end_time = Time.now
          timing = {
            start_time: start_time.to_f,
            end_time: end_time.to_f,
            duration: (end_time - start_time) * 1000
          }
          
          # 更新会话 Cookie
          cookies = extract_cookies(browser)
          
          # 安全更新会话 Cookie
          begin
            domain_for_cookies = request.domain rescue "default_domain"
            Crawlee.logger.info("更新会话 Cookie: #{domain_for_cookies}")
            Crawlee.logger.info("提取到 #{cookies.size} 个 Cookie")
            @session_pool.update_cookies(domain_for_cookies, cookies)
          rescue => e
            Crawlee.logger.error("更新会话 Cookie 时出错: #{e.message}")
          end
          
          # 创建响应对象
          Crawlee.logger.info("创建响应对象: 状态码 #{status_code}, HTML 长度 #{body.length}")
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
          Crawlee.logger.error(e.backtrace.join("\n"))
          
          # 创建错误响应
          Crawlee.logger.info("创建错误响应")
          
          # 尝试获取当前页面的一些信息，如果可能
          error_info = e.message
          current_url = request.url
          error_body = ""
          
          begin
            if browser
              Crawlee.logger.info("尝试从浏览器获取错误页面信息")
              current_url = browser.url rescue request.url
              Crawlee.logger.info("当前 URL: #{current_url}")
              
              if browser.page
                error_body = browser.body rescue ""
                Crawlee.logger.info("错误页面 HTML 长度: #{error_body.length}")
                Crawlee.logger.info("错误页面标题: #{browser.page.title rescue '无法获取标题'}")
                
                # 尝试截图
                begin
                  screenshot_path = "json/error_screenshot_#{Time.now.strftime('%Y%m%d_%H%M%S')}.png"
                  browser.page.screenshot(path: screenshot_path)
                  Crawlee.logger.info("已保存错误页面截图到: #{screenshot_path}")
                rescue => e2
                  Crawlee.logger.error("截图时出错: #{e2.message}")
                end
              else
                Crawlee.logger.error("无法获取浏览器页面")
              end
            end
          rescue => e2
            Crawlee.logger.error("获取错误页面信息时出错: #{e2.message}")
          end
          
          Crawlee::Response.new(
            request,
            500,
            {},
            error_body,
            current_url,
            {
              start_time: start_time.to_f,
              end_time: Time.now.to_f,
              duration: (Time.now - start_time) * 1000,
              error: error_info
            }
          )
        ensure
          # 释放浏览器实例
          Crawlee.logger.info("释放浏览器实例")
          release_browser(browser) if browser
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
        Crawlee.logger.info("开始获取浏览器实例...")
        browser = nil
        
        begin
          @browser_pool_mutex.synchronize do
            if @browser_pool.empty?
              Crawlee.logger.info("浏览器池为空，创建新的浏览器实例")
              browser = create_browser
              if browser.nil?
                Crawlee.logger.error("创建浏览器实例失败")
              else
                Crawlee.logger.info("浏览器实例创建成功")
              end
            else
              Crawlee.logger.info("从浏览器池中获取浏览器实例")
              browser = @browser_pool.pop
              if browser.nil?
                Crawlee.logger.error("从浏览器池中获取的浏览器实例为 nil，创建新的浏览器实例")
                browser = create_browser
              end
            end
          end
        rescue => e
          Crawlee.logger.error("获取浏览器实例时出错: #{e.message}")
          Crawlee.logger.error(e.backtrace.join("\n"))
          
          # 尝试创建新的浏览器实例
          begin
            browser = create_browser
          rescue => e2
            Crawlee.logger.error("尝试创建新的浏览器实例也失败: #{e2.message}")
          end
        end
        
        if browser.nil?
          Crawlee.logger.error("无法获取浏览器实例，返回 nil")
        else
          Crawlee.logger.info("成功获取浏览器实例")
        end
        
        browser
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
        Crawlee.logger.info("开始创建新的浏览器实例...")
        
        begin
          # 准备浏览器选项
          options = {
            headless: false,  # 非无头模式，方便调试
            timeout: @options[:request_timeout] || 60000,
            process_timeout: (@options[:request_timeout] || 60000) * 2,
            window_size: [1366, 768]
          }
          
          # 打印浏览器配置
          Crawlee.logger.info("浏览器配置:")
          Crawlee.logger.info("  headless: #{options[:headless]}")
          Crawlee.logger.info("  timeout: #{options[:timeout]}")
          Crawlee.logger.info("  process_timeout: #{options[:process_timeout]}")
          Crawlee.logger.info("  window_size: #{options[:window_size].inspect}")
          
          # 合并用户提供的选项
          if @browser_options && !@browser_options.empty?
            Crawlee.logger.info("合并用户提供的浏览器选项:")
            @browser_options.each do |key, value|
              Crawlee.logger.info("  #{key}: #{value.inspect}")
            end
            options.merge!(@browser_options)
          end
          
          # 添加代理配置
          if @options[:proxy_configuration]
            Crawlee.logger.info("尝试配置代理...")
            proxy_url = select_proxy
            if proxy_url
              Crawlee.logger.info("使用代理: #{proxy_url}")
              options[:browser_options] ||= {}
              options[:browser_options]['proxy-server'] = proxy_url
            else
              Crawlee.logger.info("未找到可用代理")
            end
          end
          
          # 添加更多调试选项
          options[:js_errors] = true  # 捕获 JavaScript 错误
          
          Crawlee.logger.info("创建 Ferrum::Browser 实例...")
          browser = Ferrum::Browser.new(options)
          Crawlee.logger.info("浏览器实例创建成功")
          
          # 测试浏览器是否正常工作
          Crawlee.logger.info("测试浏览器是否正常工作...")
          browser.goto("about:blank")
          Crawlee.logger.info("浏览器测试成功")
          
          return browser
        rescue => e
          Crawlee.logger.error("创建浏览器实例时出错: #{e.message}")
          Crawlee.logger.error(e.backtrace.join("\n"))
          return nil
        end
      end
      
      # 等待页面加载完成
      # @param browser [Ferrum::Browser] 浏览器实例
      def wait_for_page_load(browser)
        Crawlee.logger.info("等待页面加载完成...")
        
        begin
          # 记录开始时间
          start_time = Time.now
          
          # 等待页面加载完成
          browser.network.wait_for_idle
          
          # 计算加载时间
          load_time = (Time.now - start_time) * 1000
          Crawlee.logger.info("页面加载完成，耗时: #{load_time.round(2)} 毫秒")
          
          # 打印页面信息
          Crawlee.logger.info("当前 URL: #{browser.url}")
          Crawlee.logger.info("页面标题: #{browser.page.title rescue '无法获取标题'}")
          
          # 检查页面是否有内容
          html = browser.body
          Crawlee.logger.info("页面 HTML 长度: #{html.length} 字符")
          
          # 如果 HTML 内容过短，可能是加载失败
          if html.length < 100
            Crawlee.logger.warn("警告: 页面 HTML 内容很少，可能加载不完整")
            Crawlee.logger.info("页面内容: #{html}")
          end
        rescue => e
          Crawlee.logger.error("等待页面加载完成时出错: #{e.message}")
          Crawlee.logger.error(e.backtrace.join("\n"))
          
          # 尝试截图记录错误状态
          begin
            screenshot_path = "json/load_error_#{Time.now.strftime('%Y%m%d_%H%M%S')}.png"
            browser.page.screenshot(path: screenshot_path)
            Crawlee.logger.info("已保存加载错误页面截图到: #{screenshot_path}")
          rescue => e2
            Crawlee.logger.error("截图时出错: #{e2.message}")
          end
        end
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
