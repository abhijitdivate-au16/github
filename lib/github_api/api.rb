# -*- encoding: utf-8 -*-

require 'github_api/configuration'
require 'github_api/connection'
require 'github_api/validations'
require 'github_api/request'
require 'github_api/mime_type'
require 'github_api/rate_limit'
require 'github_api/core_ext/hash'
require 'github_api/core_ext/array'
require 'github_api/compatibility'
require 'github_api/api/actions'
require 'github_api/api_factory'

module Github
  # Core class for api interface operations
  class API
    include Constants
    include Authorization
    include MimeType
    include Connection
    include Request
    include RateLimit
    # include Configuration

    # TODO consider these optional in a stack
    include Validations
    include ParameterFilter
    include Normalizer

    attr_reader *Configuration.keys

    attr_accessor *VALID_API_KEYS

    attr_accessor :current_options

    # Callback to update current configuration options
     class_eval do
       Configuration.keys.each do |key|
         define_method "#{key}=" do |arg|
           self.instance_variable_set("@#{key}", arg)
           self.current_options.merge!({:"#{key}" => arg})
         end
       end
     end

    # Create new API
    #
    def initialize(options={}, &block)
      setup(options)
      client(options) if client_id? && client_secret?
      yield_or_eval(&block) if block_given?
    end

    def yield_or_eval(&block)
      return unless block
      block.arity > 0 ? yield(self) : self.instance_eval(&block)
    end

    # Configure options and process basic authorization
    #
    def setup(options={})
      options = Github.options.merge(options)
      self.current_options = options
      Configuration.keys.each do |key|
        send("#{key}=", options[key])
      end
      process_basic_auth(options[:basic_auth])
    end

    # Extract login and password from basic_auth parameter
    #
    def process_basic_auth(auth)
      case auth
      when String
        self.login, self.password = auth.split(':', 2)
      when Hash
        self.login    = auth[:login]
        self.password = auth[:password]
      end
    end

    # Responds to attribute query or attribute clear
    def method_missing(method, *args, &block) # :nodoc:
      case method.to_s
      when /^(.*)\?$/
        return !self.send($1.to_s).nil?
      when /^clear_(.*)$/
        self.send("#{$1.to_s}=", nil)
      else
        super
      end
    end

    # Set an option to a given value
    def set(option, value=(not_set = true), &block)
      raise ArgumentError, 'value not set' if block and !not_set

      if not_set
        set_options option
        return self
      end

      if respond_to?("#{option}=")
        return __send__("#{option}=", value)
      end

      self
    end

    private

    # Set multiple options
    def set_options(options)
      unless options.respond_to?(:each)
        raise ArgumentError, 'cannot iterate over value'
      end
      options.each { |key, value| set(key, value) }
    end

    def _merge_mime_type(resource, params) # :nodoc:
#       params['resource'] = resource
#       params['mime_type'] = params['mime_type'] || :raw
    end

  end # API
end # Github
