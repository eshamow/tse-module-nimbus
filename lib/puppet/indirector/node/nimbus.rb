require 'puppet_x/nimbus/config'
require 'puppet/indirector/plain'

class Puppet::Node::Nimbus < Puppet::Indirector::Plain
  desc "node terminus for use with the nimbus face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = PuppetX::Nimbus::Config[:classes]
    node.fact_merge
    node
  end
end
