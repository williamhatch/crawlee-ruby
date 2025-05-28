# frozen_string_literal: true

require 'logger'

module Crawlee
  # Crawlee 的日志记录器
  class Logger
    # 日志级别映射
    LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL
    }.freeze

    # 初始化日志记录器
    # @param level [Symbol] 日志级别
    # @param output [IO] 日志输出目标
    def initialize(level = :info, output = STDOUT)
      @logger = ::Logger.new(output)
      @logger.level = LEVELS[level] || ::Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
    end

    # 记录调试信息
    # @param message [String] 日志消息
    def debug(message)
      @logger.debug(message)
    end

    # 记录普通信息
    # @param message [String] 日志消息
    def info(message)
      @logger.info(message)
    end

    # 记录警告信息
    # @param message [String] 日志消息
    def warn(message)
      @logger.warn(message)
    end

    # 记录错误信息
    # @param message [String] 日志消息
    def error(message)
      @logger.error(message)
    end

    # 记录致命错误信息
    # @param message [String] 日志消息
    def fatal(message)
      @logger.fatal(message)
    end
  end
end
