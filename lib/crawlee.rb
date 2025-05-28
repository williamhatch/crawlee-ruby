# frozen_string_literal: true

require_relative "crawlee/version"
require_relative "crawlee/configuration"
require_relative "crawlee/logger"
require_relative "crawlee/request"
require_relative "crawlee/response"
require_relative "crawlee/session_pool"
require_relative "crawlee/storage"
require_relative "crawlee/fingerprint_generator"
require_relative "crawlee/crawlers/base_crawler"
require_relative "crawlee/crawlers/http_crawler"
require_relative "crawlee/crawlers/browser_crawler"
require_relative "crawlee/crawlers/adaptive_crawler"
require_relative "crawlee/fix_encoding"

# Crawlee 是一个用于构建可靠爬虫的 Ruby 库
# 它处理网站封锁、代理轮换和浏览器自动化等问题
module Crawlee
  class Error < StandardError; end
  
  class << self
    attr_writer :configuration
    
    # 获取或初始化配置
    # @return [Crawlee::Configuration] 当前配置
    def configuration
      @configuration ||= Configuration.new
    end
    
    # 配置 Crawlee
    # @yield [config] 配置块
    # @example
    #   Crawlee.configure do |config|
    #     config.max_concurrency = 10
    #     config.request_timeout = 30
    #   end
    def configure
      yield(configuration)
    end
    
    # 获取日志记录器
    # @return [Crawlee::Logger] 日志记录器实例
    def logger
      @logger ||= Logger.new(configuration.log_level)
    end
  end
end
