require 'singleton'
require 'hocon'

module PuppetX
  module Workstation
    class Config
      include Singleton
      singleton_class.class_eval { attr_accessor :environment }
      singleton_class.class_eval { attr_accessor :environmentpath }
      singleton_class.class_eval { attr_accessor :confdir }
      singleton_class.class_eval { attr_reader   :config }

      def self.parse_config!
        @config = {:classes => [], :data => {}, :modules => {}}
        Dir.glob("#{@confdir}/*.conf") do |conffile|
          new_data = Hocon::ConfigFactory.parse_file(conffile).root.unwrapped
          @config[:classes] << new_data['classes']      if new_data['classes']
          @config[:data].merge!(new_data['data'])       if new_data['data']
          @config[:modules].merge!(new_data['modules']) if new_data['modules']
        end
        @config[:classes] = @config[:classes].flatten.uniq
      end
    end
  end
end
