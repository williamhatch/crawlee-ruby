require_relative 'lib/crawlee/version'

Gem::Specification.new do |spec|
  spec.name          = "crawlee"
  spec.version       = Crawlee::VERSION
  spec.authors       = ["Crawlee Ruby Team"]
  spec.email         = ["example@example.com"]

  spec.summary       = "Ruby 版 Crawlee - 一个强大的网络爬虫和浏览器自动化库"
  spec.description   = "Crawlee Ruby 是一个用于构建可靠爬虫的库。它处理网站封锁、代理轮换和浏览器自动化等问题，使您能够轻松地从网站提取数据。"
  spec.homepage      = "https://github.com/example/crawlee-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/example/crawlee-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/example/crawlee-ruby/blob/main/CHANGELOG.md"

  # 核心依赖
  spec.add_dependency "nokogiri", "~> 1.14"  # HTML 解析
  spec.add_dependency "httparty", "~> 0.21"  # HTTP 客户端
  spec.add_dependency "ferrum", "~> 0.13"    # 无头浏览器控制 (Chrome)
  spec.add_dependency "concurrent-ruby", "~> 1.2"  # 并发支持
  spec.add_dependency "addressable", "~> 2.8"  # URL 处理
  spec.add_dependency "faker", "~> 3.2"  # 生成随机数据，用于指纹生成
  
  # 指定哪些文件包含在 gem 中
  spec.files = Dir.glob("lib/**/*") + %w[LICENSE.txt README.md]
  spec.require_paths = ["lib"]
end
