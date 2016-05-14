
require 'yaml'

class Civility
  class Config
    def initialize(path:)
      @path = path
      @data = load_file
    end

    def set(opts)
      data.merge!(opts)
      save_file
    end

    def get(key)
      # TODO: support a default value
      data[key]
    end

    def delete(key)
      data.delete(key)
      save_file
    end

    private

    attr_reader :path
    attr_accessor :data

    def update_timestamp
      data[:updated_at] = Time.now.to_i
    end

    def load_file
      File.exist?(path) ? YAML.load_file(path) : {}
    rescue Psych::SyntaxError
      {}
    end

    def save_file
      update_timestamp
      File.write(path, data.to_yaml)
    end

    def config=(settings)
      File.open(path, 'w') do |file|
        file.write settings.to_yaml
      end
    end
  end
end
