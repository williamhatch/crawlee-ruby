# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Response do
  let(:request) { Crawlee::Request.new('https://example.com') }
  let(:headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }
  let(:body) { '<html><head><title>测试页面</title></head><body><h1>Hello</h1></body></html>' }
  
  describe '初始化' do
    it '创建一个响应对象' do
      response = Crawlee::Response.new(request, 200, headers, body)
      
      expect(response.request).to eq(request)
      expect(response.status_code).to eq(200)
      expect(response.headers).to eq(headers)
      expect(response.body).to eq(body)
      expect(response.url).to eq(request.url)
      expect(response.timing).to eq({})
    end
    
    it '使用提供的 URL 和计时信息' do
      timing = { start_time: 1.0, end_time: 2.0, duration: 1000 }
      response = Crawlee::Response.new(request, 200, headers, body, 'https://example.com/redirected', timing)
      
      expect(response.url).to eq('https://example.com/redirected')
      expect(response.timing).to eq(timing)
    end
  end
  
  describe '状态检查方法' do
    it '#success? 在状态码为 2xx 时返回 true' do
      expect(Crawlee::Response.new(request, 200, headers, body).success?).to be true
      expect(Crawlee::Response.new(request, 201, headers, body).success?).to be true
      expect(Crawlee::Response.new(request, 299, headers, body).success?).to be true
      expect(Crawlee::Response.new(request, 300, headers, body).success?).to be false
      expect(Crawlee::Response.new(request, 404, headers, body).success?).to be false
      expect(Crawlee::Response.new(request, 500, headers, body).success?).to be false
    end
    
    it '#redirect? 在状态码为 3xx 时返回 true' do
      expect(Crawlee::Response.new(request, 200, headers, body).redirect?).to be false
      expect(Crawlee::Response.new(request, 300, headers, body).redirect?).to be true
      expect(Crawlee::Response.new(request, 301, headers, body).redirect?).to be true
      expect(Crawlee::Response.new(request, 302, headers, body).redirect?).to be true
      expect(Crawlee::Response.new(request, 399, headers, body).redirect?).to be true
      expect(Crawlee::Response.new(request, 400, headers, body).redirect?).to be false
    end
    
    it '#client_error? 在状态码为 4xx 时返回 true' do
      expect(Crawlee::Response.new(request, 200, headers, body).client_error?).to be false
      expect(Crawlee::Response.new(request, 399, headers, body).client_error?).to be false
      expect(Crawlee::Response.new(request, 400, headers, body).client_error?).to be true
      expect(Crawlee::Response.new(request, 404, headers, body).client_error?).to be true
      expect(Crawlee::Response.new(request, 499, headers, body).client_error?).to be true
      expect(Crawlee::Response.new(request, 500, headers, body).client_error?).to be false
    end
    
    it '#server_error? 在状态码为 5xx 时返回 true' do
      expect(Crawlee::Response.new(request, 200, headers, body).server_error?).to be false
      expect(Crawlee::Response.new(request, 499, headers, body).server_error?).to be false
      expect(Crawlee::Response.new(request, 500, headers, body).server_error?).to be true
      expect(Crawlee::Response.new(request, 503, headers, body).server_error?).to be true
      expect(Crawlee::Response.new(request, 599, headers, body).server_error?).to be true
    end
  end
  
  describe '#content_type' do
    it '返回内容类型' do
      response = Crawlee::Response.new(request, 200, { 'Content-Type' => 'text/html; charset=utf-8' }, body)
      expect(response.content_type).to eq('text/html')
    end
    
    it '当没有内容类型头时返回 nil' do
      response = Crawlee::Response.new(request, 200, {}, body)
      expect(response.content_type).to be_nil
    end
    
    it '支持小写的内容类型头' do
      response = Crawlee::Response.new(request, 200, { 'content-type' => 'application/json; charset=utf-8' }, body)
      expect(response.content_type).to eq('application/json')
    end
  end
  
  describe '内容类型检查方法' do
    it '#html? 在内容类型为 HTML 时返回 true' do
      html_response = Crawlee::Response.new(request, 200, { 'Content-Type' => 'text/html; charset=utf-8' }, body)
      json_response = Crawlee::Response.new(request, 200, { 'Content-Type' => 'application/json' }, '{}')
      no_type_response = Crawlee::Response.new(request, 200, {}, body)
      
      expect(html_response.html?).to be true
      expect(json_response.html?).to be false
      expect(no_type_response.html?).to be false
    end
    
    it '#json? 在内容类型为 JSON 时返回 true' do
      html_response = Crawlee::Response.new(request, 200, { 'Content-Type' => 'text/html; charset=utf-8' }, body)
      json_response = Crawlee::Response.new(request, 200, { 'Content-Type' => 'application/json' }, '{}')
      no_type_response = Crawlee::Response.new(request, 200, {}, body)
      
      expect(html_response.json?).to be false
      expect(json_response.json?).to be true
      expect(no_type_response.json?).to be false
    end
  end
  
  describe '#html' do
    it '将响应体解析为 HTML 文档' do
      response = Crawlee::Response.new(request, 200, headers, body)
      html_doc = response.html
      
      expect(html_doc).to be_a(Nokogiri::HTML::Document)
      expect(html_doc.at_css('title').text).to eq('测试页面')
      expect(html_doc.at_css('h1').text).to eq('Hello')
    end
    
    it '缓存解析结果' do
      response = Crawlee::Response.new(request, 200, headers, body)
      
      # 第一次调用解析 HTML
      first_call = response.html
      
      # 修改响应体，但不应该影响已缓存的结果
      response.instance_variable_set(:@body, '<html><head><title>Changed</title></head><body></body></html>')
      
      # 第二次调用应该返回缓存的结果
      second_call = response.html
      
      expect(first_call).to be(second_call)
      expect(second_call.at_css('title').text).to eq('测试页面')
    end
  end
  
  describe '#json' do
    let(:json_body) { '{"name":"测试","value":123}' }
    let(:json_headers) { { 'Content-Type' => 'application/json' } }
    
    it '将响应体解析为 JSON 对象' do
      response = Crawlee::Response.new(request, 200, json_headers, json_body)
      json_obj = response.json
      
      expect(json_obj).to be_a(Hash)
      expect(json_obj['name']).to eq('测试')
      expect(json_obj['value']).to eq(123)
    end
    
    it '缓存解析结果' do
      response = Crawlee::Response.new(request, 200, json_headers, json_body)
      
      # 第一次调用解析 JSON
      first_call = response.json
      
      # 修改响应体，但不应该影响已缓存的结果
      response.instance_variable_set(:@body, '{"name":"Changed","value":456}')
      
      # 第二次调用应该返回缓存的结果
      second_call = response.json
      
      expect(first_call).to be(second_call)
      expect(second_call['name']).to eq('测试')
      expect(second_call['value']).to eq(123)
    end
    
    it '在 JSON 解析失败时抛出异常' do
      response = Crawlee::Response.new(request, 200, json_headers, 'Invalid JSON')
      
      expect { response.json }.to raise_error(JSON::ParserError)
    end
  end
  
  describe '#to_h' do
    it '将响应转换为哈希' do
      timing = { start_time: 1.0, end_time: 2.0, duration: 1000 }
      response = Crawlee::Response.new(request, 200, headers, body, 'https://example.com/redirected', timing)
      
      hash = response.to_h
      
      expect(hash[:request]).to eq(request.to_h)
      expect(hash[:status_code]).to eq(200)
      expect(hash[:headers]).to eq(headers)
      expect(hash[:body_size]).to eq(body.bytesize)
      expect(hash[:url]).to eq('https://example.com/redirected')
      expect(hash[:timing]).to eq(timing)
    end
  end
end
