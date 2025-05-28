#!/bin/bash
# Crawlee Ruby Test Script
# Run test cases and execute crawler examples

# Set color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Crawlee Ruby Test Script${NC}"
echo "=============================="

# 0. Install dependencies
echo -e "\n${YELLOW}0. Installing necessary dependencies${NC}"
echo "------------------------------"

rvm use 3.2.2
gem install bundler --no-document
bundle install

# Create logs directory
mkdir -p logs

# 1. Run RSpec tests
echo -e "\n${YELLOW}1. Running RSpec tests${NC}"
echo "------------------------------"
bundle exec rspec 2>&1 | tee logs/rspec_tests.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
else
  echo -e "${RED}✗ Tests failed, please check the logs${NC}"
fi

# 2. Run basic HTTP crawler example
echo -e "\n${YELLOW}2. Running basic HTTP crawler example${NC}"
echo "------------------------------"
ruby examples/basic_http_crawler.rb 2>&1 | tee logs/basic_http_crawler.log

# 3. Run browser crawler example
echo -e "\n${YELLOW}3. Running browser crawler example${NC}"
echo "------------------------------"
ruby examples/browser_crawler_example.rb 2>&1 | tee logs/browser_crawler.log

# 4. Run adaptive crawler example
echo -e "\n${YELLOW}4. Running adaptive crawler example${NC}"
echo "------------------------------"
ruby examples/adaptive_crawler_example.rb 2>&1 | tee logs/adaptive_crawler.log

# 5. Run 36kr investment event crawler
echo -e "\n${YELLOW}5. Scraping 36kr investment event data${NC}"
echo "------------------------------"
ruby examples/pitchhub_36kr_crawler.rb 2>&1 | tee logs/pitchhub_36kr_crawler.log

echo -e "\n${GREEN}Testing complete!${NC}"
echo "All log files are saved in the logs directory"
echo "Scraped 36kr data is saved in the json directory"
