# frozen_string_literal: true

require 'concurrent'

module Crawlee
  # 管理爬虫会话的池
  # 会话池用于维护与不同网站的持久连接，并实现 Cookie 管理
  class SessionPool
    # 初始化会话池
    # @param size [Integer] 池的最大大小
    # @param persist_cookies [Boolean] 是否在会话之间保持 Cookie
    def initialize(size = nil, persist_cookies: true)
      @size = size || Crawlee.configuration.session_pool_size
      @persist_cookies = persist_cookies
      @sessions = Concurrent::Map.new
      @session_usage = Concurrent::Map.new
      @mutex = Mutex.new
    end

    # 获取指定域名的会话
    # @param domain [String] 域名
    # @return [Hash] 会话数据
    def get_session(domain)
      @mutex.synchronize do
        session = @sessions[domain]
        
        # 如果会话不存在，创建一个新会话
        unless session
          session = create_session(domain)
          @sessions[domain] = session
        end
        
        # 更新会话使用计数
        @session_usage[domain] = (@session_usage[domain] || 0) + 1
        
        session
      end
    end

    # 更新会话的 Cookie
    # @param domain [String] 域名
    # @param cookies [Array<Hash>] Cookie 数组
    # @return [Hash] 更新后的会话
    def update_cookies(domain, cookies)
      @mutex.synchronize do
        session = get_session(domain)
        session[:cookies] ||= []
        
        # 合并新的 Cookie
        cookies.each do |new_cookie|
          # 查找现有的同名 Cookie
          existing_index = session[:cookies].find_index { |c| c[:name] == new_cookie[:name] }
          
          if existing_index
            # 更新现有 Cookie
            session[:cookies][existing_index] = new_cookie
          else
            # 添加新 Cookie
            session[:cookies] << new_cookie
          end
        end
        
        session
      end
    end

    # 获取会话的 Cookie 字符串
    # @param domain [String] 域名
    # @return [String] Cookie 字符串，用于 HTTP 请求头
    def cookie_string(domain)
      session = get_session(domain)
      return '' unless session[:cookies]
      
      session[:cookies]
        .select { |c| !c[:expired] }
        .map { |c| "#{c[:name]}=#{c[:value]}" }
        .join('; ')
    end

    # 清除会话
    # @param domain [String] 域名，如果为 nil，则清除所有会话
    def clear(domain = nil)
      @mutex.synchronize do
        if domain
          @sessions.delete(domain)
          @session_usage.delete(domain)
        else
          @sessions.clear
          @session_usage.clear
        end
      end
    end

    # 获取会话池的统计信息
    # @return [Hash] 统计信息
    def stats
      {
        size: @sessions.size,
        domains: @sessions.keys,
        usage: @session_usage.to_h
      }
    end

    private

    # 创建新会话
    # @param domain [String] 域名
    # @return [Hash] 新会话
    def create_session(domain)
      {
        id: SecureRandom.uuid,
        domain: domain,
        created_at: Time.now.to_i,
        cookies: [],
        user_agent: generate_user_agent,
        headers: {}
      }
    end

    # 生成随机用户代理
    # @return [String] 用户代理字符串
    def generate_user_agent
      # 这里可以使用更复杂的用户代理生成逻辑
      # 或者集成指纹生成器
      Crawlee.configuration.default_headers['User-Agent']
    end

    # 清理过期的会话
    # 当会话池达到最大大小时，移除最少使用的会话
    def cleanup
      return unless @sessions.size >= @size
      
      @mutex.synchronize do
        # 按使用次数排序
        sorted_domains = @session_usage.to_h.sort_by { |_, count| count }
        
        # 移除最少使用的会话，直到池大小低于限制
        while @sessions.size >= @size && !sorted_domains.empty?
          domain, _ = sorted_domains.shift
          @sessions.delete(domain)
          @session_usage.delete(domain)
        end
      end
    end
  end
end
