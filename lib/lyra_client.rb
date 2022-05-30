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
            path = singleton_path(scope, options)
            response = request('get', path, headers)
            body = response.data.fetch(:body, "{}") unless response.nil?
            new(response, JSON.parse(body), true)
        end
      end

      def instantiate_collection(response)
        Collection.new(response).collect! { |record| new(response, record, true) }
      end

      def singleton_path(id, query_options = nil)
        # changed URI.scape to CGI.escape as proposed here
        # https://ruby-doc.org/stdlib-2.7.0/libdoc/uri/rdoc/URI/Escape.html
        "#{path_prefix}/#{collection_name}/#{CGI.escape(id.to_s)}#{query_string(query_options)}"
      end

      def collection_path(query_options = nil)
        "#{path_prefix}/#{collection_name}#{query_string(query_options)}"
      end

      def query_string(options)
        "?#{options.to_query}" unless options.nil? || options.empty?
      end

      def collect_headers(req_headers = {})
        collect_headers = {'Content-Type' => 'application/json'}
        # add class header attributes
        collect_headers.merge!(self.headers)
        # add request headers
        collect_headers.merge!(req_headers)
      end

      def request(method, path, headers = {}, body = "")
        # request
        connection.request(
          :expects => [200, 201, 204],
          :method => method,
          :path => path,
          :headers => collect_headers(headers),
          :body => body
        )
      end

    end

    attr_accessor :attributes, :errors
    attr_reader :response

    def initialize(response = nil, attributes = {}, persisted = false)
      @response = response
      @attributes = attributes
      @persisted = persisted
      @errors = {}
    end

    def save(*arguments)
      headers = arguments.slice!(0) || {}
      options = arguments.slice!(0) || {}

      if @persisted
        # update
        update(headers, options)
      else
        # create
        create(headers, options)
      end
    end

    def save!(*arguments)
      save(*arguments)
    rescue => e
      self.add_errors(e.response.body)
      return false
    end

    def create(headers = {}, options = {})
      path = self.class.collection_path(options)
      response = self.class.request('post', path, headers, attributes.to_json)
      body = response.body
      record = JSON.parse(body)
      self.attributes['id'] = record['id']
    end

    def update(headers = {}, options = {})
      path = self.class.singleton_path(self.attributes['id'], options)
      self.class.request('put', path, headers, attributes.to_json)
    end

    def destroy(headers = {}, options = {})
      path = self.class.singleton_path(self.attributes['id'], options)
      self.class.request('delete', path, headers)
    end

    # private

    def add_errors(response)
      decoded = JSON.parse(response) rescue {}
      if decoded.kind_of?(Hash) && (decoded.has_key?('errors') || decoded.empty?)
        self.errors = decoded['errors'] || {}
      end
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

    def empty?
      @elements.empty?
    end

    def collect!
      return elements unless block_given?
      set = []
      body = @response.body unless @response.nil?
      records = JSON.parse(body)
      records.each { |o| set << yield(o) }
      @elements = set
      self
    end

    def total_pages
      total_elements = @response.nil? ? 0 : @response.headers.fetch('Pagination-Elements', "").to_i
      if limit_value != 0
        total = total_elements / limit_value
        if total_elements % limit_value > 0
          total += 1
        end
        return total
      end
      return 0
    end

    def current_page
      @response.headers.fetch('Pagination-Page', "").to_i
    end

    def limit_value
      @response.headers.fetch('Pagination-Per-Page', "").to_i
    end

  end

end
