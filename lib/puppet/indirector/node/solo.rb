require 'puppet_x/solo/config'
require 'puppet/indirector/plain'

class Puppet::Node::Solo < Puppet::Indirector::Plain
  desc "node terminus for use with the solo face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = PuppetX::Solo::Config[:classes]
    node.fact_merge
    node
  end
end
