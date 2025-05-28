# frozen_string_literal: true

module Crawlee
  module FixEncoding
    # 修复 JSON 文件读取的编码问题
    def self.patch_storage_classes
      # 定义通用的 read_json_file 方法
      def self.improved_read_json_file(file)
        return nil unless File.exist?(file)
        
        # 检查文件是否为空
        return nil if File.size(file) == 0
        
        begin
          # 指定 UTF-8 编码读取文件
          content = File.read(file, encoding: 'UTF-8')
          
          # 检查内容是否为空或仅包含空白字符
          return nil if content.strip.empty?
          
          # 检查是否是有效的 JSON
          if content.strip.start_with?('{') || content.strip.start_with?('[')
            JSON.parse(content)
          else
            Crawlee.logger.debug("文件内容不是有效的 JSON格式: #{file}")
            nil
          end
        rescue JSON::ParserError => e
          # 只在调试模式下记录解析错误
          Crawlee.logger.debug("JSON 解析错误: #{e.message} (文件: #{file})")
          nil
        rescue Encoding::InvalidByteSequenceError => e
          Crawlee.logger.debug("编码错误: #{e.message} (文件: #{file})")
          nil
        rescue => e
          Crawlee.logger.debug("读取文件错误: #{e.message} (文件: #{file})")
          nil
        end
      end
      
      # 修复 RequestQueueStorage 类的 read_json_file 方法
      Storage::RequestQueueStorage.class_eval do
        def read_json_file(file)
          Crawlee::FixEncoding.improved_read_json_file(file)
        end
      end
      
      # 修复 DatasetStorage 类的 read_json_file 方法
      Storage::DatasetStorage.class_eval do
        def read_json_file(file)
          Crawlee::FixEncoding.improved_read_json_file(file)
        end
      end
      
      # 修复 KeyValueStorage 类的 read_json_file 方法
      Storage::KeyValueStorage.class_eval do
        def read_json_file(file)
          Crawlee::FixEncoding.improved_read_json_file(file)
        end
      end
    end
  end
end

# 应用补丁
Crawlee::FixEncoding.patch_storage_classes
