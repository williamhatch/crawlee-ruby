# frozen_string_literal: true

# 配置测试覆盖率报告
require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
]

SimpleCov.start do
  add_filter '/spec/'
  add_group 'Crawlers', 'lib/crawlee/crawlers'
  add_group 'Storage', 'lib/crawlee/storage'
  add_group 'Core', 'lib/crawlee'
  minimum_coverage 80
end

require 'crawlee'
require 'webmock/rspec'

# 禁用外部网络连接，确保测试不会发出实际的 HTTP 请求
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # 启用 RSpec 的期望语法
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # 启用模拟对象的严格语法
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # 共享上下文的元数据继承
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # 随机化测试顺序
  config.order = :random
  Kernel.srand config.seed

  # 在每个测试前清理存储目录
  config.before(:each) do
    storage_dir = File.join(Dir.pwd, 'tmp', 'test_storage')
    FileUtils.rm_rf(storage_dir)
    FileUtils.mkdir_p(storage_dir)
    
    # 配置 Crawlee 使用测试存储目录
    Crawlee.configure do |c|
      c.storage_dir = storage_dir
    end
  end
end

# 测试辅助方法
module TestHelpers
  # 模拟 HTTP 响应
  def mock_http_response(url, status: 200, body: '<html><body>测试页面</body></html>', headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        body: body,
        headers: { 'Content-Type' => 'text/html; charset=utf-8' }.merge(headers)
      )
  end
  
  # 模拟浏览器响应
  # 此方法用于测试浏览器爬虫功能，可以直接创建 BrowserContext 对象而无需实际启动浏览器
  # @param url [String] 请求 URL
  # @param status [Integer] HTTP 状态码
  # @param body [String] 响应体
  # @param headers [Hash] 响应头
  # @return [Crawlee::Crawlers::BrowserContext] 浏览器上下文对象
  def mock_browser_response(url, status: 200, body: '<html><body>测试页面</body></html>', headers: {})
    # 首先使用 WebMock 模拟 HTTP 请求
    mock_http_response(url, status: status, body: body, headers: headers)
    
    # 创建 Nokogiri HTML 文档
    html_doc = Nokogiri::HTML(body)
    
    # 模拟浏览器页面对象
    page = double('Page')
    allow(page).to receive(:goto).with(url).and_return(true)
    allow(page).to receive(:body).and_return(body)
    allow(page).to receive(:content).and_return(body)
    allow(page).to receive(:status).and_return(status)
    allow(page).to receive(:url).and_return(url)
    
    # 允许评估 JavaScript
    allow(page).to receive(:evaluate).and_return(nil)
    allow(page).to receive(:evaluate).with('document.title').and_return(html_doc.at_css('title')&.text || '')
    
    # 模拟网络对象
    network = double('Network')
    allow(network).to receive(:status).and_return(status)
    allow(page).to receive(:network).and_return(network)
    
    # 模拟响应对象
    response = Crawlee::Response.new(
      Crawlee::Request.new(url),
      status,
      headers,
      body,
      url,
      { start_time: Time.now.to_f, end_time: Time.now.to_f, duration: 0 }
    )
    
    # 模拟浏览器爬虫
    crawler = double('BrowserCrawler')
    allow(crawler).to receive(:dataset).and_return(double('Dataset'))
    allow(crawler.dataset).to receive(:push_data).and_return({id: SecureRandom.uuid})
    allow(crawler).to receive(:enqueue).and_return(true)
    allow(crawler).to receive(:enqueue_links).and_return(0)
    allow(crawler).to receive(:save_data) do |data|
      # 模拟保存数据的行为
      data.merge(id: SecureRandom.uuid)
    end
    
    # 创建浏览器上下文
    context = Crawlee::Crawlers::BrowserContext.new(crawler, response.request, response)
    
    # 添加 page 方法到上下文
    context.define_singleton_method(:page) { page }
    
    # 添加 evaluate 方法到上下文
    context.define_singleton_method(:evaluate) do |script|
      page.evaluate(script)
    end
    
    # 返回上下文对象
    context
  end
  
  # 创建带有特定元素的 HTML 页面
  def html_with_elements(title: '测试页面', links: [], images: [])
    html = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <title>#{title}</title>
        </head>
        <body>
          <h1>#{title}</h1>
    HTML
    
    if links.any?
      html += "<div class='links'>\n"
      links.each do |link|
        html += "  <a href='#{link[:url]}'>#{link[:text]}</a>\n"
      end
      html += "</div>\n"
    end
    
    if images.any?
      html += "<div class='images'>\n"
      images.each do |image|
        html += "  <img src='#{image[:src]}' alt='#{image[:alt]}' width='#{image[:width]}' height='#{image[:height]}'>\n"
      end
      html += "</div>\n"
    end
    
    html += "        </body>\n      </html>"
    html
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
