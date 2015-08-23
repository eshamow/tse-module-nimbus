require 'singleton'
require 'hocon'

module PuppetX
  module Localhost
    class Config
      include Singleton

      singleton_class.class_eval { attr_accessor :environment }
      singleton_class.class_eval { attr_accessor :environmentpath }
      singleton_class.class_eval { attr_accessor :confdir }
      singleton_class.class_eval { attr_accessor :config }

      def self.[](index)
        @data[index]
      end

      def self.[]=(index, value)
        @data[index] = value
      end

      def self.parse_config!
        @data = {:classes => [], :data => {}, :modules => {}}
        confdir_files = Dir.glob("#{@confdir}/*.conf")
        [confdir_files, @config].flatten.compact.each do |file|
          new_data = Hocon::ConfigFactory.parse_file(file).root.unwrapped
          @data[:classes] << new_data['classes']      if new_data['classes']
          @data[:data].merge!(new_data['data'])       if new_data['data']
          @data[:modules].merge!(new_data['modules']) if new_data['modules']
        end
        @data[:classes] = @data[:classes].flatten.uniq
      end
    end
  end
end
