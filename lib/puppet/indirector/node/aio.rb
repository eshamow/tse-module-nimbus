require 'puppet_x/aio/config'
require 'puppet/indirector/plain'

class Puppet::Node::Aio < Puppet::Indirector::Plain
  desc "node terminus for use with the aio face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = PuppetX::Aio::Config[:classes]
    node.fact_merge
    node
  end
end
