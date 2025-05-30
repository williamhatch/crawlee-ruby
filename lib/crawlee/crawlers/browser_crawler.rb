# frozen_string_literal: true

# 浏览器爬虫模块的改进说明：
# 1. 添加了 launch_browser 方法，支持无头模式和自定义浏览器选项
# 2. 改进了 extract_cookies 方法，支持多种 Cookie 对象格式（哈希、对象、Ferrum::Cookies::Cookie）
# 3. 增强了 extract_response_headers 方法，兼容不同版本的 Ferrum 返回的响应头格式
# 4. 修复了 BrowserContext 类，添加了 page 参数支持，并实现了各种页面操作方法
# 5. 优化了错误处理和日志记录，提高了代码的健壮性

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
        # 如果指定了 headless 选项，将其添加到浏览器选项中
        @browser_options[:headless] = options[:headless] if options.key?(:headless)
        @browser_pool = []
        @browser_pool_mutex = Mutex.new
      end
      
      # 运行爬虫
      # @param options [Hash] 运行选项
      # @return [Hash] 爬虫统计信息
      def run(options = {})
        Crawlee.logger.info("启动浏览器爬虫...")
        
        # 在运行爬虫前启动浏览器
        Crawlee.logger.info("预先启动浏览器...")
        browser_options = {}
        # 如果指定了 headless 选项，将其添加到浏览器选项中
        browser_options[:headless] = @options[:headless] if @options.key?(:headless)
        
        # 调用 launch_browser 方法启动浏览器
        browser = launch_browser(browser_options)
        
        # 释放浏览器实例，因为每个请求都会重新获取
        release_browser(browser) if browser
        
        # 调用父类的 run 方法
        super(options)
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
        
        # 获取浏览器实例（使用 launch_browser 方法）
        Crawlee.logger.info("启动浏览器实例")
        browser_options = {}
        # 安全地访问 userData，如果存在的话
        if request.respond_to?(:userData) && request.userData.is_a?(Hash) && request.userData[:browserOptions]
          browser_options = request.userData[:browserOptions]
        elsif request.respond_to?(:metadata) && request.metadata.is_a?(Hash) && request.metadata[:browserOptions]
          # 尝试从 metadata 中获取浏览器选项
          browser_options = request.metadata[:browserOptions]
        end
        browser = launch_browser(browser_options)
        
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
        # 尝试从响应中获取页面对象
        page = nil
        
        # 如果响应中包含页面信息，尝试提取
        if response.respond_to?(:metadata) && response.metadata.is_a?(Hash) && response.metadata[:page]
          page = response.metadata[:page]
        end
        
        # 创建浏览器上下文实例，传递四个参数
        BrowserContext.new(self, request, response, page)
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
      
      # 启动浏览器
      # @param options [Hash] 浏览器选项
      # @return [Ferrum::Browser] 浏览器实例
      def launch_browser(options = {})
        Crawlee.logger.info("启动浏览器...")
        
        # 合并默认选项和用户提供的选项
        browser_options = @browser_options.dup || {}
        browser_options.merge!(options)
        
        # 创建浏览器实例
        browser = create_browser_with_options(browser_options)
        
        # 如果创建失败，尝试再次创建
        if browser.nil?
          Crawlee.logger.warn("首次创建浏览器失败，尝试再次创建...")
          browser = create_browser_with_options(browser_options)
        end
        
        browser
      end
      
      # 创建新的浏览器实例
      # @return [Ferrum::Browser] 浏览器实例
      def create_browser
        create_browser_with_options(@browser_options || {})
      end
      
      # 使用指定选项创建浏览器实例
      # @param custom_options [Hash] 自定义浏览器选项
      # @return [Ferrum::Browser] 浏览器实例
      def create_browser_with_options(custom_options = {})
        Crawlee.logger.info("开始创建新的浏览器实例...")
        
        begin
          # 准备浏览器选项
          options = {
            headless: @options[:headless] || false,  # 默认非无头模式，方便调试
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
          if custom_options && !custom_options.empty?
            Crawlee.logger.info("合并用户提供的浏览器选项:")
            custom_options.each do |key, value|
              Crawlee.logger.info("  #{key}: #{value.inspect}")
            end
            options.merge!(custom_options)
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
          Crawlee.logger.debug("最后一个请求类型: #{last_request.class}")
          
          if last_request
            # 处理不同类型的请求对象
            if last_request.is_a?(Hash) && last_request[:response] && last_request[:response][:headers]
              # 旧版本的 Ferrum 返回哈希
              headers = last_request[:response][:headers] || {}
              Crawlee.logger.debug("使用哈希格式获取响应头")
            elsif last_request.respond_to?(:response) && last_request.response
              # 新版本的 Ferrum 返回对象
              response = last_request.response
              
              if response.respond_to?(:headers)
                # 直接使用 headers 方法
                headers = response.headers || {}
                Crawlee.logger.debug("使用 headers 方法获取响应头")
              elsif response.respond_to?(:[])
                # 尝试使用 [] 访问 headers
                headers = response[:headers] || response['headers'] || {}
                Crawlee.logger.debug("使用 [] 访问获取响应头")
              elsif response.instance_variable_defined?(:@params) && 
                    response.instance_variable_get(:@params).is_a?(Hash) && 
                    response.instance_variable_get(:@params)['response']
                # 从 @params 中提取
                params_response = response.instance_variable_get(:@params)['response']
                headers = params_response['headers'] || {}
                Crawlee.logger.debug("从 @params 中提取响应头")
              elsif response.instance_variable_defined?(:@response) && 
                    response.instance_variable_get(:@response).is_a?(Hash)
                # 从 @response 中提取
                headers = response.instance_variable_get(:@response)['headers'] || {}
                Crawlee.logger.debug("从 @response 中提取响应头")
              end
            end
          end
          
          # 确保 headers 是一个哈希
          headers = {} unless headers.is_a?(Hash)
          
        rescue => e
          Crawlee.logger.warn("提取响应头失败: #{e.message}")
          Crawlee.logger.debug(e.backtrace.join("\n"))
        end
        
        Crawlee.logger.info("提取到响应头: #{headers.keys.size} 个")
        headers
      end
      
      # 提取 Cookie
      # @param browser [Ferrum::Browser] 浏览器实例
      # @return [Array<Hash>] Cookie 数组
      def extract_cookies(browser)
        begin
          # 获取所有 cookie
          all_cookies = browser.cookies.all
          
          # 如果没有 cookie，返回空数组
          if all_cookies.nil? || all_cookies.empty?
            Crawlee.logger.debug("没有找到 cookie")
            return []
          end
          
          Crawlee.logger.debug("提取 cookie，总数: #{all_cookies.size}, 格式: #{all_cookies.first.class}")
          
          cookies = all_cookies.map do |cookie|
            # 检查 cookie 的类型和访问方式
            cookie_data = {}
            
            begin
              if cookie.is_a?(Hash)
                # 哈希格式
                Crawlee.logger.debug("处理哈希格式 cookie: #{cookie.keys.join(', ')}")
                cookie_data = {
                  name: cookie[:name] || cookie['name'],
                  value: cookie[:value] || cookie['value'],
                  domain: cookie[:domain] || cookie['domain'],
                  path: cookie[:path] || cookie['path'],
                  expires: (cookie[:expires] || cookie['expires'])&.to_i,
                  httponly: cookie[:httpOnly] || cookie[:httponly] || cookie['httpOnly'] || cookie['httponly'] || false,
                  secure: cookie[:secure] || cookie['secure'] || false,
                  expired: false
                }
              elsif cookie.respond_to?(:to_h)
                # 可转换为哈希的对象
                Crawlee.logger.debug("将对象转换为哈希")
                hash = cookie.to_h
                cookie_data = {
                  name: hash[:name] || hash['name'],
                  value: hash[:value] || hash['value'],
                  domain: hash[:domain] || hash['domain'],
                  path: hash[:path] || hash['path'],
                  expires: (hash[:expires] || hash['expires'])&.to_i,
                  httponly: hash[:httpOnly] || hash[:httponly] || hash['httpOnly'] || hash['httponly'] || false,
                  secure: hash[:secure] || hash['secure'] || false,
                  expired: false
                }
              elsif cookie.respond_to?(:name) && cookie.respond_to?(:value)
                # 对象具有方法访问方式
                Crawlee.logger.debug("使用方法访问 cookie 属性")
                cookie_data = {
                  name: cookie.name,
                  value: cookie.value,
                  domain: cookie.respond_to?(:domain) ? cookie.domain : 'unknown',
                  path: cookie.respond_to?(:path) ? cookie.path : '/',
                  expires: cookie.respond_to?(:expires) ? cookie.expires&.to_i : nil,
                  httponly: cookie.respond_to?(:httponly) ? cookie.httponly : false,
                  secure: cookie.respond_to?(:secure) ? cookie.secure : false,
                  expired: false
                }
              elsif cookie.instance_variable_defined?(:@attributes) && cookie.instance_variable_get(:@attributes).is_a?(Hash)
                # Ferrum::Cookies::Cookie 类型
                Crawlee.logger.debug("从 @attributes 中提取 cookie 属性")
                attrs = cookie.instance_variable_get(:@attributes)
                cookie_data = {
                  name: attrs['name'],
                  value: attrs['value'],
                  domain: attrs['domain'] || 'unknown',
                  path: attrs['path'] || '/',
                  expires: attrs['expires'] ? Time.parse(attrs['expires']).to_i : nil,
                  httponly: attrs['httpOnly'] || false,
                  secure: attrs['secure'] || false,
                  expired: false
                }
              else
                # 尝试使用反射获取属性
                Crawlee.logger.debug("使用反射获取 cookie 属性: #{cookie.methods.grep(/name|value|domain|path/).join(', ')}")
                name_method = cookie.methods.grep(/name/).first
                value_method = cookie.methods.grep(/value/).first
                
                if name_method && value_method
                  cookie_data = {
                    name: cookie.send(name_method),
                    value: cookie.send(value_method),
                    domain: cookie.methods.grep(/domain/).first ? cookie.send(cookie.methods.grep(/domain/).first) : 'unknown',
                    path: cookie.methods.grep(/path/).first ? cookie.send(cookie.methods.grep(/path/).first) : '/',
                    expires: cookie.methods.grep(/expires/).first ? cookie.send(cookie.methods.grep(/expires/).first)&.to_i : nil,
                    httponly: cookie.methods.grep(/httponly|http_only/).first ? cookie.send(cookie.methods.grep(/httponly|http_only/).first) : false,
                    secure: cookie.methods.grep(/secure/).first ? cookie.send(cookie.methods.grep(/secure/).first) : false,
                    expired: false
                  }
                end
              end
            rescue => e
              Crawlee.logger.warn("处理 cookie 时出错: #{e.message}")
              Crawlee.logger.debug("问题 cookie: #{cookie.inspect}")
              Crawlee.logger.debug(e.backtrace.join("\n"))
            end
            
            # 确保所有必要字段都存在
            cookie_data[:name] ||= 'unknown'
            cookie_data[:value] ||= 'unknown'
            cookie_data[:domain] ||= 'unknown'
            cookie_data[:path] ||= '/'
            cookie_data[:httponly] ||= false
            cookie_data[:secure] ||= false
            cookie_data[:expired] ||= false
            
            cookie_data
          end.compact
          
          Crawlee.logger.info("提取到 #{cookies.size} 个 Cookie")
          cookies
        rescue => e
          Crawlee.logger.error("提取 cookie 时出错: #{e.message}")
          Crawlee.logger.debug(e.backtrace.join("\n"))
          []
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
      # @param page [Ferrum::Page] 页面对象
      def initialize(crawler, request, response, page = nil)
        @crawler = crawler
        @request = request
        @response = response
        @page = page
        @metadata = request.metadata.dup
      end
      
      # 获取爬虫实例
      # @return [BrowserCrawler] 爬虫实例
      attr_reader :crawler
      
      # 获取请求对象
      # @return [Crawlee::Request] 请求对象
      attr_reader :request
      
      # 获取响应对象
      # @return [Crawlee::Response] 响应对象
      attr_reader :response
      
      # 获取页面对象
      # @return [Ferrum::Page] 页面对象
      attr_reader :page
      
      # 获取元数据
      # @return [Hash] 元数据
      attr_reader :metadata
      
      # 获取 HTML 文档
      # @return [Nokogiri::HTML::Document] HTML 文档
      def html
        @html ||= begin
          if @response.respond_to?(:html)
            # 如果响应对象有 html 方法，直接使用
            @response.html
          elsif @response.respond_to?(:body) && @response.body.is_a?(String)
            # 如果响应对象有 body 方法，使用 Nokogiri 解析
            Nokogiri::HTML(@response.body)
          elsif @page && @page.respond_to?(:body)
            # 如果有页面对象，使用页面对象的 body
            Nokogiri::HTML(@page.body)
          else
            # 在测试环境中，可能使用的是 mock 对象
            # 返回一个空的 HTML 文档
            Nokogiri::HTML('')
          end
        end
      end
      
      # 查找 HTML 元素
      # @param selector [String] CSS 选择器
      # @return [Nokogiri::XML::NodeSet] 元素集合
      def query_selector_all(selector)
        if @page && @page.respond_to?(:query_selector_all)
          # 如果有页面对象，使用页面对象的 query_selector_all 方法
          @page.query_selector_all(selector)
        else
          # 否则使用 Nokogiri 的 css 方法
          html.css(selector)
        end
      end
      
      # 查找单个 HTML 元素
      # @param selector [String] CSS 选择器
      # @return [Nokogiri::XML::Element, nil] 元素或 nil
      def query_selector(selector)
        if @page && @page.respond_to?(:query_selector)
          # 如果有页面对象，使用页面对象的 query_selector 方法
          @page.query_selector(selector)
        else
          # 否则使用 Nokogiri 的 at_css 方法
          html.at_css(selector)
        end
      end
      
      # 从页面提取链接并添加到队列
      # @param selector [String] CSS 选择器
      # @param options [Hash] 请求选项
      # @return [Integer] 添加的链接数量
      def enqueue_links(selector = 'a', options = {})
        Crawlee.logger.debug("从页面提取链接，选择器: #{selector}")
        links = query_selector_all(selector).map do |element|
          href = element['href']
          next if href.nil? || href.empty? || href.start_with?('#')
          
          # 跳过 JavaScript 链接
          if href.start_with?('javascript:')
            Crawlee.logger.debug("跳过 JavaScript 链接: #{href}")
            next
          end
          
          # 处理可能包含单引号或双引号的 URL
          if href.include?("'") || href.include?('"')
            href = href.gsub(/['"]/, '')
            Crawlee.logger.debug("清理引号后的 URL: #{href}")
          end
          
          # 处理相对 URL
          if !href.start_with?('http://') && !href.start_with?('https://')
            base_url = @response.url
            href = URI.join(base_url, href).to_s
          end
          
          href
        end.compact
        
        Crawlee.logger.debug("提取到 #{links.size} 个链接")
        
        # 添加链接到队列
        count = 0
        links.each do |url|
          if @crawler.enqueue(url, options)
            count += 1
          end
        end
        
        count
      end
      
      # 在页面上下文中执行 JavaScript
      # @param script [String] JavaScript 代码
      # @return [Object] 执行结果
      def evaluate(script)
        if @page && @page.respond_to?(:evaluate)
          @page.evaluate(script)
        else
          Crawlee.logger.warn("无法执行 JavaScript，页面对象不可用")
          nil
        end
      end
      
      # 等待选择器匹配的元素出现
      # @param selector [String] CSS 选择器
      # @param options [Hash] 选项
      # @return [Object] 元素
      def wait_for_selector(selector, options = {})
        if @page && @page.respond_to?(:wait_for_selector)
          @page.wait_for_selector(selector, options)
        else
          Crawlee.logger.warn("无法等待元素，页面对象不可用")
          query_selector(selector)
        end
      end
      
      # 点击页面中的元素
      # @param selector [String] CSS 选择器
      # @param options [Hash] 选项
      # @return [Boolean] 是否成功
      def click(selector, options = {})
        if @page && @page.respond_to?(:click)
          @page.click(selector, options)
          true
        else
          Crawlee.logger.warn("无法点击元素，页面对象不可用")
          false
        end
      end
      
      # 在页面中的输入框中输入文本
      # @param selector [String] CSS 选择器
      # @param text [String] 要输入的文本
      # @param options [Hash] 选项
      # @return [Boolean] 是否成功
      def type(selector, text, options = {})
        if @page && @page.respond_to?(:type)
          @page.type(selector, text, options)
          true
        else
          Crawlee.logger.warn("无法输入文本，页面对象不可用")
          false
        end
      end
      
      # 截取页面截图
      # @param options [Hash] 选项
      # @return [Object] 截图结果
      def screenshot(options = {})
        if @page && @page.respond_to?(:screenshot)
          # 直接返回 page.screenshot 的结果，不做任何修改
          @page.screenshot(options)
        else
          Crawlee.logger.warn("无法截取页面截图，页面对象不可用")
          nil
        end
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
