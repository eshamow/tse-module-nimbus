require 'puppet/indirector/terminus'
require 'puppet_x/workstation/config'

class Puppet::DataBinding::Workstation < Puppet::Indirector::Plain
  desc "data_binding terminus for use with workstation face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Workstation::Config.config[:data]
  end

end
