#!/usr/bin/env ruby
# encoding: utf-8

# Use locally compiled Crawlee Ruby to scrape investment events from 36kr
# and save the results in JSON format

# Add local library path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'crawlee'
require 'json'
require 'fileutils'
require 'nokogiri'
require 'httparty'
require 'addressable/uri'

# Ensure json directory exists
FileUtils.mkdir_p('json')

puts "Starting to scrape investment events from 36kr..."

# Configure Crawlee
Crawlee.configure do |config|
  config.max_concurrency = 1
  config.request_timeout = 60
  config.max_retries = 3
  config.default_headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
end

# Create browser crawler
crawler = Crawlee::Crawlers::BrowserCrawler.new

# Add default route handler
crawler.router.default_handler do |context|
  puts "Processing: #{context.request.url}"
  
  # Wait for page to load completely
  context.wait_for_selector('.invest-list')
  
  # Extract investment event data
  events = []
  
  # Get all investment event elements
  event_elements = context.query_selector_all('.invest-list .invest-item')
  
  event_elements.each_with_index do |element, index|
    begin
      # Extract data
      company_name = element.query_selector('.company-name')&.text&.strip
      round = element.query_selector('.round')&.text&.strip
      industry = element.query_selector('.industry')&.text&.strip
      date = element.query_selector('.date')&.text&.strip
      amount = element.query_selector('.amount')&.text&.strip
      investors = element.query_selector('.investors')&.text&.strip
      
      # Create event object
      event = {
        company_name: company_name,
        round: round,
        industry: industry,
        date: date,
        amount: amount,
        investors: investors
      }
      
      puts "Extracted event #{index + 1}: #{company_name}"
      events << event
    rescue => e
      puts "Error extracting event #{index + 1}: #{e.message}"
    end
  end
  
  # Save as JSON
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  filename = "json/pitchhub_36kr_#{timestamp}.json"
  
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(events))
  end
  
  puts "Saved #{events.size} investment events to #{filename}"
end

# Add starting URL
crawler.enqueue('https://pitchhub.36kr.com/investevent')

# Run crawler
crawler.run
