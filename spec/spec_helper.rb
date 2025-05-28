# frozen_string_literal: true

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
  # 创建模拟 HTTP 响应
  def mock_http_response(url, status: 200, body: '<html><body>测试页面</body></html>', headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        body: body,
        headers: { 'Content-Type' => 'text/html; charset=utf-8' }.merge(headers)
      )
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
