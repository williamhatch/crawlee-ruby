# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 3,  # 设置最大并发请求数
  request_timeout: 30,  # 设置请求超时时间（秒）
  max_retries: 5       # 设置最大重试次数
)

# 产品页面处理器
crawler.router.add(/item\.jd\.com\/\d+\.html/) do |context|
  puts "处理产品页面: #{context.request.url}"
  
  # 提取产品 ID
  product_id = context.request.url.match(/item\.jd\.com\/(\d+)\.html/)[1]
  
  # 提取产品信息
  title = context.query_selector('.sku-name')&.text&.strip
  price_element = context.query_selector('.p-price')
  price = price_element ? price_element.at_css('span')&.text&.strip : nil
  
  # 提取产品详情
  detail_items = context.query_selector_all('.parameter2 li').map { |li| li.text.strip }
  
  # 提取产品图片
  main_image = context.query_selector('#spec-img')&.[]('src')
  main_image = "https:#{main_image}" if main_image && !main_image.start_with?('http')
  
  # 提取产品评分
  score = context.query_selector('.percent-con')&.text&.strip
  
  # 保存产品数据
  context.save_data({
    product_id: product_id,
    url: context.request.url,
    title: title,
    price: price,
    details: detail_items,
    main_image: main_image,
    score: score,
    crawled_at: Time.now.to_i
  })
  
  puts "已保存产品: #{title} (#{product_id})"
end

# 分类页面处理器
crawler.router.add(/list\.jd\.com\/list\.html/) do |context|
  puts "处理分类页面: #{context.request.url}"
  
  # 提取产品链接
  product_links = context.query_selector_all('.gl-item .p-img a')
  puts "找到 #{product_links.size} 个产品链接"
  
  # 将产品链接添加到队列
  product_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = "https:#{url}" if url.start_with?('//')
    url = "https://item.jd.com#{url}" if url.start_with?('/')
    
    # 添加到队列
    crawler.enqueue(url)
  end
  
  # 查找下一页链接
  next_page = context.query_selector('.pn-next')
  if next_page && next_page['href']
    next_url = next_page['href']
    
    # 确保 URL 是绝对路径
    next_url = "https://list.jd.com#{next_url}" if next_url.start_with?('/')
    
    # 添加下一页到队列
    crawler.enqueue(next_url)
    puts "已添加下一页: #{next_url}"
  end
end

# 搜索结果页面处理器
crawler.router.add(/search\.jd\.com/) do |context|
  puts "处理搜索结果页面: #{context.request.url}"
  
  # 提取产品链接
  product_links = context.query_selector_all('.gl-item .p-img a')
  puts "找到 #{product_links.size} 个产品链接"
  
  # 将产品链接添加到队列
  product_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = "https:#{url}" if url.start_with?('//')
    
    # 添加到队列
    crawler.enqueue(url)
  end
  
  # 查找下一页链接
  next_page = context.query_selector('.pn-next')
  if next_page && next_page['href']
    next_url = next_page['href']
    
    # 确保 URL 是绝对路径
    next_url = "https:#{next_url}" if next_url.start_with?('//')
    
    # 添加下一页到队列
    crawler.enqueue(next_url)
    puts "已添加下一页: #{next_url}"
  end
end

# 添加起始 URL（可以是分类页面或搜索结果页面）
crawler.enqueue('https://search.jd.com/Search?keyword=手机&enc=utf-8')

# 运行爬虫
puts "开始运行爬虫..."
stats = crawler.run
puts "爬虫运行完成！"

# 输出统计信息
puts "总请求数: #{stats[:requests_total]}"
puts "成功请求数: #{stats[:requests_successful]}"
puts "失败请求数: #{stats[:requests_failed]}"
puts "重试请求数: #{stats[:requests_retried]}"

# 导出数据为 JSON 文件
require 'json'

dataset = crawler.dataset
all_data = dataset.get_data

File.open('jd_products.json', 'w') do |file|
  file.write(JSON.pretty_generate(all_data))
end

puts "已将 #{all_data.size} 个产品保存到 jd_products.json"
