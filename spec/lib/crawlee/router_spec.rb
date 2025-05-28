# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Router do
  let(:router) { Crawlee::Router.new }
  let(:context) { double('Context', request: request) }
  let(:request) { double('Request', url: 'https://example.com/page') }
  
  describe '#initialize' do
    it '创建一个路由器实例' do
      expect(router).to be_a(Crawlee::Router)
    end
    
    it '初始化时没有路由处理器' do
      handlers = router.instance_variable_get(:@handlers)
      expect(handlers).to be_empty
    end
    
    it '初始化时没有默认处理器' do
      default_handler = router.instance_variable_get(:@default_handler)
      expect(default_handler).to be_nil
    end
  end
  
  describe '#add' do
    it '添加路由处理器' do
      handler = proc { |ctx| puts ctx.request.url }
      router.add(/example\.com/, &handler)
      
      handlers = router.instance_variable_get(:@handlers)
      expect(handlers.size).to eq(1)
      expect(handlers.first[:pattern]).to eq(/example\.com/)
      expect(handlers.first[:handler]).to eq(handler)
    end
    
    it '添加多个路由处理器' do
      handler1 = proc { |ctx| puts "Handler 1: #{ctx.request.url}" }
      handler2 = proc { |ctx| puts "Handler 2: #{ctx.request.url}" }
      
      router.add(/example\.com/, &handler1)
      router.add(/page/, &handler2)
      
      handlers = router.instance_variable_get(:@handlers)
      expect(handlers.size).to eq(2)
    end
  end
  
  describe '#default_handler' do
    it '设置默认处理器' do
      handler = proc { |ctx| puts ctx.request.url }
      router.default_handler(&handler)
      
      default_handler = router.instance_variable_get(:@default_handler)
      expect(default_handler).to eq(handler)
    end
    
    it '覆盖之前设置的默认处理器' do
      handler1 = proc { |ctx| puts "Handler 1: #{ctx.request.url}" }
      handler2 = proc { |ctx| puts "Handler 2: #{ctx.request.url}" }
      
      router.default_handler(&handler1)
      router.default_handler(&handler2)
      
      default_handler = router.instance_variable_get(:@default_handler)
      expect(default_handler).to eq(handler2)
    end
  end
  
  describe '#route' do
    context '有匹配的路由处理器' do
      before do
        @called = false
        router.add(/example\.com/) do |ctx|
          @called = true
          "Handled by pattern handler: #{ctx.request.url}"
        end
      end
      
      it '调用匹配的路由处理器' do
        result = router.route(context)
        expect(@called).to be true
        expect(result).to eq("Handled by pattern handler: #{request.url}")
      end
    end
    
    context '有多个匹配的路由处理器' do
      before do
        @called1 = false
        @called2 = false
        
        router.add(/example/) do |ctx|
          @called1 = true
          "Handled by first handler: #{ctx.request.url}"
        end
        
        router.add(/page/) do |ctx|
          @called2 = true
          "Handled by second handler: #{ctx.request.url}"
        end
      end
      
      it '调用第一个匹配的路由处理器' do
        result = router.route(context)
        expect(@called1).to be true
        expect(@called2).to be false
        expect(result).to eq("Handled by first handler: #{request.url}")
      end
    end
    
    context '没有匹配的路由处理器但有默认处理器' do
      before do
        @pattern_called = false
        @default_called = false
        
        router.add(/other/) do |ctx|
          @pattern_called = true
          "Handled by pattern handler: #{ctx.request.url}"
        end
        
        router.default_handler do |ctx|
          @default_called = true
          "Handled by default handler: #{ctx.request.url}"
        end
      end
      
      it '调用默认处理器' do
        result = router.route(context)
        expect(@pattern_called).to be false
        expect(@default_called).to be true
        expect(result).to eq("Handled by default handler: #{request.url}")
      end
    end
    
    context '既没有匹配的路由处理器也没有默认处理器' do
      it '返回 nil' do
        result = router.route(context)
        expect(result).to be_nil
      end
    end
  end
  
  describe '#clear' do
    before do
      router.add(/example/) { |ctx| "Handler 1: #{ctx.request.url}" }
      router.add(/page/) { |ctx| "Handler 2: #{ctx.request.url}" }
      router.default_handler { |ctx| "Default: #{ctx.request.url}" }
    end
    
    it '清除所有路由处理器和默认处理器' do
      router.clear
      
      handlers = router.instance_variable_get(:@handlers)
      default_handler = router.instance_variable_get(:@default_handler)
      
      expect(handlers).to be_empty
      expect(default_handler).to be_nil
    end
  end
end
