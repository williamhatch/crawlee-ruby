# frozen_string_literal: true

require 'crawlee'

# 创建浏览器爬虫
crawler = Crawlee::Crawlers::BrowserCrawler.new(
  max_concurrency: 2,  # 设置最大并发请求数
  headless: true,      # 使用无头模式
  launch_options: {
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
)

# 话题页面处理器
crawler.router.add(/www\.zhihu\.com\/topic\/\d+/) do |context|
  puts "处理话题页面: #{context.request.url}"
  
  # 等待页面加载完成
  context.wait_for_selector('.TopicMain')
  
  # 提取话题 ID
  topic_id = context.request.url.match(/topic\/(\d+)/)[1]
  
  # 提取话题信息
  topic_name = context.query_selector('.TopicMetaCard-title')&.text&.strip
  topic_desc = context.query_selector('.TopicMetaCard-description')&.text&.strip
  follower_count = context.query_selector('.TopicMetaCard-followCount')&.text&.strip
  
  # 保存话题数据
  context.save_data({
    topic_id: topic_id,
    url: context.request.url,
    name: topic_name,
    description: topic_desc,
    follower_count: follower_count,
    crawled_at: Time.now.to_i
  })
  
  puts "已保存话题: #{topic_name} (#{topic_id})"
  
  # 滚动页面加载更多内容
  3.times do |i|
    puts "正在滚动页面加载更多内容 (#{i+1}/3)..."
    context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
    sleep 2  # 等待内容加载
  end
  
  # 提取问题链接
  question_links = context.query_selector_all('.ContentItem-title a[data-za-detail-view-element_name="Title"]')
  puts "找到 #{question_links.size} 个问题链接"
  
  # 将问题链接添加到队列
  question_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = "https://www.zhihu.com#{url}" if url.start_with?('/')
    
    # 添加到队列
    crawler.enqueue(url)
  end
  
  # 提取相关话题链接
  related_topic_links = context.query_selector_all('.RelatedTopics-item a')
  puts "找到 #{related_topic_links.size} 个相关话题链接"
  
  # 将相关话题链接添加到队列
  related_topic_links.each do |link|
    url = link['href']
    next unless url
    
    # 确保 URL 是绝对路径
    url = "https://www.zhihu.com#{url}" if url.start_with?('/')
    
    # 添加到队列
    crawler.enqueue(url)
  end
end

# 问题页面处理器
crawler.router.add(/www\.zhihu\.com\/question\/\d+/) do |context|
  puts "处理问题页面: #{context.request.url}"
  
  # 等待页面加载完成
  context.wait_for_selector('.QuestionHeader')
  
  # 提取问题 ID
  question_id = context.request.url.match(/question\/(\d+)/)[1]
  
  # 提取问题信息
  question_title = context.query_selector('.QuestionHeader-title')&.text&.strip
  question_desc = context.query_selector('.QuestionRichText')&.text&.strip
  follower_count = context.query_selector('.NumberBoard-itemValue')&.text&.strip
  
  # 提取问题标签
  tags = context.query_selector_all('.QuestionHeader-topics .Tag').map { |tag| tag.text.strip }
  
  # 保存问题数据
  context.save_data({
    question_id: question_id,
    url: context.request.url,
    title: question_title,
    description: question_desc,
    follower_count: follower_count,
    tags: tags,
    type: 'question',
    crawled_at: Time.now.to_i
  })
  
  puts "已保存问题: #{question_title} (#{question_id})"
  
  # 滚动页面加载更多回答
  3.times do |i|
    puts "正在滚动页面加载更多回答 (#{i+1}/3)..."
    context.evaluate('window.scrollTo(0, document.body.scrollHeight)')
    sleep 2  # 等待内容加载
  end
  
  # 提取回答
  answers = context.query_selector_all('.AnswerItem')
  puts "找到 #{answers.size} 个回答"
  
  # 处理每个回答
  answers.each_with_index do |answer, index|
    # 提取回答 ID
    answer_id = answer['data-zop']
    answer_id = JSON.parse(answer_id)['itemId'] if answer_id
    
    # 提取回答者信息
    author_link = answer.at_css('.AuthorInfo-name a')
    author_name = author_link&.text&.strip
    author_url = author_link&.[]('href')
    author_url = "https://www.zhihu.com#{author_url}" if author_url && author_url.start_with?('/')
    
    # 提取回答内容
    content = answer.at_css('.RichContent-inner')&.text&.strip
    
    # 提取赞同数
    vote_count = answer.at_css('.VoteButton--up')&.text&.strip
    
    # 保存回答数据
    context.save_data({
      answer_id: answer_id,
      question_id: question_id,
      question_url: context.request.url,
      author_name: author_name,
      author_url: author_url,
      content: content,
      vote_count: vote_count,
      type: 'answer',
      crawled_at: Time.now.to_i
    })
    
    puts "已保存回答 #{index+1}: 作者 #{author_name}, 赞同数 #{vote_count}"
  end
end

# 添加起始 URL
crawler.enqueue('https://www.zhihu.com/topic/19550517')  # 互联网话题

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

# 按类型分组
topics = all_data.select { |item| item[:topic_id] }
questions = all_data.select { |item| item[:type] == 'question' }
answers = all_data.select { |item| item[:type] == 'answer' }

# 保存数据
File.open('zhihu_topics.json', 'w') do |file|
  file.write(JSON.pretty_generate(topics))
end

File.open('zhihu_questions.json', 'w') do |file|
  file.write(JSON.pretty_generate(questions))
end

File.open('zhihu_answers.json', 'w') do |file|
  file.write(JSON.pretty_generate(answers))
end

puts "已保存 #{topics.size} 个话题到 zhihu_topics.json"
puts "已保存 #{questions.size} 个问题到 zhihu_questions.json"
puts "已保存 #{answers.size} 个回答到 zhihu_answers.json"
