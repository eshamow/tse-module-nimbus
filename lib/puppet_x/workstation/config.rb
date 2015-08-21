require 'singleton'

module PuppetX
  module Workstation
    class Config
      include Singleton
      singleton_class.class_eval { attr_accessor :environment }
      singleton_class.class_eval { attr_accessor :environmentpath }
      singleton_class.class_eval { attr_accessor :confdir }
      singleton_class.class_eval { attr_accessor :config }
    end
  end
end
