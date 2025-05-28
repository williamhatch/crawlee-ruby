# Publishing Crawlee Ruby to RubyGems.org

This document outlines the process for publishing the Crawlee Ruby gem to RubyGems.org, making it available for installation via `gem install crawlee`.

## Prerequisites

Before publishing, ensure you have:

1. A RubyGems.org account
2. The necessary permissions to publish under the `crawlee` gem name
3. A properly configured gemspec file
4. All required files in your project

## Step 1: Prepare Your Gemspec

Ensure your `crawlee.gemspec` file is properly configured with:

- Accurate metadata (name, version, description, etc.)
- Correct dependencies
- Proper file inclusions

Example of our prepared gemspec:

```ruby
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
  spec.files = Dir.glob("lib/**/*") + %w[LICENSE README.md]
  spec.require_paths = ["lib"]
end
```

## Step 2: Build the Gem Locally

Before publishing, build the gem locally to ensure everything is working correctly:

```bash
gem build crawlee.gemspec
```

This will create a file named `crawlee-x.x.x.gem` (where x.x.x is your version number).

## Step 3: Create a RubyGems.org Account

If you don't already have one, create an account at [RubyGems.org](https://rubygems.org/sign_up).

## Step 4: Sign In to RubyGems

Sign in to your RubyGems account:

```bash
gem signin
```

You'll be prompted to enter your RubyGems.org credentials.

## Step 5: Push the Gem to RubyGems.org

Push your gem to RubyGems.org:

```bash
gem push crawlee-x.x.x.gem
```

Replace `x.x.x` with your actual version number.

## Step 6: Verify the Publication

After pushing, verify that your gem is available on RubyGems.org:

1. Visit https://rubygems.org/gems/crawlee
2. Try installing it with `gem install crawlee`

## Step 7: Update Documentation

Ensure your README.md and other documentation correctly reflect the installation process:

```markdown
## Installation

```bash
gem install crawlee
```

Or add to your Gemfile:

```ruby
gem 'crawlee'
```

Then run:

```bash
bundle install
```
```

## Updating the Gem

When you need to update the gem:

1. Update the version number in `lib/crawlee/version.rb`
2. Make your changes
3. Rebuild and push the gem as described above

## Yanking a Version

If you need to remove a version from RubyGems.org:

```bash
gem yank crawlee -v x.x.x
```

## Best Practices

1. **Semantic Versioning**: Follow [semantic versioning](https://semver.org/) for your gem versions
2. **Changelog**: Maintain a CHANGELOG.md file to document changes between versions
3. **Documentation**: Keep documentation up-to-date with each release
4. **Testing**: Ensure all tests pass before publishing
5. **Security**: Never include sensitive information in your gem

## Troubleshooting

### Common Issues

1. **Name conflicts**: If the gem name is already taken, you'll need to choose a different name
2. **Permission issues**: Ensure you have the right permissions to push to the gem
3. **Dependency conflicts**: Make sure your dependencies are correctly specified and compatible

### Getting Help

If you encounter issues, consult:
- [RubyGems Guides](https://guides.rubygems.org/)
- [RubyGems Help](https://help.rubygems.org/)
- [Ruby Gems Community](https://community.rubygems.org/)
