# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 5,  # 设置最大并发请求数
  request_timeout: 30  # 设置请求超时时间（秒）
)

# 文章页面处理器
crawler.router.add(/\/article\//) do |context|
  puts "处理文章页面: #{context.request.url}"
  
  # 提取文章信息
  title = context.query_selector('h1.article-title')&.text&.strip
  author = context.query_selector('.author-name')&.text&.strip
  date = context.query_selector('.publish-date')&.text&.strip
  content = context.query_selector('.article-content')&.text&.strip
  
  # 保存文章数据
  context.save_data({
    url: context.request.url,
    title: title,
    author: author,
    date: date,
    content: content,
    type: 'article'
  })
end

# 列表页面处理器
crawler.router.add(/\/category\//) do |context|
  puts "处理列表页面: #{context.request.url}"
  
  # 提取文章链接
  article_links = context.query_selector_all('a.article-link')
  puts "找到 #{article_links.size} 篇文章"
  
  # 将文章链接添加到队列
  article_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = URI.join(context.request.url, url).to_s if url !~ /^https?:\/\//
    
    # 添加到队列
    crawler.enqueue(url)
  end
  
  # 查找下一页链接
  next_page = context.query_selector('a.next-page')
  if next_page && next_page['href']
    next_url = next_page['href']
    
    # 确保 URL 是绝对路径
    next_url = URI.join(context.request.url, next_url).to_s if next_url !~ /^https?:\/\//
    
    # 添加下一页到队列
    crawler.enqueue(next_url)
  end
end

# 主页处理器
crawler.router.add(/^https?:\/\/news\.example\.com\/?$/) do |context|
  puts "处理主页: #{context.request.url}"
  
  # 提取分类链接
  category_links = context.query_selector_all('a.category-link')
  puts "找到 #{category_links.size} 个分类"
  
  # 将分类链接添加到队列
  category_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = URI.join(context.request.url, url).to_s if url !~ /^https?:\/\//
    
    # 添加到队列
    crawler.enqueue(url)
  end
end

# 默认处理器
crawler.router.default_handler do |context|
  puts "处理其他页面: #{context.request.url}"
  
  # 提取所有链接
  links = context.query_selector_all('a')
  
  # 过滤链接，只保留同一域名的链接
  domain = URI.parse(context.request.url).host
  same_domain_links = links.select do |link|
    href = link['href']
    next false unless href
    
    begin
      href_domain = URI.parse(href).host
      href_domain == domain
    rescue URI::InvalidURIError
      false
    end
  end
  
  # 将过滤后的链接添加到队列
  same_domain_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = URI.join(context.request.url, url).to_s if url !~ /^https?:\/\//
    
    # 添加到队列
    crawler.enqueue(url)
  end
end

# 添加起始 URL
crawler.enqueue('https://news.example.com')

# 运行爬虫
puts "开始运行爬虫..."
stats = crawler.run
puts "爬虫运行完成！"

# 输出统计信息
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"

# 导出数据为 JSON 文件
require 'json'

dataset = crawler.dataset
all_data = dataset.get_data

# 按类型分组
articles = all_data.select { |item| item[:type] == 'article' }

# 保存文章数据
File.open('articles.json', 'w') do |file|
  file.write(JSON.pretty_generate(articles))
end

puts "已将 #{articles.size} 篇文章保存到 articles.json"
