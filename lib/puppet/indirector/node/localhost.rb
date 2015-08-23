require 'puppet_x/localhost/config'
require 'puppet/indirector/plain'

class Puppet::Node::Localhost < Puppet::Indirector::Plain
  desc "node terminus for use with the localhost face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = PuppetX::Localhost::Config[:classes]
    node.fact_merge
    node
  end
end
