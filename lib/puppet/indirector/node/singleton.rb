require 'puppet_x/singleton/config'
require 'puppet/indirector/plain'

class Puppet::Node::Singleton < Puppet::Indirector::Plain
  desc "node terminus for use with the singleton face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = PuppetX::Singleton::Config[:classes]
    node.fact_merge
    node
  end
end
