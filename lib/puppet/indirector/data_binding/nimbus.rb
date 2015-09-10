require 'puppet/indirector/terminus'
require 'puppet_x/nimbus/config'

class Puppet::DataBinding::Nimbus < Puppet::Indirector::Plain
  desc "data_binding terminus for use with nimbus face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Nimbus::Config[:data]
  end

end
