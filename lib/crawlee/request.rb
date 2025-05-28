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
    # @param method [Symbol] HTTP 方法
    # @param headers [Hash] 请求头
    # @param payload [Hash, String] 请求体
    # @param metadata [Hash] 与请求关联的元数据
    def initialize(url, method: :get, headers: {}, payload: nil, metadata: {})
      @id = SecureRandom.uuid
      @url = normalize_url(url)
      @method = validate_method(method)
      @headers = Crawlee.configuration.default_headers.merge(headers)
      @payload = payload
      @metadata = metadata
      @retry_count = 0
    end

    # 获取请求的域名
    # @return [String] 域名
    def domain
      Addressable::URI.parse(@url).host
    end

    # 获取请求的路径
    # @return [String] 路径
    def path
      Addressable::URI.parse(@url).path
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
        method: @method,
        headers: @headers.dup,
        payload: @payload.is_a?(Hash) ? @payload.dup : @payload,
        metadata: @metadata.dup
      )
    end

    # 将请求转换为哈希
    # @return [Hash] 请求的哈希表示
    def to_h
      {
        id: @id,
        url: @url,
        method: @method,
        headers: @headers,
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
      uri = Addressable::URI.parse(url)
      uri.scheme = 'http' if uri.scheme.nil?
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
