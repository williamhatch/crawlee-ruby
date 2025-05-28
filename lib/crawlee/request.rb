# frozen_string_literal: true

require 'addressable/uri'
require 'securerandom'

module Crawlee
  # 表示一个 HTTP 请求
  class Request
    # 支持的 HTTP 方法
    METHODS = [:get, :post, :put, :delete, :head, :options, :patch].freeze

    # 请求属性
    attr_reader :id, :url, :method, :headers, :payload, :metadata
    attr_accessor :retry_count

    # 初始化一个新的请求
    # @param url [String] 请求 URL
    # @param options [Hash] 请求选项
    def initialize(url, options = {})
      @id = SecureRandom.uuid
      @url = normalize_url(url)
      @method = validate_method(options[:method] || :get)
      # 保存用户提供的原始头部
      @original_headers = options[:headers] || {}
      @headers = Crawlee.configuration.default_headers.merge(@original_headers)
      @payload = options[:payload]
      @metadata = options[:metadata] || {}
      @retry_count = 0
    end

    # 获取请求的域名
    # @return [String] 域名
    def domain
      uri = Addressable::URI.parse(@url)
      uri&.host
    rescue => e
      puts "URL解析错误: #{e.message}, URL: #{@url}"
      nil
    end

    # 获取请求的路径
    # @return [String] 路径
    def path
      uri = Addressable::URI.parse(@url)
      uri&.path
    rescue => e
      puts "URL解析错误: #{e.message}, URL: #{@url}"
      nil
    end

    # 获取请求的查询参数
    # @return [Hash] 查询参数
    def query_params
      uri = Addressable::URI.parse(@url)
      uri.query_values || {}
    end

    # 克隆请求
    # @return [Request] 请求的副本
    def clone
      Request.new(
        @url,
        {
          method: @method,
          headers: @headers.dup,
          payload: @payload.is_a?(Hash) ? @payload.dup : @payload,
          metadata: @metadata.dup
        }
      )
    end

    # 将请求转换为哈希
    # @return [Hash] 请求的哈希表示
    def to_h
      # 在初始化时保存用户提供的原始头部
      original_headers = @original_headers || @headers
      
      {
        id: @id,
        url: @url,
        method: @method,
        headers: original_headers,
        payload: @payload,
        metadata: @metadata,
        retry_count: @retry_count
      }
    end

    private

    # 规范化 URL
    # @param url [String] 原始 URL
    # @return [String] 规范化后的 URL
    def normalize_url(url)
      # 如果 URL 不包含协议和双斜线，添加 http://
      url = "http://#{url}" unless url =~ %r{\A[a-z][a-z0-9+\-.]*://}
      
      uri = Addressable::URI.parse(url)
      # 确保有协议
      uri.scheme = 'http' if uri.scheme.nil?
      # 确保有主机名
      return url if uri.host.nil?
      
      uri.to_s
    end

    # 验证 HTTP 方法
    # @param method [Symbol] HTTP 方法
    # @return [Symbol] 验证后的 HTTP 方法
    # @raise [ArgumentError] 如果方法无效
    def validate_method(method)
      method = method.to_sym.downcase
      unless METHODS.include?(method)
        raise ArgumentError, "不支持的 HTTP 方法: #{method}. 支持的方法: #{METHODS.join(', ')}"
      end
      method
    end
  end
end
