# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'concurrent'

module Crawlee
  # 存储管理类，用于保存爬虫数据和请求队列
  class Storage
    # 存储类型
    TYPES = [:request_queue, :dataset, :key_value].freeze
    
    # 初始化存储
    # @param base_dir [String] 基础存储目录
    def initialize(base_dir = nil)
      @base_dir = base_dir || Crawlee.configuration.storage_dir
      @locks = Concurrent::Map.new
      
      # 确保存储目录存在
      initialize_storage_dirs
    end
    
    # 获取请求队列存储
    # @param name [String] 队列名称
    # @return [RequestQueueStorage] 请求队列存储
    def request_queue(name = 'default')
      RequestQueueStorage.new(File.join(@base_dir, 'request_queues', name))
    end
    
    # 获取数据集存储
    # @param name [String] 数据集名称
    # @return [DatasetStorage] 数据集存储
    def dataset(name = 'default')
      DatasetStorage.new(File.join(@base_dir, 'datasets', name))
    end
    
    # 获取键值存储
    # @param name [String] 存储名称
    # @return [KeyValueStorage] 键值存储
    def key_value(name = 'default')
      KeyValueStorage.new(File.join(@base_dir, 'key_value_stores', name))
    end
    
    # 清除所有存储
    # @param type [Symbol, nil] 要清除的存储类型，如果为 nil，则清除所有类型
    def clear(type = nil)
      if type.nil?
        TYPES.each { |t| clear(t) }
        return
      end
      
      raise ArgumentError, "无效的存储类型: #{type}" unless TYPES.include?(type)
      
      dir = File.join(@base_dir, "#{type}s")
      FileUtils.rm_rf(dir)
      FileUtils.mkdir_p(dir)
    end
    
    private
    
    # 初始化存储目录
    def initialize_storage_dirs
      FileUtils.mkdir_p(@base_dir)
      
      TYPES.each do |type|
        FileUtils.mkdir_p(File.join(@base_dir, "#{type}s"))
      end
    end
    
    # 请求队列存储类
    class RequestQueueStorage
      # 初始化请求队列存储
      # @param dir [String] 存储目录
      def initialize(dir)
        @dir = dir
        @mutex = Mutex.new
        FileUtils.mkdir_p(@dir)
        @queue_file = File.join(@dir, 'queue.json')
        @handled_file = File.join(@dir, 'handled.json')
        
        # 初始化队列文件
        initialize_files
      end
      
      # 添加请求到队列
      # @param request [Crawlee::Request] 请求对象
      # @return [Boolean] 是否成功添加
      def add_request(request)
        @mutex.synchronize do
          # 读取当前队列
          queue = read_json_file(@queue_file) || []
          handled = read_json_file(@handled_file) || []
          
          # 检查请求是否已经在队列中或已处理
          request_id = request.id
          return false if queue.any? { |r| r['id'] == request_id }
          return false if handled.any? { |id| id == request_id }
          
          # 添加请求到队列
          queue << request.to_h
          write_json_file(@queue_file, queue)
          
          true
        end
      end
      
      # 获取下一个请求
      # @return [Crawlee::Request, nil] 下一个请求或 nil
      def next_request
        @mutex.synchronize do
          queue = read_json_file(@queue_file) || []
          return nil if queue.empty?
          
          # 获取第一个请求
          request_data = queue.shift
          write_json_file(@queue_file, queue)
          
          # 创建请求对象
          request = Crawlee::Request.new(
            request_data['url'],
            method: request_data['method'].to_sym,
            headers: request_data['headers'],
            payload: request_data['payload'],
            metadata: request_data['metadata']
          )
          
          # 设置请求 ID 和重试计数
          request.instance_variable_set(:@id, request_data['id'])
          request.retry_count = request_data['retry_count'] || 0
          
          request
        end
      end
      
      # 标记请求为已处理
      # @param request_id [String] 请求 ID
      # @return [Boolean] 是否成功标记
      def mark_handled(request_id)
        @mutex.synchronize do
          handled = read_json_file(@handled_file) || []
          return false if handled.include?(request_id)
          
          handled << request_id
          write_json_file(@handled_file, handled)
          
          true
        end
      end
      
      # 重新添加请求到队列
      # @param request [Crawlee::Request] 请求对象
      # @return [Boolean] 是否成功添加
      def reclaim_request(request)
        @mutex.synchronize do
          queue = read_json_file(@queue_file) || []
          
          # 增加重试计数
          request.retry_count += 1
          
          # 添加请求到队列头部
          queue.unshift(request.to_h)
          write_json_file(@queue_file, queue)
          
          true
        end
      end
      
      # 获取队列统计信息
      # @return [Hash] 统计信息
      def get_info
        @mutex.synchronize do
          queue = read_json_file(@queue_file) || []
          handled = read_json_file(@handled_file) || []
          
          {
            pending_count: queue.size,
            handled_count: handled.size,
            total_count: queue.size + handled.size
          }
        end
      end
      
      private
      
      # 初始化文件
      def initialize_files
        unless File.exist?(@queue_file)
          write_json_file(@queue_file, [])
        end
        
        unless File.exist?(@handled_file)
          write_json_file(@handled_file, [])
        end
      end
      
      # 读取 JSON 文件
      # @param file [String] 文件路径
      # @return [Array, Hash, nil] 解析后的 JSON 数据
      def read_json_file(file)
        return nil unless File.exist?(file)
        
        begin
          JSON.parse(File.read(file))
        rescue JSON::ParserError => e
          Crawlee.logger.error("JSON 解析错误: #{e.message}")
          nil
        end
      end
      
      # 写入 JSON 文件
      # @param file [String] 文件路径
      # @param data [Array, Hash] 要写入的数据
      def write_json_file(file, data)
        File.write(file, JSON.pretty_generate(data))
      end
    end
    
    # 数据集存储类
    class DatasetStorage
      # 初始化数据集存储
      # @param dir [String] 存储目录
      def initialize(dir)
        @dir = dir
        @mutex = Mutex.new
        FileUtils.mkdir_p(@dir)
        @data_file = File.join(@dir, 'data.json')
        
        # 初始化数据文件
        initialize_files
      end
      
      # 推送数据到数据集
      # @param data [Hash] 数据
      # @return [Hash] 带有 ID 的数据
      def push_data(data)
        @mutex.synchronize do
          # 读取当前数据
          dataset = read_json_file(@data_file) || []
          
          # 确保所有键都是符号形式的
          symbolized_data = {}
          data.each do |key, value|
            symbolized_data[key.to_sym] = value
          end
          
          # 添加 ID 和时间戳
          data_with_id = symbolized_data
          data_with_id[:id] = SecureRandom.uuid
          data_with_id[:createdAt] = Time.now.to_i
          
          # 添加数据到数据集
          dataset << data_with_id
          write_json_file(@data_file, dataset)
          
          data_with_id
        end
      end
      
      # 获取所有数据
      # @return [Array<Hash>] 数据集中的所有数据
      def get_data
        @mutex.synchronize do
          data = read_json_file(@data_file) || []
          
          # 确保所有数据的键都是符号形式的
          data.map do |item|
            symbolized_item = {}
            item.each do |key, value|
              symbolized_item[key.to_sym] = value
            end
            symbolized_item
          end
        end
      end
      
      # 获取数据集统计信息
      # @return [Hash] 统计信息
      def get_info
        @mutex.synchronize do
          dataset = read_json_file(@data_file) || []
          
          {
            count: dataset.size,
            created_at: File.ctime(@data_file).to_i,
            modified_at: File.mtime(@data_file).to_i
          }
        end
      end
      
      private
      
      # 初始化文件
      def initialize_files
        unless File.exist?(@data_file)
          write_json_file(@data_file, [])
        end
      end
      
      # 读取 JSON 文件
      # @param file [String] 文件路径
      # @return [Array, Hash, nil] 解析后的 JSON 数据
      def read_json_file(file)
        return nil unless File.exist?(file)
        
        begin
          JSON.parse(File.read(file))
        rescue JSON::ParserError => e
          Crawlee.logger.error("JSON 解析错误: #{e.message}")
          nil
        end
      end
      
      # 写入 JSON 文件
      # @param file [String] 文件路径
      # @param data [Array, Hash] 要写入的数据
      def write_json_file(file, data)
        File.write(file, JSON.pretty_generate(data))
      end
    end
    
    # 键值存储类
    class KeyValueStorage
      # 初始化键值存储
      # @param dir [String] 存储目录
      def initialize(dir)
        @dir = dir
        @mutex = Mutex.new
        FileUtils.mkdir_p(@dir)
        @store_file = File.join(@dir, 'store.json')
        
        # 初始化存储文件
        initialize_files
      end
      
      # 获取值
      # @param key [String] 键
      # @return [Object, nil] 值或 nil
      def get(key)
        @mutex.synchronize do
          store = read_json_file(@store_file) || {}
          store[key]
        end
      end
      
      # 设置值
      # @param key [String] 键
      # @param value [Object] 值
      # @return [Object] 值
      def set(key, value)
        @mutex.synchronize do
          store = read_json_file(@store_file) || {}
          store[key] = value
          write_json_file(@store_file, store)
          value
        end
      end
      
      # 删除键
      # @param key [String] 键
      # @return [Boolean] 是否成功删除
      def delete(key)
        @mutex.synchronize do
          store = read_json_file(@store_file) || {}
          return false unless store.key?(key)
          
          store.delete(key)
          write_json_file(@store_file, store)
          true
        end
      end
      
      # 获取所有键值对
      # @return [Hash] 所有键值对
      def get_all
        @mutex.synchronize do
          read_json_file(@store_file) || {}
        end
      end
      
      private
      
      # 初始化文件
      def initialize_files
        unless File.exist?(@store_file)
          write_json_file(@store_file, {})
        end
      end
      
      # 读取 JSON 文件
      # @param file [String] 文件路径
      # @return [Array, Hash, nil] 解析后的 JSON 数据
      def read_json_file(file)
        return nil unless File.exist?(file)
        
        begin
          JSON.parse(File.read(file))
        rescue JSON::ParserError => e
          Crawlee.logger.error("JSON 解析错误: #{e.message}")
          nil
        end
      end
      
      # 写入 JSON 文件
      # @param file [String] 文件路径
      # @param data [Array, Hash] 要写入的数据
      def write_json_file(file, data)
        File.write(file, JSON.pretty_generate(data))
      end
    end
  end
end
