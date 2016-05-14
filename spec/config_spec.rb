describe Civility::Config do
  let(:path) { '/tmp/.civility.yml' }
  let(:config) { Civility::Config.new(path: path) }

  before do
    # Config file includes updated_at timestamp and so this will avoid expects from failing on second rollovers
    Timecop.freeze
  end

  after do
    Timecop.return
    cleanup_tmp_files
  end

  describe '#initialize' do
    it 'requires a path' do
      expect { Civility::Config.new }.to raise_error(ArgumentError)
    end

    it 'stores path' do
      expect(config.send(:path)).to eq(path)
    end
  end

  describe '#load_file' do
    before do
      cleanup_tmp_files
    end

    it 'handles a missing file' do
      expect(File.exist?(path)).to be_falsy
      expect(config.send(:data)).to eq({})
    end

    it 'handles an invalid file' do
      save_file(path, '%')
      expect(File.exist?(path)).to be_truthy
      expect(config.send(:data)).to eq({})
    end

    it 'handles existing data' do
      save_file(path, 'foo: bar')
      expect(File.exist?(path)).to be_truthy
      expect(config.send(:data)).to eq('foo' => 'bar')
    end
  end

  describe '#save_file' do
    it 'saves data without an existing file' do
      config.set(foo: :bar)
      expect(File.read(path)).to eq({ foo: :bar, updated_at: Time.now.to_i }.to_yaml)
    end

    it 'saves data with an existing file' do
      config.set(foo: :bar)
      config.set(baz: :qux)
      expect(File.read(path)).to eq({ foo: :bar, updated_at: Time.now.to_i, baz: :qux }.to_yaml)
    end

    it 'sets updated_at time' do
      created_at = Time.now - 60
      save_file(path, { foo: :bar, updated_at: created_at.to_i }.to_yaml)
      config.set(baz: :qux)
      expect(File.read(path)).to_not include(created_at.to_i.to_s)
    end
  end

  describe '#set' do
    it 'updates data' do
      config.set(foo: :bar)
      expect(config.get(:foo)).to eq(:bar)
      config.set(foo: :baz)
      expect(config.get(:foo)).to eq(:baz)
    end

    it 'saves to disk' do
      config.set(foo: :bar)
      expect(config.get(:foo)).to eq(:bar)
      expect(File.read(path)).to eq({ foo: :bar, updated_at: Time.now.to_i }.to_yaml)
    end
  end

  describe '#get' do
    it 'returns the asked for value' do
      config.set(foo: :bar)
      expect(config.get(:foo)).to eq(:bar)
    end

    it 'returns nil when the key is not found' do
      config.set(foo: :bar)
      expect(config.get(:baz)).to be_nil
    end
  end

  describe '#delete' do
    it 'removes a key and value' do
      config.set(foo: :bar)
      config.set(baz: :qux)
      config.delete(:foo)
      expect(config.get(:foo)).to be_nil
      expect(config.get(:baz)).to eq(:qux)
    end
  end

  private

  def cleanup_tmp_files
    [path].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  def save_file(path, data)
    File.open(path, 'w') do |file|
      file.write(data)
    end
  end
end
