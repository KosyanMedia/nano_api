module NanoApi
  module Global

    def client= value
      Thread.current[:client] = value
    end

    def client
      Thread.current[:client] || NanoApi::Client.new
    end

    def config= hash
      @config = NanoApi::Config.new(hash)
    end

    def config
      @config ||= begin
        file = File.join(root, 'config', 'nano_api.yml')
        if File.exist?(file)
          NanoApi::Config.new(YAML.load_file(file)[env])
        else
          raise 'No nano_api config file found. Please create one using `rails g nano_api:config` command'
        end
      end
    end

    # Returns the Rails.root_to_s when you are using rails
    # Running the current directory in a generic Ruby process
    def root
      @root ||= defined?(Rails) ? Rails.root.to_s : Dir.pwd
    end

    def env
      @env = defined?(Rails) ? Rails.env : 'development'
    end
  end
end