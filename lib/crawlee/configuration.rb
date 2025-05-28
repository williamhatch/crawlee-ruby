# frozen_string_literal: true

module Crawlee
  # Crawlee 的全局配置类
  class Configuration
    # 默认的最大并发请求数
    DEFAULT_MAX_CONCURRENCY = 10
    
    # 默认的请求超时时间（秒）
    DEFAULT_REQUEST_TIMEOUT = 30
    
    # 默认的重试次数
    DEFAULT_MAX_RETRIES = 3
    
    # 默认的日志级别
    DEFAULT_LOG_LEVEL = :info
    
    # 默认的存储目录
    DEFAULT_STORAGE_DIR = "./storage"
    
    # 默认的请求头
    DEFAULT_HEADERS = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language" => "zh-CN,zh;q=0.9,en;q=0.8"
    }
    
    # 可配置的属性
    attr_accessor :max_concurrency, :request_timeout, :max_retries, 
                  :log_level, :storage_dir, :default_headers,
                  :proxy_configuration, :session_pool_size
    
    def initialize
      @max_concurrency = DEFAULT_MAX_CONCURRENCY
      @request_timeout = DEFAULT_REQUEST_TIMEOUT
      @max_retries = DEFAULT_MAX_RETRIES
      @log_level = DEFAULT_LOG_LEVEL
      @storage_dir = DEFAULT_STORAGE_DIR
      @default_headers = DEFAULT_HEADERS.dup
      @proxy_configuration = nil
      @session_pool_size = 20
    end
    
    # 配置代理
    # @param urls [Array<String>] 代理服务器 URL 列表
    # @param rotation [Symbol] 代理轮换策略 (:round_robin, :random)
    # @return [Hash] 代理配置
    def configure_proxy(urls, rotation: :round_robin)
      @proxy_configuration = {
        urls: urls,
        rotation: rotation
      }
    end
    
    # 配置浏览器选项
    # @param browser_type [Symbol] 浏览器类型 (:chrome, :firefox)
    # @param headless [Boolean] 是否使用无头模式
    # @param args [Array<String>] 浏览器启动参数
    # @return [Hash] 浏览器配置
    def configure_browser(browser_type: :chrome, headless: true, args: [])
      @browser_configuration = {
        browser_type: browser_type,
        headless: headless,
        args: args
      }
    end
  end
end
