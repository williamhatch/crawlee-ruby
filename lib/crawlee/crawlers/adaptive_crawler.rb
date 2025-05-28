# frozen_string_literal: true

module Crawlee
  module Crawlers
    # 自适应爬虫类，根据需要在 HTTP 和浏览器模式之间切换
    class AdaptiveCrawler < BaseCrawler
      # 初始化自适应爬虫
      # @param options [Hash] 爬虫选项
      def initialize(options = {})
        super(options)
        
        # 创建 HTTP 爬虫和浏览器爬虫实例
        @http_crawler = HttpCrawler.new(options)
        @browser_crawler = BrowserCrawler.new(options)
        
        # 初始化 URL 模式缓存
        @url_patterns = {
          http: [],      # 使用 HTTP 爬虫的 URL 模式
          browser: []    # 使用浏览器爬虫的 URL 模式
        }
        @url_patterns_mutex = Mutex.new
      end
      
      # 添加 HTTP 爬虫 URL 模式
      # @param pattern [Regexp, String] URL 模式
      def add_http_pattern(pattern)
        @url_patterns_mutex.synchronize do
          @url_patterns[:http] << pattern
        end
      end
      
      # 添加浏览器爬虫 URL 模式
      # @param pattern [Regexp, String] URL 模式
      def add_browser_pattern(pattern)
        @url_patterns_mutex.synchronize do
          @url_patterns[:browser] << pattern
        end
      end
      
      protected
      
      # 执行请求
      # @param request [Crawlee::Request] 请求对象
      # @return [Crawlee::Response] 响应对象
      def do_request(request)
        # 确定使用哪种爬虫
        crawler_type = determine_crawler_type(request.url)
        
        # 执行请求
        response = case crawler_type
                   when :browser
                     Crawlee.logger.info("使用浏览器爬虫处理: #{request.url}")
                     @browser_crawler.send(:do_request, request)
                   else
                     Crawlee.logger.info("使用 HTTP 爬虫处理: #{request.url}")
                     @http_crawler.send(:do_request, request)
                   end
        
        # 如果 HTTP 爬虫失败，尝试使用浏览器爬虫
        if crawler_type == :http && !response.success? && needs_javascript?(response)
          Crawlee.logger.info("HTTP 爬虫失败，切换到浏览器爬虫: #{request.url}")
          
          # 添加到浏览器模式缓存
          add_browser_pattern(extract_url_pattern(request.url))
          
          # 使用浏览器爬虫重试
          response = @browser_crawler.send(:do_request, request)
        end
        
        # 更新 URL 模式缓存
        if response.success?
          update_url_patterns(request.url, crawler_type)
        end
        
        response
      end
      
      # 创建上下文
      # @param request [Crawlee::Request] 请求对象
      # @param response [Crawlee::Response] 响应对象
      # @return [AdaptiveContext] 上下文对象
      def create_context(request, response)
        AdaptiveContext.new(self, request, response)
      end
      
      private
      
      # 确定使用哪种爬虫
      # @param url [String] URL
      # @return [Symbol] 爬虫类型 (:http 或 :browser)
      def determine_crawler_type(url)
        @url_patterns_mutex.synchronize do
          # 检查是否匹配浏览器模式
          @url_patterns[:browser].each do |pattern|
            return :browser if url_match?(url, pattern)
          end
          
          # 检查是否匹配 HTTP 模式
          @url_patterns[:http].each do |pattern|
            return :http if url_match?(url, pattern)
          end
        end
        
        # 默认使用 HTTP 爬虫
        :http
      end
      
      # 检查 URL 是否匹配模式
      # @param url [String] URL
      # @param pattern [Regexp, String] URL 模式
      # @return [Boolean] 是否匹配
      def url_match?(url, pattern)
        case pattern
        when Regexp
          pattern.match?(url)
        when String
          url.include?(pattern)
        else
          false
        end
      end
      
      # 更新 URL 模式缓存
      # @param url [String] URL
      # @param crawler_type [Symbol] 爬虫类型
      def update_url_patterns(url, crawler_type)
        pattern = extract_url_pattern(url)
        
        @url_patterns_mutex.synchronize do
          case crawler_type
          when :http
            @url_patterns[:http] << pattern unless @url_patterns[:http].any? { |p| p == pattern }
          when :browser
            @url_patterns[:browser] << pattern unless @url_patterns[:browser].any? { |p| p == pattern }
          end
        end
      end
      
      # 从 URL 提取模式
      # @param url [String] URL
      # @return [String] URL 模式
      def extract_url_pattern(url)
        uri = URI.parse(url)
        "#{uri.host}#{uri.path.split('/').first(2).join('/')}"
      rescue URI::InvalidURIError
        url
      end
      
      # 检查响应是否需要 JavaScript
      # @param response [Crawlee::Response] 响应对象
      # @return [Boolean] 是否需要 JavaScript
      def needs_javascript?(response)
        return false unless response.html?
        
        body = response.body.to_s.downcase
        
        # 检查常见的 JavaScript 框架和加载指示器
        js_indicators = [
          'window.onload', 'document.ready', 'vue', 'react', 'angular',
          'loading...', '加载中', 'please enable javascript',
          'please wait', 'content is loading'
        ]
        
        # 检查是否有大量的 JavaScript 代码
        has_js_code = body.scan(/<script[^>]*>(.*?)<\/script>/im).size > 5
        
        # 检查是否有 JavaScript 框架或加载指示器
        has_js_indicators = js_indicators.any? { |indicator| body.include?(indicator) }
        
        # 检查内容是否很少（可能是未渲染的页面）
        has_little_content = response.html.css('body').text.strip.length < 1000
        
        has_js_code || has_js_indicators || has_little_content
      end
    end
    
    # 自适应上下文类
    class AdaptiveContext
      # 初始化自适应上下文
      # @param crawler [AdaptiveCrawler] 爬虫实例
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
      
      # 将 URL 模式添加到 HTTP 爬虫
      # @param pattern [Regexp, String] URL 模式
      def add_http_pattern(pattern)
        @crawler.add_http_pattern(pattern)
      end
      
      # 将 URL 模式添加到浏览器爬虫
      # @param pattern [Regexp, String] URL 模式
      def add_browser_pattern(pattern)
        @crawler.add_browser_pattern(pattern)
      end
    end
  end
end
