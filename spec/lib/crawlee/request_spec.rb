# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Request do
  describe '初始化' do
    it '创建一个带有默认值的请求对象' do
      request = Crawlee::Request.new('https://example.com')
      
      expect(request.id).not_to be_nil
      expect(request.url).to eq('https://example.com')
      expect(request.method).to eq(:get)
      expect(request.headers).to eq(Crawlee.configuration.default_headers)
      expect(request.payload).to be_nil
      expect(request.metadata).to eq({})
      expect(request.retry_count).to eq(0)
    end
    
    it '使用提供的值创建请求对象' do
      headers = { 'User-Agent' => 'Custom Agent' }
      payload = { 'key' => 'value' }
      metadata = { 'category' => 'test' }
      
      request = Crawlee::Request.new(
        'https://example.com',
        method: :post,
        headers: headers,
        payload: payload,
        metadata: metadata
      )
      
      expect(request.url).to eq('https://example.com')
      expect(request.method).to eq(:post)
      expect(request.headers['User-Agent']).to eq('Custom Agent')
      expect(request.payload).to eq(payload)
      expect(request.metadata).to eq(metadata)
    end
    
    it '规范化 URL' do
      request = Crawlee::Request.new('example.com')
      
      expect(request.url).to eq('http://example.com')
    end
    
    it '验证 HTTP 方法' do
      expect {
        Crawlee::Request.new('https://example.com', method: :invalid)
      }.to raise_error(ArgumentError, /不支持的 HTTP 方法/)
    end
  end
  
  describe '#domain' do
    it '返回请求的域名' do
      request = Crawlee::Request.new('https://example.com/path')
      
      expect(request.domain).to eq('example.com')
    end
  end
  
  describe '#path' do
    it '返回请求的路径' do
      request = Crawlee::Request.new('https://example.com/path/to/resource')
      
      expect(request.path).to eq('/path/to/resource')
    end
  end
  
  describe '#query_params' do
    it '返回请求的查询参数' do
      request = Crawlee::Request.new('https://example.com/search?q=test&page=1')
      
      expect(request.query_params).to eq({ 'q' => 'test', 'page' => '1' })
    end
    
    it '当没有查询参数时返回空哈希' do
      request = Crawlee::Request.new('https://example.com/path')
      
      expect(request.query_params).to eq({})
    end
  end
  
  describe '#clone' do
    it '创建请求的副本' do
      original = Crawlee::Request.new(
        'https://example.com',
        method: :post,
        headers: { 'Custom' => 'Header' },
        payload: { 'key' => 'value' },
        metadata: { 'category' => 'test' }
      )
      
      clone = original.clone
      
      expect(clone.url).to eq(original.url)
      expect(clone.method).to eq(original.method)
      expect(clone.headers).to eq(original.headers)
      expect(clone.payload).to eq(original.payload)
      expect(clone.metadata).to eq(original.metadata)
      expect(clone.id).not_to eq(original.id)
    end
  end
  
  describe '#to_h' do
    it '将请求转换为哈希' do
      request = Crawlee::Request.new(
        'https://example.com',
        method: :post,
        headers: { 'Custom' => 'Header' },
        payload: { 'key' => 'value' },
        metadata: { 'category' => 'test' }
      )
      request.retry_count = 2
      
      hash = request.to_h
      
      expect(hash[:id]).to eq(request.id)
      expect(hash[:url]).to eq('https://example.com')
      expect(hash[:method]).to eq(:post)
      expect(hash[:headers]).to eq({ 'Custom' => 'Header' })
      expect(hash[:payload]).to eq({ 'key' => 'value' })
      expect(hash[:metadata]).to eq({ 'category' => 'test' })
      expect(hash[:retry_count]).to eq(2)
    end
  end
end
