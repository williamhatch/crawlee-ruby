# frozen_string_literal: true

require 'crawlee'

# 创建 HTTP 爬虫
crawler = Crawlee::Crawlers::HttpCrawler.new(
  max_concurrency: 2,  # 设置最大并发请求数
  request_timeout: 30  # 设置请求超时时间（秒）
)

# 微博热搜榜处理器
crawler.router.add(/s\.weibo\.com\/top\/summary/) do |context|
  puts "处理微博热搜榜页面: #{context.request.url}"
  
  # 提取热搜列表
  hot_items = context.query_selector_all('tr.td-02').map do |item|
    # 提取排名
    rank_element = item.at_css('.ranktop')
    rank = rank_element ? rank_element.text.strip : '未知'
    
    # 提取标题
    title_element = item.at_css('a')
    title = title_element ? title_element.text.strip : '未知'
    
    # 提取链接
    link = title_element ? title_element['href'] : nil
    link = "https://s.weibo.com#{link}" if link && link.start_with?('/')
    
    # 提取热度
    hot_element = item.at_css('span')
    hot = hot_element ? hot_element.text.strip : '未知'
    
    # 返回热搜项数据
    {
      rank: rank,
      title: title,
      link: link,
      hot: hot,
      crawled_at: Time.now.to_i
    }
  end
  
  # 保存热搜数据
  hot_items.each do |item|
    context.save_data(item)
    puts "已保存热搜: #{item[:rank]} - #{item[:title]} (#{item[:hot]})"
  end
  
  # 将热搜链接添加到队列
  hot_items.each do |item|
    crawler.enqueue(item[:link]) if item[:link]
  end
end

# 热搜详情页处理器
crawler.router.add(/s\.weibo\.com\/weibo\?q=/) do |context|
  puts "处理热搜详情页面: #{context.request.url}"
  
  # 提取热搜标题
  title = context.query_selector('h2.search-title')&.text&.strip
  
  # 提取微博列表
  weibo_items = context.query_selector_all('.card-wrap').map do |card|
    # 提取用户信息
    user_element = card.at_css('.name')
    user_name = user_element ? user_element.text.strip : '未知'
    user_link = user_element ? user_element['href'] : nil
    user_link = "https://weibo.com#{user_link}" if user_link && user_link.start_with?('/')
    
    # 提取微博内容
    content_element = card.at_css('.txt')
    content = content_element ? content_element.text.strip : '未知'
    
    # 提取发布时间
    time_element = card.at_css('.from a:first-child')
    publish_time = time_element ? time_element.text.strip : '未知'
    
    # 提取互动数据
    forward = card.at_css('.card-act ul li:nth-child(2)')&.text&.strip
    comment = card.at_css('.card-act ul li:nth-child(3)')&.text&.strip
    like = card.at_css('.card-act ul li:nth-child(4)')&.text&.strip
    
    # 返回微博数据
    {
      user_name: user_name,
      user_link: user_link,
      content: content,
      publish_time: publish_time,
      forward: forward,
      comment: comment,
      like: like,
      hot_search: title,
      url: context.request.url,
      crawled_at: Time.now.to_i
    }
  end
  
  # 保存微博数据
  weibo_items.each do |item|
    context.save_data(item)
  end
  
  puts "已保存 #{weibo_items.size} 条微博"
  
  # 查找下一页链接
  next_page = context.query_selector('.next')
  if next_page && next_page['href']
    next_url = next_page['href']
    
    # 确保 URL 是绝对路径
    next_url = "https://s.weibo.com#{next_url}" if next_url.start_with?('/')
    
    # 添加下一页到队列
    crawler.enqueue(next_url)
    puts "已添加下一页: #{next_url}"
  end
end

# 添加起始 URL
crawler.enqueue('https://s.weibo.com/top/summary')

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
hot_searches = all_data.select { |item| item[:rank] }
weibos = all_data.select { |item| item[:content] }

# 保存数据
File.open('weibo_hot_searches.json', 'w') do |file|
  file.write(JSON.pretty_generate(hot_searches))
end

File.open('weibo_posts.json', 'w') do |file|
  file.write(JSON.pretty_generate(weibos))
end

puts "已保存 #{hot_searches.size} 个热搜到 weibo_hot_searches.json"
puts "已保存 #{weibos.size} 条微博到 weibo_posts.json"
