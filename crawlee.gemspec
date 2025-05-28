require_relative 'lib/crawlee/version'

Gem::Specification.new do |spec|
  spec.name          = "crawlee"
  spec.version       = Crawlee::VERSION
  spec.authors       = ["Crawlee Ruby Team"]
  spec.email         = ["example@example.com"]

  spec.summary       = "Crawlee for Ruby - A powerful web scraping and browser automation library"
  spec.description   = "Crawlee Ruby is a library for building reliable web crawlers. It handles website blocking, proxy rotation, and browser automation, making it easy to extract data from websites."
  spec.homepage      = "https://github.com/williamhatch/crawlee-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/williamhatch/crawlee-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/williamhatch/crawlee-ruby/blob/main/CHANGELOG.md"

  # Core dependencies
  spec.add_dependency "nokogiri", "~> 1.14"  # HTML parsing
  spec.add_dependency "httparty", "~> 0.21"  # HTTP client
  spec.add_dependency "ferrum", "~> 0.13"    # Headless browser control (Chrome)
  spec.add_dependency "concurrent-ruby", "~> 1.2"  # Concurrency support
  spec.add_dependency "addressable", "~> 2.8"  # URL handling
  spec.add_dependency "faker", "~> 3.2"  # Generate random data for fingerprinting
  
  # Specify which files are included in the gem
  spec.files = Dir.glob("lib/**/*") + %w[LICENSE.txt README.md]
  spec.require_paths = ["lib"]
end
