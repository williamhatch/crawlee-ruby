# frozen_string_literal: true

require 'nokogiri'

module Crawlee
  # 表示一个 HTTP 响应
  class Response
    # 响应属性
    attr_reader :request, :status_code, :headers, :body, :url, :timing

    # 初始化一个新的响应
    # @param request [Crawlee::Request] 原始请求
    # @param status_code [Integer] HTTP 状态码
    # @param headers [Hash] 响应头
    # @param body [String] 响应体
    # @param url [String] 最终 URL（考虑重定向）
    # @param timing [Hash] 请求计时信息
    def initialize(request, status_code, headers, body, url = nil, timing = {})
      @request = request
      @status_code = status_code
      @headers = headers
      @body = body
      @url = url || request.url
      @timing = timing
      @parsed_html = nil
      @parsed_json = nil
    end

    # 检查响应是否成功
    # @return [Boolean] 如果状态码在 200-299 范围内则为 true
    def success?
      (200..299).include?(@status_code)
    end

    # 检查响应是否为重定向
    # @return [Boolean] 如果状态码在 300-399 范围内则为 true
    def redirect?
      (300..399).include?(@status_code)
    end

    # 检查响应是否为客户端错误
    # @return [Boolean] 如果状态码在 400-499 范围内则为 true
    def client_error?
      (400..499).include?(@status_code)
    end

    # 检查响应是否为服务器错误
    # @return [Boolean] 如果状态码在 500-599 范围内则为 true
    def server_error?
      (500..599).include?(@status_code)
    end

    # 获取响应的内容类型
    # @return [String, nil] 内容类型或 nil
    def content_type
      content_type_header = @headers['Content-Type'] || @headers['content-type']
      return nil unless content_type_header
      content_type_header.split(';').first.strip
    end

    # 检查响应是否为 HTML
    # @return [Boolean] 如果内容类型为 HTML 则为 true
    def html?
      !!(content_type && content_type.include?('text/html'))
    end

    # 检查响应是否为 JSON
    # @return [Boolean] 如果内容类型为 JSON 则为 true
    def json?
      !!(content_type && content_type.include?('application/json'))
    end

    # 将响应体解析为 HTML
    # @return [Nokogiri::HTML::Document] 解析后的 HTML 文档
    def html
      @parsed_html ||= Nokogiri::HTML(@body)
    end

    # 获取 JSON 响应体
    # @return [Hash, Array] 解析后的 JSON 数据
    # @raise [JSON::ParserError] 如果 JSON 解析失败
    def json
      return @parsed_json if @parsed_json
      
      require 'json'
      begin
        @parsed_json = JSON.parse(@body)
      rescue JSON::ParserError => e
        # 只在调试模式下记录解析错误
        Crawlee.logger.debug("JSON 解析错误: #{e.message}")
        raise
      end
    end

    # 将响应转换为哈希
    # @return [Hash] 响应的哈希表示
    def to_h
      {
        request: @request.to_h,
        status_code: @status_code,
        headers: @headers,
        body_size: @body.bytesize,
        url: @url,
        timing: @timing
      }
    end
  end
end
