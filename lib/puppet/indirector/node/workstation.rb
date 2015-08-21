require 'puppet_x/workstation/config'
require 'puppet/indirector/plain'

class Puppet::Node::Workstation < Puppet::Indirector::Plain
  desc "node terminus for use with the workstation face."

  def find(request)
    node = Puppet::Node.new(request.key)
    node.classes = YAML.load(File.read(PuppetX::Workstation::Config.config))['classes']
    node.fact_merge
    node
  end
end
