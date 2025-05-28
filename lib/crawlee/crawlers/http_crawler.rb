# frozen_string_literal: true

require 'httparty'

module Crawlee
  module Crawlers
    # HTTP 爬虫类，用于处理 HTTP 请求
    class HttpCrawler < BaseCrawler
      # 初始化 HTTP 爬虫
      # @param options [Hash] 爬虫选项
      def initialize(options = {})
        super(options)
      end
      
      protected
      
      # 执行 HTTP 请求
      # @param request [Crawlee::Request] 请求对象
      # @return [Crawlee::Response] 响应对象
      def do_request(request)
        start_time = Time.now
        
        # 获取会话
        session = @session_pool.get_session(request.domain)
        
        # 合并会话 Cookie
        headers = request.headers.dup
        cookie_string = @session_pool.cookie_string(request.domain)
        headers['Cookie'] = cookie_string unless cookie_string.empty?
        
        # 准备请求选项
        options = {
          headers: headers,
          timeout: @options[:request_timeout],
          follow_redirects: true
        }
        
        # 添加代理配置
        if @options[:proxy_configuration]
          proxy_url = select_proxy
          options[:http_proxyaddr], options[:http_proxyport] = parse_proxy_url(proxy_url) if proxy_url
        end
        
        # 添加请求体
        if request.payload
          if request.method == :get
            options[:query] = request.payload
          else
            options[:body] = request.payload
          end
        end
        
        # 执行请求
        begin
          response = HTTParty.send(
            request.method,
            request.url,
            options
          )
          
          # 计算请求时间
          end_time = Time.now
          timing = {
            start_time: start_time.to_f,
            end_time: end_time.to_f,
            duration: (end_time - start_time) * 1000
          }
          
          # 更新会话 Cookie
          if response.headers['set-cookie']
            cookies = parse_cookies(response.headers['set-cookie'], request.domain)
            @session_pool.update_cookies(request.domain, cookies)
          end
          
          # 创建响应对象
          Crawlee::Response.new(
            request,
            response.code,
            response.headers.to_h,
            response.body,
            response.request.last_uri.to_s,
            timing
          )
        rescue => e
          Crawlee.logger.error("HTTP 请求错误: #{e.message}")
          
          # 创建错误响应
          Crawlee::Response.new(
            request,
            0,
            {},
            e.message,
            request.url,
            { error: e.message }
          )
        end
      end
      
      # 创建 HTTP 上下文
      # @param request [Crawlee::Request] 请求对象
      # @param response [Crawlee::Response] 响应对象
      # @return [HttpContext] HTTP 上下文对象
      def create_context(request, response)
        HttpContext.new(self, request, response)
      end
      
      private
      
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
      
      # 解析代理 URL
      # @param proxy_url [String] 代理 URL
      # @return [Array<String, Integer>] 代理主机和端口
      def parse_proxy_url(proxy_url)
        uri = URI.parse(proxy_url)
        [uri.host, uri.port]
      end
      
      # 解析 Cookie
      # @param set_cookie [String] Set-Cookie 头
      # @param domain [String] 域名
      # @return [Array<Hash>] Cookie 数组
      def parse_cookies(set_cookie, domain)
        cookies = []
        
        set_cookie.split(/,\s*(?=[^;,]*=)/).each do |cookie_str|
          parts = cookie_str.split(';').map(&:strip)
          name_value = parts.shift.split('=', 2)
          
          cookie = {
            name: name_value[0],
            value: name_value[1],
            domain: domain,
            path: '/',
            expires: nil,
            httponly: false,
            secure: false,
            expired: false
          }
          
          # 解析 Cookie 属性
          parts.each do |part|
            case part.downcase
            when 'httponly'
              cookie[:httponly] = true
            when 'secure'
              cookie[:secure] = true
            when /^expires=(.*)/i
              cookie[:expires] = Time.parse($1).to_i rescue nil
              cookie[:expired] = !cookie[:expires].nil? && Time.now.to_i > cookie[:expires]
            when /^path=(.*)/i
              cookie[:path] = $1
            when /^domain=(.*)/i
              cookie[:domain] = $1
            end
          end
          
          cookies << cookie
        end
        
        cookies
      end
    end
    
    # HTTP 上下文类
    class HttpContext
      # 初始化 HTTP 上下文
      # @param crawler [HttpCrawler] 爬虫实例
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
          
          # 处理可能包含单引号或双引号的 URL
          if href.include?("'") || href.include?('"')
            href = href.gsub(/['"]/,'') 
          end
          
          # 构建完整 URL
          begin
            if href =~ /\Ahttps?:\/\//
              # 已经是完整的 URL
              href
            else
              URI.join(@response.url, href).to_s
            end
          rescue URI::InvalidURIError => e
            Crawlee.logger.debug("Invalid URI: #{href} - #{e.message}")
            nil
          end
        end.compact
        
        # 确保所有链接都被添加到队列
        Crawlee.logger.debug("Enqueueing links: #{links.inspect}")
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
