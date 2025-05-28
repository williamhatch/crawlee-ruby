# frozen_string_literal: true

require 'faker'

module Crawlee
  # 生成浏览器指纹的类
  # 用于创建真实的浏览器指纹，以避免被网站检测为爬虫
  class FingerprintGenerator
    # 支持的浏览器类型
    BROWSERS = [:chrome, :firefox, :safari, :edge].freeze
    
    # 支持的设备类型
    DEVICES = [:desktop, :mobile, :tablet].freeze
    
    # 支持的操作系统
    OS = [:windows, :macos, :linux, :android, :ios].freeze
    
    # 支持的语言区域
    LOCALES = ['zh-CN', 'en-US', 'en-GB', 'ja-JP', 'de-DE', 'fr-FR'].freeze
    
    # 初始化指纹生成器
    # @param browsers [Array<Symbol>] 要模拟的浏览器类型
    # @param devices [Array<Symbol>] 要模拟的设备类型
    # @param os [Array<Symbol>] 要模拟的操作系统
    # @param locales [Array<String>] 要模拟的语言区域
    def initialize(browsers: nil, devices: nil, os: nil, locales: nil)
      @browsers = browsers || BROWSERS
      @devices = devices || DEVICES
      @os = os || OS
      @locales = locales || LOCALES
    end
    
    # 生成随机指纹
    # @param domain [String] 目标域名
    # @return [Hash] 指纹数据
    def generate(domain = nil)
      browser = @browsers.sample
      device = @devices.sample
      os_type = @os.sample
      locale = @locales.sample
      
      fingerprint = {
        browser: browser,
        device: device,
        os: os_type,
        locale: locale,
        headers: generate_headers(browser, device, os_type, locale),
        navigator: generate_navigator(browser, device, os_type),
        screen: generate_screen(device),
        plugins: generate_plugins(browser),
        fonts: generate_fonts(os_type)
      }
      
      fingerprint
    end
    
    # 生成 HTTP 请求头
    # @param browser [Symbol] 浏览器类型
    # @param device [Symbol] 设备类型
    # @param os [Symbol] 操作系统
    # @param locale [String] 语言区域
    # @return [Hash] HTTP 请求头
    def generate_headers(browser, device, os, locale)
      user_agent = generate_user_agent(browser, device, os)
      
      headers = {
        'User-Agent' => user_agent,
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language' => "#{locale},en;q=0.5",
        'Accept-Encoding' => 'gzip, deflate, br',
        'DNT' => ['0', '1'].sample,
        'Connection' => 'keep-alive',
        'Upgrade-Insecure-Requests' => '1',
        'Sec-Fetch-Dest' => 'document',
        'Sec-Fetch-Mode' => 'navigate',
        'Sec-Fetch-Site' => 'none',
        'Sec-Fetch-User' => '?1',
        'Cache-Control' => 'max-age=0'
      }
      
      # 添加浏览器特定的头
      case browser
      when :chrome
        headers['sec-ch-ua'] = '"Google Chrome";v="89", "Chromium";v="89", ";Not A Brand";v="99"'
        headers['sec-ch-ua-mobile'] = device == :mobile ? '?1' : '?0'
        headers['sec-ch-ua-platform'] = os.to_s.capitalize
      end
      
      headers
    end
    
    private
    
    # 生成用户代理字符串
    # @param browser [Symbol] 浏览器类型
    # @param device [Symbol] 设备类型
    # @param os [Symbol] 操作系统
    # @return [String] 用户代理字符串
    def generate_user_agent(browser, device, os)
      case browser
      when :chrome
        if device == :mobile && [:android, :ios].include?(os)
          Faker::Internet.user_agent(vendor: :chrome, device: :android)
        else
          Faker::Internet.user_agent(vendor: :chrome)
        end
      when :firefox
        Faker::Internet.user_agent(vendor: :firefox)
      when :safari
        if device == :mobile && os == :ios
          Faker::Internet.user_agent(vendor: :safari, device: :ios)
        else
          Faker::Internet.user_agent(vendor: :safari)
        end
      when :edge
        "Mozilla/5.0 (#{os_string(os)}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36 Edg/89.0.774.50"
      end
    end
    
    # 生成操作系统字符串
    # @param os [Symbol] 操作系统
    # @return [String] 操作系统字符串
    def os_string(os)
      case os
      when :windows
        "Windows NT #{['10.0', '6.3', '6.2', '6.1'].sample}"
      when :macos
        "Macintosh; Intel Mac OS X #{['10_15_7', '11_2_3', '10_14_6'].sample}"
      when :linux
        "X11; Linux #{['x86_64', 'i686'].sample}"
      when :android
        "Linux; Android #{rand(8..12)}.0; #{['Pixel', 'Galaxy S20', 'OnePlus 8'].sample}"
      when :ios
        "iPhone; CPU iPhone OS #{rand(12..15)}_#{rand(0..6)} like Mac OS X"
      end
    end
    
    # 生成浏览器导航器对象
    # @param browser [Symbol] 浏览器类型
    # @param device [Symbol] 设备类型
    # @param os [Symbol] 操作系统
    # @return [Hash] 导航器对象
    def generate_navigator(browser, device, os)
      is_mobile = device == :mobile
      
      {
        userAgent: generate_user_agent(browser, device, os),
        appName: 'Netscape',
        appVersion: '5.0',
        platform: os_platform(os),
        product: 'Gecko',
        productSub: '20030107',
        vendor: browser_vendor(browser),
        language: @locales.sample.split('-').first,
        languages: @locales.map { |l| l.split('-').first }.uniq,
        cookieEnabled: true,
        doNotTrack: ['1', nil].sample,
        maxTouchPoints: is_mobile ? rand(1..5) : 0,
        hardwareConcurrency: [2, 4, 8, 16].sample,
        deviceMemory: [2, 4, 8, 16].sample
      }
    end
    
    # 获取操作系统平台字符串
    # @param os [Symbol] 操作系统
    # @return [String] 平台字符串
    def os_platform(os)
      case os
      when :windows
        'Win32'
      when :macos
        'MacIntel'
      when :linux
        'Linux x86_64'
      when :android
        'Linux armv8l'
      when :ios
        'iPhone'
      end
    end
    
    # 获取浏览器供应商字符串
    # @param browser [Symbol] 浏览器类型
    # @return [String] 供应商字符串
    def browser_vendor(browser)
      case browser
      when :chrome
        'Google Inc.'
      when :safari
        'Apple Computer, Inc.'
      when :edge
        'Microsoft Corporation'
      else
        ''
      end
    end
    
    # 生成屏幕信息
    # @param device [Symbol] 设备类型
    # @return [Hash] 屏幕信息
    def generate_screen(device)
      case device
      when :desktop
        {
          width: [1366, 1440, 1920, 2560].sample,
          height: [768, 900, 1080, 1440].sample,
          colorDepth: 24,
          pixelDepth: 24,
          availWidth: [1366, 1440, 1920, 2560].sample,
          availHeight: [728, 860, 1040, 1400].sample
        }
      when :mobile
        {
          width: [320, 375, 414, 428].sample,
          height: [568, 667, 736, 926].sample,
          colorDepth: 24,
          pixelDepth: 24,
          availWidth: [320, 375, 414, 428].sample,
          availHeight: [518, 617, 686, 876].sample
        }
      when :tablet
        {
          width: [768, 834, 1024].sample,
          height: [1024, 1112, 1366].sample,
          colorDepth: 24,
          pixelDepth: 24,
          availWidth: [768, 834, 1024].sample,
          availHeight: [974, 1062, 1316].sample
        }
      end
    end
    
    # 生成插件信息
    # @param browser [Symbol] 浏览器类型
    # @return [Array<Hash>] 插件信息
    def generate_plugins(browser)
      plugins = []
      
      # Chrome 和 Edge 的常见插件
      if [:chrome, :edge].include?(browser)
        plugins << { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer' }
        plugins << { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai' }
        plugins << { name: 'Native Client', filename: 'internal-nacl-plugin' }
      end
      
      # Firefox 的常见插件
      if browser == :firefox
        plugins << { name: 'Shockwave Flash', filename: 'libflashplayer.so' }
        plugins << { name: 'Firefox PDF Viewer', filename: 'internal-pdf-viewer' }
      end
      
      plugins
    end
    
    # 生成字体信息
    # @param os [Symbol] 操作系统
    # @return [Array<String>] 字体列表
    def generate_fonts(os)
      common_fonts = ['Arial', 'Verdana', 'Helvetica', 'Times New Roman', 'Courier New']
      
      case os
      when :windows
        common_fonts + ['Segoe UI', 'Tahoma', 'Calibri', 'Cambria', 'Consolas']
      when :macos
        common_fonts + ['San Francisco', 'Helvetica Neue', 'Lucida Grande', 'Monaco', 'Menlo']
      when :linux
        common_fonts + ['Ubuntu', 'DejaVu Sans', 'Liberation Sans', 'Droid Sans', 'Nimbus Sans L']
      when :android
        common_fonts + ['Roboto', 'Droid Sans', 'Noto Sans', 'Droid Serif', 'Noto Serif']
      when :ios
        common_fonts + ['San Francisco', 'Helvetica Neue', 'Avenir', 'Avenir Next', 'Futura']
      end
    end
  end
end
