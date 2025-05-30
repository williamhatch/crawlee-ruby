# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Crawlers::HttpContext do
  let(:crawler) { Crawlee::Crawlers::HttpCrawler.new }
  let(:request) { Crawlee::Request.new('https://example.com') }
  let(:response) do
    Crawlee::Response.new(
      request,
      200,
      { 'Content-Type' => 'text/html; charset=UTF-8' },
      '<html><head><title>测试页面</title></head><body><a href="/page1">链接1</a><a href="/page2">链接2</a></body></html>',
      'https://example.com',
      {}
    )
  end
  let(:context) { Crawlee::Crawlers::HttpContext.new(crawler, request, response) }
  
  describe '#initialize' do
    it '创建一个 HTTP 上下文实例' do
      expect(context).to be_a(Crawlee::Crawlers::HttpContext)
    end
    
    it '设置爬虫、请求和响应' do
      expect(context.crawler).to eq(crawler)
      expect(context.request).to eq(request)
      expect(context.response).to eq(response)
    end
  end
  
  describe '#query_selector' do
    it '查询单个元素' do
      title = context.query_selector('title')
      expect(title).not_to be_nil
      expect(title.text).to eq('测试页面')
    end
    
    it '当元素不存在时返回 nil' do
      element = context.query_selector('h1')
      expect(element).to be_nil
    end
  end
  
  describe '#query_selector_all' do
    it '查询多个元素' do
      links = context.query_selector_all('a')
      expect(links.size).to eq(2)
      expect(links.first.text).to eq('链接1')
      expect(links.last.text).to eq('链接2')
    end
    
    it '当元素不存在时返回空数组' do
      elements = context.query_selector_all('h1')
      expect(elements).to be_empty
    end
  end
  
  describe '#save_data' do
    it '保存数据到数据集' do
      data = { title: '测试标题', url: 'https://example.com' }
      
      expect(crawler.dataset).to receive(:push_data).with(data).and_return(data.merge(id: '123'))
      
      result = context.save_data(data)
      expect(result).to include(:id)
      expect(result[:title]).to eq('测试标题')
    end
  end
  
  describe '#enqueue' do
    it '将 URL 添加到请求队列' do
      url = 'https://example.com/page1'
      
      expect(crawler).to receive(:enqueue).with(url, {})
      
      context.enqueue(url)
    end
    
    it '将请求对象添加到请求队列' do
      new_request = Crawlee::Request.new('https://example.com/page1')
      
      expect(crawler).to receive(:enqueue).with(new_request, {})
      
      context.enqueue(new_request)
    end
    
    it '使用自定义选项将 URL 添加到请求队列' do
      url = 'https://example.com/page1'
      options = { method: :post, headers: { 'X-Test' => 'test' } }
      
      expect(crawler).to receive(:enqueue).with(url, options)
      
      context.enqueue(url, options)
    end
  end
  
  describe '#enqueue_links' do
    it '提取链接并添加到请求队列' do
      expect(crawler).to receive(:enqueue).with('https://example.com/page1', {}).and_return(true)
      expect(crawler).to receive(:enqueue).with('https://example.com/page2', {}).and_return(true)
      
      count = context.enqueue_links('a')
      expect(count).to eq(2)
    end
    
    it '使用自定义选项提取链接并添加到请求队列' do
      options = { method: :post, headers: { 'X-Test' => 'test' } }
      
      expect(crawler).to receive(:enqueue).with('https://example.com/page1', options).and_return(true)
      expect(crawler).to receive(:enqueue).with('https://example.com/page2', options).and_return(true)
      
      count = context.enqueue_links('a', options)
      expect(count).to eq(2)
    end
    
    it '使用自定义选择器提取链接' do
      expect(crawler).to receive(:enqueue).with('https://example.com/page1', {}).and_return(true)
      
      count = context.enqueue_links('a[href="/page1"]')
      expect(count).to eq(1)
    end
    
    it '当没有匹配的链接时返回 0' do
      count = context.enqueue_links('a[href="/page3"]')
      expect(count).to eq(0)
    end
    
    it '正确处理相对 URL' do
      expect(crawler).to receive(:enqueue).with('https://example.com/page1', {}).and_return(true)
      expect(crawler).to receive(:enqueue).with('https://example.com/page2', {}).and_return(true)
      
      count = context.enqueue_links('a')
      expect(count).to eq(2)
    end
    
    it '正确处理带有单引号或双引号的 URL' do
      # 使用位置参数而不是命名参数来创建 Response 对象
      response_with_quotes = Crawlee::Response.new(
        request, 
        200,
        { 'Content-Type' => 'text/html; charset=UTF-8' },
        '<html><body><a href="/page1">链接1</a><a href=\'page2\'>链接2</a></body></html>'
      )
      context_with_quotes = Crawlee::Crawlers::HttpContext.new(crawler, request, response_with_quotes)
      
      expect(crawler).to receive(:enqueue).with('https://example.com/page1', {}).and_return(true)
      expect(crawler).to receive(:enqueue).with('https://example.com/page2', {}).and_return(true)
      
      count = context_with_quotes.enqueue_links('a')
      expect(count).to eq(2)
    end
  end
end

RSpec.describe Crawlee::Crawlers::BrowserContext do
  let(:crawler) { double('BrowserCrawler') }
  let(:request) { Crawlee::Request.new('https://example.com') }
  let(:response) { double('Response', request: request) }
  let(:page) { double('Page') }
  let(:context) { Crawlee::Crawlers::BrowserContext.new(crawler, request, response, page) }
  
  describe '#initialize' do
    it '创建一个浏览器上下文实例' do
      expect(context).to be_a(Crawlee::Crawlers::BrowserContext)
    end
    
    it '设置爬虫、请求、响应和页面' do
      expect(context.crawler).to eq(crawler)
      expect(context.request).to eq(request)
      expect(context.response).to eq(response)
      expect(context.page).to eq(page)
    end
  end
  
  describe '#query_selector' do
    it '查询单个元素' do
      element = double('Element')
      expect(page).to receive(:query_selector).with('title').and_return(element)
      
      result = context.query_selector('title')
      expect(result).to eq(element)
    end
    
    it '当元素不存在时返回 nil' do
      expect(page).to receive(:query_selector).with('h1').and_return(nil)
      
      result = context.query_selector('h1')
      expect(result).to be_nil
    end
  end
  
  describe '#query_selector_all' do
    it '查询多个元素' do
      elements = [double('Element1'), double('Element2')]
      expect(page).to receive(:query_selector_all).with('a').and_return(elements)
      
      result = context.query_selector_all('a')
      expect(result).to eq(elements)
    end
    
    it '当元素不存在时返回空数组' do
      expect(page).to receive(:query_selector_all).with('h1').and_return([])
      
      result = context.query_selector_all('h1')
      expect(result).to be_empty
    end
  end
  
  describe '#evaluate' do
    it '在页面上下文中执行 JavaScript' do
      expect(page).to receive(:evaluate).with('document.title').and_return('测试页面')
      
      result = context.evaluate('document.title')
      expect(result).to eq('测试页面')
    end
  end
  
  describe '#wait_for_selector' do
    it '等待选择器匹配的元素出现' do
      element = double('Element')
      expect(page).to receive(:wait_for_selector).with('title', {}).and_return(element)
      
      result = context.wait_for_selector('title')
      expect(result).to eq(element)
    end
    
    it '使用自定义选项等待选择器匹配的元素出现' do
      element = double('Element')
      options = { timeout: 5000, visible: true }
      expect(page).to receive(:wait_for_selector).with('title', options).and_return(element)
      
      result = context.wait_for_selector('title', options)
      expect(result).to eq(element)
    end
  end
  
  describe '#click' do
    it '点击页面中的元素' do
      expect(page).to receive(:click).with('button', {})
      
      context.click('button')
    end
    
    it '使用自定义选项点击页面中的元素' do
      options = { button: :right, click_count: 2 }
      expect(page).to receive(:click).with('button', options)
      
      context.click('button', options)
    end
  end
  
  describe '#type' do
    it '在页面中的输入框中输入文本' do
      expect(page).to receive(:type).with('#input', 'test', {})
      
      context.type('#input', 'test')
    end
    
    it '使用自定义选项在页面中的输入框中输入文本' do
      options = { delay: 100 }
      expect(page).to receive(:type).with('#input', 'test', options)
      
      context.type('#input', 'test', options)
    end
  end
  
  describe '#screenshot' do
    it '截取页面截图' do
      buffer = double('Buffer')
      expect(page).to receive(:screenshot).with({}).and_return(buffer)
      
      result = context.screenshot
      expect(result).to eq(buffer)
    end
    
    it '使用自定义选项截取页面截图' do
      buffer = double('Buffer')
      options = { path: 'screenshot.png', full_page: true }
      expect(page).to receive(:screenshot).with(options).and_return(buffer)
      
      result = context.screenshot(options)
      expect(result).to eq(buffer)
    end
  end
end
