# frozen_string_literal: true

module Faraday
  # Middleware is the basic base class of any Faraday middleware.
  class Middleware
    extend MiddlewareRegistry

    attr_reader :app, :options

    DEFAULT_OPTIONS = {}.freeze

    def initialize(app = nil, options = {})
      @app = app
      @options = self.class.default_options.merge(options)
    end

    class << self
      # Faraday::Middleware::default_options= allows user to set default options at the Faraday::Middleware
      # class level.
      #
      # @example Set the Faraday::Response::RaiseError option, `include_request` to `false`
      # my_app/config/initializers/my_faraday_middleware.rb
      #
      # Faraday::Response::RaiseError.default_options = { include_request: false }
      #
      def default_options=(options = {})
        validate_default_options(options)
        @default_options = default_options.merge(options)
      end

      # default_options attr_reader that initializes class instance variable
      # with the values of any Faraday::Middleware defaults, and merges with
      # subclass defaults
      def default_options
        @default_options ||= DEFAULT_OPTIONS.merge(self::DEFAULT_OPTIONS)
      end

      private

      def validate_default_options(options)
        options.each_key do |opt|
          self::DEFAULT_OPTIONS.key?(opt) ||
            raise(Faraday::Error, "#{opt} is not a DEFAULT_OPTION for #{self}")
        end
      end
    end

    def call(env)
      on_request(env) if respond_to?(:on_request)
      app.call(env).on_complete do |environment|
        on_complete(environment) if respond_to?(:on_complete)
      end
    rescue StandardError => e
      on_error(e) if respond_to?(:on_error)
      raise
    end

    def close
      if app.respond_to?(:close)
        app.close
      else
        warn "#{app} does not implement \#close!"
      end
    end
  end
end
