# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::SessionPool do
  let(:session_pool) { Crawlee::SessionPool.new(5) }
  let(:domain) { 'example.com' }
  
  describe '初始化' do
    it '使用指定的大小创建会话池' do
      pool = Crawlee::SessionPool.new(10)
      expect(pool.instance_variable_get(:@size)).to eq(10)
    end
    
    it '使用配置的默认大小创建会话池' do
      allow(Crawlee.configuration).to receive(:session_pool_size).and_return(20)
      pool = Crawlee::SessionPool.new
      expect(pool.instance_variable_get(:@size)).to eq(20)
    end
    
    it '默认启用 Cookie 持久化' do
      pool = Crawlee::SessionPool.new
      expect(pool.instance_variable_get(:@persist_cookies)).to be true
    end
    
    it '可以禁用 Cookie 持久化' do
      pool = Crawlee::SessionPool.new(5, persist_cookies: false)
      expect(pool.instance_variable_get(:@persist_cookies)).to be false
    end
  end
  
  describe '#get_session' do
    it '为新域名创建会话' do
      session = session_pool.get_session(domain)
      
      expect(session).to be_a(Hash)
      expect(session[:domain]).to eq(domain)
      expect(session[:cookies]).to eq([])
      expect(session[:id]).not_to be_nil
      expect(session[:created_at]).not_to be_nil
    end
    
    it '返回已存在域名的会话' do
      # 第一次调用创建会话
      first_session = session_pool.get_session(domain)
      
      # 第二次调用应该返回相同的会话
      second_session = session_pool.get_session(domain)
      
      expect(second_session).to be(first_session)
      expect(second_session[:id]).to eq(first_session[:id])
    end
    
    it '更新会话使用计数' do
      session_pool.get_session(domain)
      expect(session_pool.instance_variable_get(:@session_usage)[domain]).to eq(1)
      
      session_pool.get_session(domain)
      expect(session_pool.instance_variable_get(:@session_usage)[domain]).to eq(2)
    end
  end
  
  describe '#update_cookies' do
    let(:cookies) do
      [
        { name: 'session_id', value: '12345', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false },
        { name: 'user_id', value: 'user123', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false }
      ]
    end
    
    it '添加新的 Cookie 到会话' do
      session = session_pool.get_session(domain)
      expect(session[:cookies]).to be_empty
      
      session_pool.update_cookies(domain, cookies)
      
      expect(session[:cookies].size).to eq(2)
      expect(session[:cookies][0][:name]).to eq('session_id')
      expect(session[:cookies][0][:value]).to eq('12345')
      expect(session[:cookies][1][:name]).to eq('user_id')
      expect(session[:cookies][1][:value]).to eq('user123')
    end
    
    it '更新已存在的 Cookie' do
      # 添加初始 Cookie
      session_pool.update_cookies(domain, cookies)
      
      # 更新一个 Cookie
      updated_cookie = { name: 'session_id', value: 'updated', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false }
      session_pool.update_cookies(domain, [updated_cookie])
      
      session = session_pool.get_session(domain)
      expect(session[:cookies].size).to eq(2)
      
      # 找到 session_id Cookie
      session_cookie = session[:cookies].find { |c| c[:name] == 'session_id' }
      expect(session_cookie[:value]).to eq('updated')
      
      # user_id Cookie 应该保持不变
      user_cookie = session[:cookies].find { |c| c[:name] == 'user_id' }
      expect(user_cookie[:value]).to eq('user123')
    end
  end
  
  describe '#cookie_string' do
    it '返回空字符串，当没有 Cookie 时' do
      expect(session_pool.cookie_string(domain)).to eq('')
    end
    
    it '返回格式化的 Cookie 字符串' do
      cookies = [
        { name: 'session_id', value: '12345', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false },
        { name: 'user_id', value: 'user123', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false }
      ]
      
      session_pool.update_cookies(domain, cookies)
      
      expect(session_pool.cookie_string(domain)).to eq('session_id=12345; user_id=user123')
    end
    
    it '排除过期的 Cookie' do
      cookies = [
        { name: 'valid', value: 'yes', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: false },
        { name: 'expired', value: 'no', domain: domain, path: '/', expires: nil, httponly: false, secure: false, expired: true }
      ]
      
      session_pool.update_cookies(domain, cookies)
      
      expect(session_pool.cookie_string(domain)).to eq('valid=yes')
    end
  end
  
  describe '#clear' do
    before do
      # 添加多个域名的会话
      session_pool.get_session('example.com')
      session_pool.get_session('test.com')
    end
    
    it '清除指定域名的会话' do
      expect(session_pool.instance_variable_get(:@sessions).size).to eq(2)
      
      session_pool.clear('example.com')
      
      expect(session_pool.instance_variable_get(:@sessions).size).to eq(1)
      expect(session_pool.instance_variable_get(:@sessions)['example.com']).to be_nil
      expect(session_pool.instance_variable_get(:@sessions)['test.com']).not_to be_nil
    end
    
    it '清除所有会话' do
      expect(session_pool.instance_variable_get(:@sessions).size).to eq(2)
      
      session_pool.clear
      
      expect(session_pool.instance_variable_get(:@sessions).size).to eq(0)
    end
  end
  
  describe '#stats' do
    before do
      # 添加多个域名的会话并模拟使用次数
      session_pool.get_session('example.com')
      session_pool.get_session('example.com')
      session_pool.get_session('test.com')
    end
    
    it '返回会话池的统计信息' do
      stats = session_pool.stats
      
      expect(stats[:size]).to eq(2)
      expect(stats[:domains]).to contain_exactly('example.com', 'test.com')
      expect(stats[:usage]['example.com']).to eq(2)
      expect(stats[:usage]['test.com']).to eq(1)
    end
  end
end
