require 'fileutils'

require 'rabbit/rabbit'

module Rabbit
  module Source
    
    module Base
      
      attr_reader :encoding, :base, :tmp_base
      attr_accessor :force_modified
      
      def initialize(encoding)
        @encoding = encoding
        @source = nil
        @force_modified = false
        init_base
      end
      
      def read
        if need_read?
          @source = _read
          unless /\Autf-?8\z/i =~ @encoding
            require "iconv"
            @source = Iconv.iconv("UTF-8", @encoding, @source)
          end
        end
        @source
      end
      
      def modified?
        @force_modified or need_read?
      end
      
      def need_read?
        @source.nil?
      end
      
      def full_path(path)
        uri = parse_uri(@base)
        if uri.nil? or uri.relative?
          ::File.join(@base, path)
        else
          uri.path = uri.path + "/" unless /\/$/ =~ uri.path
          (uri + path).to_s
        end
      end
      
      def open_full_path(path, mode="rb")
        open(full_path(path), mode) do |f|
          yield f
        end
      end
      
      def old?(current, get_latest_method_name)
        current.nil? or
          (current and __send__(get_latest_method_name) > current)
      end
      
      def tmp_dir_name
        dir = ::File.join(@tmp_base, TMP_DIR_NAME)  
        FileUtils.mkdir_p(dir) unless ::File.exist?(dir)
        dir
      end
      
      def base=(new_value)
        if new_value.nil?
          init_base
        else
          set_base(new_value)
        end
      end
      
      private
      def init_base
        set_base(".")
      end
      
      def set_base(new_value)
        @base = new_value
        uri = parse_uri(@base)
        if uri.nil? or uri.scheme.nil?
          @tmp_base = @base
        else
          @tmp_base = "."
        end
      end

      def parse_uri(str)
        begin
          ::URI.parse(str)
        rescue ::URI::InvalidURIError
          nil
        end
      end
      
    end

    module LimitAccessInterval
      MINIMUM_ACCESS_TIME = 60

      def initialize(*args, &block)
        update_last_access_time
        super
      end

      def old?(current, get_latest_method_name)
        result = (can_access? and super)
        update_last_access_time if result
        result
      end
      
      private
      def update_last_access_time
        @last_access_time = Time.now
      end

      def can_access?
        Time.now - @last_access_time > MINIMUM_ACCESS_TIME
      end
    end
    
  end
end