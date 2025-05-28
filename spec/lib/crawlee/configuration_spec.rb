# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Configuration do
  let(:configuration) { Crawlee::Configuration.new }

  describe '初始化' do
    it '使用默认值初始化配置' do
      expect(configuration.max_concurrency).to eq(Crawlee::Configuration::DEFAULT_MAX_CONCURRENCY)
      expect(configuration.request_timeout).to eq(Crawlee::Configuration::DEFAULT_REQUEST_TIMEOUT)
      expect(configuration.max_retries).to eq(Crawlee::Configuration::DEFAULT_MAX_RETRIES)
      expect(configuration.log_level).to eq(Crawlee::Configuration::DEFAULT_LOG_LEVEL)
      expect(configuration.storage_dir).to eq(Crawlee::Configuration::DEFAULT_STORAGE_DIR)
      expect(configuration.default_headers).to eq(Crawlee::Configuration::DEFAULT_HEADERS)
      expect(configuration.proxy_configuration).to be_nil
    end
  end

  describe '#configure_proxy' do
    let(:proxy_urls) { ['http://proxy1.example.com:8080', 'http://proxy2.example.com:8080'] }
    
    it '配置代理服务器' do
      configuration.configure_proxy(proxy_urls, rotation: :round_robin)
      
      expect(configuration.proxy_configuration).to be_a(Hash)
      expect(configuration.proxy_configuration[:urls]).to eq(proxy_urls)
      expect(configuration.proxy_configuration[:rotation]).to eq(:round_robin)
    end
    
    it '使用默认的轮换策略' do
      configuration.configure_proxy(proxy_urls)
      
      expect(configuration.proxy_configuration[:rotation]).to eq(:round_robin)
    end
  end

  describe '#configure_browser' do
    it '配置浏览器选项' do
      configuration.configure_browser(
        browser_type: :firefox,
        headless: false,
        args: ['--window-size=1920,1080']
      )
      
      expect(configuration.instance_variable_get(:@browser_configuration)).to be_a(Hash)
      expect(configuration.instance_variable_get(:@browser_configuration)[:browser_type]).to eq(:firefox)
      expect(configuration.instance_variable_get(:@browser_configuration)[:headless]).to eq(false)
      expect(configuration.instance_variable_get(:@browser_configuration)[:args]).to eq(['--window-size=1920,1080'])
    end
  end
end
