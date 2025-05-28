<h1 align="center">
    <img alt="Crawlee Ruby" src="https://via.placeholder.com/500x100?text=Crawlee+Ruby" width="500">
    <br>
    <small>Web Scraping and Browser Automation Library for Ruby</small>
</h1>

## Acknowledgements

This project is inspired by the JavaScript and Python versions provided by the [Crawlee](https://crawlee.dev) community, developed as a Ruby implementation out of interest. Special thanks to the developers of the Crawlee community for providing such an excellent web scraping framework, which has provided valuable design ideas and references for this project.

Official Crawlee versions:
- [Crawlee JavaScript](https://github.com/apify/crawlee) - Original JavaScript implementation
- [Crawlee Python](https://github.com/apify/crawlee-python) - Python implementation

<p align=center>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/gem/v/crawlee.svg" alt="Gem Version">
    </a>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/gem/dt/crawlee.svg" alt="Gem Downloads">
    </a>
    <a href="https://rubygems.org/gems/crawlee">
        <img src="https://img.shields.io/badge/ruby-%3E%3D%203.0.0-ruby.svg" alt="Ruby Version">
    </a>
</p>

Crawlee Ruby is a comprehensive web scraping and data extraction framework that helps you build reliable crawlers. Fast and efficient.

> 🚀 Crawlee Ruby is the Ruby implementation of the Crawlee ecosystem!

Even with the default configuration, your crawlers can behave almost like human behavior, easily bypassing modern website anti-scraping protections. Crawlee Ruby provides you with tools to crawl web links, extract data, and persistently store it in machine-readable formats, without worrying about technical details. Through rich configuration options, you can adjust almost any aspect of Crawlee Ruby according to your project needs.

## Architecture Diagram

```
+---------------------+      +---------------------+
|   Application Layer |      |  Tools & Extensions |
|  (User Crawler Scripts)    |                     |
+----------+----------+      | +---------------+   |
           |                 | | Fingerprint Gen|   |
           v                 | +---------------+   |
+---------------------+      |                     |
|    Crawler Layer    |<---->| +---------------+   |
|                     |      | | Proxy Manager |   |
| +---------------+   |      | +---------------+   |
| | HttpCrawler   |   |      |                     |
| +---------------+   |      | +---------------+   |
|                     |      | | Browser Manager|  |
| +---------------+   |      | +---------------+   |
| | BrowserCrawler|   |      +---------------------+
| +---------------+   |                ^
|                     |                |
| +---------------+   |                v
| | AdaptiveCrawler|  |      +---------------------+
| +---------------+   |      |  Middleware System  |
+----------+----------+      |                     |
           |                 | +---------------+   |
           v                 | | Request Middleware|
+---------------------+      | +---------------+   |
|     Core Layer      |<---->|                     |
|                     |      | +---------------+   |
| +---------------+   |      | | Response Middleware|
| | Request/Response |      | +---------------+   |
| +---------------+   |      |                     |
|                     |      | +---------------+   |
| +---------------+   |      | | Error Middleware ||
| | Session Mgmt  |   |      | +---------------+   |
| +---------------+   |      +---------------------+
|                     |                ^
| +---------------+   |                |
| | Routing System|   |                v
| +---------------+   |      +---------------------+
+----------+----------+      |  Monitoring & Logs  |
           |                 |                     |
           v                 | +---------------+   |
+---------------------+      | | Performance   |   |
|    Storage Layer    |<---->| +---------------+   |
|                     |      |                     |
| +---------------+   |      | +---------------+   |
| | Request Queue |   |      | | Logging System|   |
| +---------------+   |      | +---------------+   |
|                     |      |                     |
| +---------------+   |      | +---------------+   |
| | Dataset       |   |      | | Statistics    |   |
| +---------------+   |      | +---------------+   |
|                     |      +---------------------+
| +---------------+   |
| | Key-Value Store|  |
| +---------------+   |
+---------------------+
```

## Installation

We recommend visiting the Getting Started tutorial in the Crawlee Ruby documentation for more information.

Crawlee Ruby can be installed via RubyGems, with the package name `crawlee`. This package includes core functionality, while additional features can be installed as optional dependencies to keep dependencies and package size minimal.

To install Crawlee Ruby and all its features, run the following command:

```sh
gem install crawlee
```

Or add to your Gemfile:

```ruby
gem 'crawlee'
```

Then run:

```sh
bundle install
```

## Testing

Crawlee Ruby uses RSpec for testing. To run the tests, follow these steps:

1. Install development dependencies:

```sh
bundle install
```

2. Run the tests:

```sh
bundle exec rspec
```

You can run specific test files:

```sh
bundle exec rspec spec/lib/crawlee/configuration_spec.rb
```

Or run specific test cases:

```sh
bundle exec rspec spec/lib/crawlee/request_spec.rb:10
```

Verify that Crawlee Ruby is successfully installed:

```sh
ruby -e 'require "crawlee"; puts Crawlee::VERSION'
```

## Examples

### Basic HTTP Crawler

```ruby
require 'crawlee'

# Configure Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 10
  config.request_timeout = 30
end

# Create HTTP crawler
crawler = Crawlee::Crawlers::HttpCrawler.new

# Add route handler
crawler.router.add(/example\.com/) do |context|
  # Extract data
  title = context.query_selector('title')&.text
  
  # Save data
  context.save_data({
    url: context.request.url,
    title: title
  })
  
  # Extract and follow links
  context.enqueue_links('a')
end

# Add starting URL
crawler.enqueue('https://example.com')

# Run crawler
crawler.run
```

### More Examples

Check out the `examples` directory for more examples:

- Basic crawler using Nokogiri
- Browser crawler using Ferrum
- Adaptive crawler examples
- Proxy rotation examples
- Data storage examples

## Features

Why choose Crawlee Ruby for web scraping and data extraction?

### Why use Crawlee Ruby instead of a random HTTP library and HTML parser?

- Unified interface for **HTTP & browser crawling**
- Automatic **parallel crawling** based on available system resources
- Written in Ruby with **complete documentation** and **clear API**
- Automatic **retries** on errors or when you're getting blocked
- Integrated **proxy rotation** and session management
- Configurable **request routing** - direct URLs to the appropriate handlers
- Persistent **queue for URLs** to crawl
- Pluggable **storage** of both tabular data and files
- Robust **error handling**
- Anti-scraping bypass based on **real browser fingerprints**

### Why use Crawlee Ruby instead of other Ruby scraping frameworks?

- **Modern design** - Built on the latest Ruby practices and patterns
- **Simple integration** - Crawlee crawlers are regular Ruby scripts, requiring no additional launcher executor. This flexibility allows to integrate a crawler directly into other applications
- **State persistence** - Supports state persistence during interruptions, saving time and costs by avoiding the need to restart scraping pipelines from scratch after an issue
- **Organized data storages** - Allows saving of multiple types of results in a single scraping run. Offers several storing options (see datasets and key-value stores)
- **Advanced session management** - Provides robust session pool and cookie management capabilities, effectively simulating real user behavior

## Quick Start

### 1. Install Crawlee Ruby

```sh
gem install crawlee
```

### 2. Create Your First Crawler

Create a file named `my_crawler.rb`:

```ruby
require 'crawlee'

# Configure Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 5
end

# Create HTTP crawler
crawler = Crawlee::Crawlers::HttpCrawler.new

# Add default route handler
crawler.router.default_handler do |context|
  puts "Processing: #{context.request.url}"
  
  # Extract title
  title = context.query_selector('title')&.text
  puts "Page title: #{title}"
  
  # Save data
  context.save_data({
    url: context.request.url,
    title: title,
    crawled_at: Time.now.to_s
  })
  
  # Extract and follow all links
  context.enqueue_links('a')
end

# Add starting URL
crawler.enqueue('https://example.com')

# Run crawler
crawler.run
```

### 3. Run the Crawler

```sh
ruby my_crawler.rb
```

## Documentation

Complete documentation can be found in DeepWiki: [Crawlee Ruby Documentation](https://deepwiki.example.com/crawlee-ruby)

## Running on the Apify Platform

Crawlee Ruby can be run on the [Apify platform](https://apify.com), which provides infrastructure for hosting, scaling, and monitoring your crawlers.

## Support & Community

- **GitHub Issues**: If you encounter any issues while using Crawlee Ruby, please create an issue on our [GitHub repository](https://github.com/example/crawlee-ruby/issues)
- **Discussions**: Join our [discussion forum](https://github.com/example/crawlee-ruby/discussions) to share your experiences and questions

## Contributing

We welcome contributions of any kind! Please check out our [contribution guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
