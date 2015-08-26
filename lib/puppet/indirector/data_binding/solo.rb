require 'puppet/indirector/terminus'
require 'puppet_x/solo/config'

class Puppet::DataBinding::Solo < Puppet::Indirector::Plain
  desc "data_binding terminus for use with solo face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Solo::Config[:data]
  end

end
