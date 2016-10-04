require "lyra_client/version"
require "lyra_client/threadsafe_attributes"
require "lyra_client/to_query"
require "pry"
require "excon"
require 'json'

module LyraClient

  class Base

    class << self
      include ThreadsafeAttributes
      threadsafe_attribute :_headers, :_site, :_path_prefix, :_connection

      def site
        if _site_defined?
          _site
        end
      end

      def site=(site)
        self._connection = nil
        if site.nil?
          self._site = nil
        else
          uri = URI::parse(site)
          self._path_prefix = uri.path.to_s
          uri.path = ''
          self._site = uri.to_s
        end
      end

      def headers
        self._headers ||= {}
        if superclass != Object && superclass.headers
          self._headers = superclass.headers.merge(_headers)
        else
          _headers
        end
      end

      def headers=(headers)
        if headers.nil?
          self._headers = nil
        else
          self._headers = headers
        end
      end

      def path_prefix
        _path_prefix
      end

      attr_writer :collection_name

      def collection_name
        @collection_name
      end

      def connection(refresh = false)
        if _connection_defined? || superclass == Object
          if refresh || _connection.nil?
            self._connection = Excon.new(site)
          end
          _connection
        else
          superclass.connection
        end
      end

      #
      # Examples:
      # all({headers}, {query params})
      # all({"X-Auth-Token" => 'd4e2f9461ef14137b055d1668758c9ca'}, {limit: 10})
      #
      def all(headers = {}, params = {})
        find(:all, headers, params)
      end

      #
      # Examples:
      # find(scope, {headers}, {query params})
      # find(:all, {"X-Auth-Token" => 'd4e2f9461ef14137b055d1668758c9ca'}, {limit: 10})
      # find(test_id, {"X-Auth-Token" => 'd4e2f9461ef14137b055d1668758c9ca'}, {tags: 'all'})
      #
      def find(*arguments)
        scope   = arguments.slice!(0)
        headers = arguments.slice!(0) || {}
        options = arguments.slice!(0) || {}

        case scope
          when :all   then
            path = collection_path(options)
            instantiate_collection(request('get', path, headers))
          else
            path = singelton_path(scope, options)
            instantiate_record(request('get', path, headers).data.fetch(:body, {}))
        end
      end

      def singelton_path(id, query_options = nil)
        "#{path_prefix}/#{collection_name}/#{URI.escape(id.to_s)}#{query_string(query_options)}"
      end

      def collection_path(query_options = nil)
        "#{path_prefix}/#{collection_name}#{query_string(query_options)}"
      end

      def instantiate_record(record)
        new(record, true)
      end

      def instantiate_collection(response)
        Collection.new(response).collect!
      end

      def query_string(options)
        "?#{options.to_query}" unless options.nil? || options.empty?
      end

      def request(method, path, headers = {})
        # collect headers
        req_headers = {'Content-Type' => 'application/json'}
        headers.each do |key, value|
          req_headers[key] = value
        end
        # request
        connection.request(
          :method => method,
          :path => path,
          :headers => req_headers
        )
      end

    end

    attr_accessor :attributes

    def initialize(attributes = {}, persisted = false)
      @attributes = attributes
      @persisted = persisted
    end

  end

  class Collection
    include Enumerable

    attr_accessor :elements
    attr_reader :response

    def initialize(response = nil)
      @response = response
    end

    def to_a
      @elements
    end

    def <<(val)
      @elements << val
    end

    def each(&block)
      @elements.each(&block)
    end

    def collect!
      # set the elemets
      set = []
      body = @response.data.fetch(:body, "[]") unless @response.nil?
      records = JSON.parse(body)
      records.each { |record| set <<  Base::instantiate_record(record)}
      @elements = set
      self
    end

  end

end
