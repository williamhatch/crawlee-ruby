# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crawlee::Storage do
  let(:storage_dir) { File.join('tmp', 'test_storage') }
  
  before do
    # 确保测试目录存在
    FileUtils.mkdir_p(storage_dir)
  end
  
  after do
    # 清理测试目录
    FileUtils.rm_rf(storage_dir)
  end
  
  describe '.open' do
    it '打开存储实例' do
      storage = Crawlee::Storage.open(storage_dir)
      expect(storage).to be_a(Crawlee::Storage)
    end
    
    it '使用自定义选项打开存储实例' do
      storage = Crawlee::Storage.open(storage_dir, name: 'custom')
      expect(storage.name).to eq('custom')
    end
  end
  
  describe '#dataset' do
    let(:storage) { Crawlee::Storage.open(storage_dir) }
    
    it '返回数据集实例' do
      dataset = storage.dataset
      expect(dataset).to be_a(Crawlee::DatasetStorage)
    end
    
    it '返回指定名称的数据集' do
      dataset = storage.dataset('custom')
      expect(dataset.name).to eq('custom')
    end
    
    it '返回相同名称的相同数据集实例' do
      dataset1 = storage.dataset('same')
      dataset2 = storage.dataset('same')
      expect(dataset1).to eq(dataset2)
    end
  end
  
  describe '#request_queue' do
    let(:storage) { Crawlee::Storage.open(storage_dir) }
    
    it '返回请求队列实例' do
      queue = storage.request_queue
      expect(queue).to be_a(Crawlee::RequestQueueStorage)
    end
    
    it '返回指定名称的请求队列' do
      queue = storage.request_queue('custom')
      expect(queue.name).to eq('custom')
    end
    
    it '返回相同名称的相同请求队列实例' do
      queue1 = storage.request_queue('same')
      queue2 = storage.request_queue('same')
      expect(queue1).to eq(queue2)
    end
  end
  
  describe '#key_value_store' do
    let(:storage) { Crawlee::Storage.open(storage_dir) }
    
    it '返回键值存储实例' do
      store = storage.key_value_store
      expect(store).to be_a(Crawlee::KeyValueStorage)
    end
    
    it '返回指定名称的键值存储' do
      store = storage.key_value_store('custom')
      expect(store.name).to eq('custom')
    end
    
    it '返回相同名称的相同键值存储实例' do
      store1 = storage.key_value_store('same')
      store2 = storage.key_value_store('same')
      expect(store1).to eq(store2)
    end
  end
end

RSpec.describe Crawlee::Storage::DatasetStorage do
  let(:storage_dir) { File.join('tmp', 'test_storage') }
  let(:dataset_name) { 'test_dataset' }
  let(:dataset) { Crawlee::Storage.open(storage_dir).dataset(dataset_name) }
  
  before do
    # 确保测试目录存在
    FileUtils.mkdir_p(storage_dir)
  end
  
  after do
    # 清理测试目录
    FileUtils.rm_rf(storage_dir)
  end
  
  describe '#push_data' do
    it '添加数据到数据集' do
      data = { title: '测试标题', url: 'https://example.com' }
      result = dataset.push_data(data)
      
      expect(result).to include(:id)
      expect(result).to include(:createdAt)
      expect(result[:title]).to eq('测试标题')
      expect(result[:url]).to eq('https://example.com')
    end
    
    it '添加多个数据项到数据集' do
      data1 = { title: '标题1', url: 'https://example.com/1' }
      data2 = { title: '标题2', url: 'https://example.com/2' }
      
      dataset.push_data(data1)
      dataset.push_data(data2)
      
      all_data = dataset.get_data
      expect(all_data.size).to eq(2)
      expect(all_data.map { |d| d[:title] }).to contain_exactly('标题1', '标题2')
    end
    
    it '确保所有键都是符号形式' do
      data = { 'title' => '测试标题', 'url' => 'https://example.com' }
      result = dataset.push_data(data)
      
      expect(result).to have_key(:title)
      expect(result).to have_key(:url)
      expect(result).not_to have_key('title')
      expect(result).not_to have_key('url')
    end
  end
  
  describe '#get_data' do
    before do
      dataset.push_data({ title: '标题1', url: 'https://example.com/1' })
      dataset.push_data({ title: '标题2', url: 'https://example.com/2' })
    end
    
    it '获取所有数据' do
      all_data = dataset.get_data
      expect(all_data.size).to eq(2)
      expect(all_data.first).to include(:title, :url, :id, :createdAt)
    end
    
    it '确保所有键都是符号形式' do
      all_data = dataset.get_data
      all_data.each do |item|
        item.keys.each do |key|
          expect(key).to be_a(Symbol)
        end
      end
    end
  end
  
  describe '#clear' do
    before do
      dataset.push_data({ title: '标题1', url: 'https://example.com/1' })
      dataset.push_data({ title: '标题2', url: 'https://example.com/2' })
    end
    
    it '清空数据集' do
      expect(dataset.get_data.size).to eq(2)
      
      dataset.clear
      
      expect(dataset.get_data.size).to eq(0)
    end
  end
end

RSpec.describe Crawlee::Storage::RequestQueueStorage do
  let(:storage_dir) { File.join('tmp', 'test_storage') }
  let(:queue_name) { 'test_queue' }
  let(:queue) { Crawlee::Storage.open(storage_dir).request_queue(queue_name) }
  
  before do
    # 确保测试目录存在
    FileUtils.mkdir_p(storage_dir)
  end
  
  after do
    # 清理测试目录
    FileUtils.rm_rf(storage_dir)
  end
  
  describe '#add' do
    it '添加请求到队列' do
      request = Crawlee::Request.new('https://example.com')
      result = queue.add(request)
      
      expect(result).to be true
      expect(queue.size).to eq(1)
    end
    
    it '不添加重复的请求' do
      request1 = Crawlee::Request.new('https://example.com')
      request2 = Crawlee::Request.new('https://example.com')
      
      queue.add(request1)
      result = queue.add(request2)
      
      expect(result).to be false
      expect(queue.size).to eq(1)
    end
    
    it '添加不同的请求' do
      request1 = Crawlee::Request.new('https://example.com/1')
      request2 = Crawlee::Request.new('https://example.com/2')
      
      queue.add(request1)
      queue.add(request2)
      
      expect(queue.size).to eq(2)
    end
  end
  
  describe '#fetch' do
    before do
      queue.add(Crawlee::Request.new('https://example.com/1'))
      queue.add(Crawlee::Request.new('https://example.com/2'))
    end
    
    it '获取下一个请求' do
      request = queue.fetch
      expect(request).to be_a(Crawlee::Request)
      expect(request.url).to eq('https://example.com/1')
    end
    
    it '获取所有请求' do
      requests = []
      while request = queue.fetch
        requests << request
      end
      
      expect(requests.size).to eq(2)
      expect(requests.map(&:url)).to contain_exactly(
        'https://example.com/1',
        'https://example.com/2'
      )
    end
  end
  
  describe '#mark_handled' do
    let(:request) { Crawlee::Request.new('https://example.com') }
    
    before do
      queue.add(request)
    end
    
    it '标记请求为已处理' do
      queue.mark_handled(request)
      
      # 已处理的请求不应该再被获取
      expect(queue.fetch).to be_nil
    end
  end
  
  describe '#clear' do
    before do
      queue.add(Crawlee::Request.new('https://example.com/1'))
      queue.add(Crawlee::Request.new('https://example.com/2'))
    end
    
    it '清空请求队列' do
      expect(queue.size).to eq(2)
      
      queue.clear
      
      expect(queue.size).to eq(0)
      expect(queue.fetch).to be_nil
    end
  end
end
