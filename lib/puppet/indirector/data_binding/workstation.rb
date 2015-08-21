require 'puppet/indirector/terminus'

class Puppet::DataBinding::Workstation < Puppet::Indirector::Terminus
  desc "data_binding terminus for use with workstation face."

  def find(request)
    data[request.key] || nil
  end

  def self.data
    @data ||= YAML.load(File.read(PuppetX::Workstation::Config.config))['data']
  end

end
