require 'puppet/indirector/terminus'
require 'puppet_x/localhost/config'

class Puppet::DataBinding::Localhost < Puppet::Indirector::Plain
  desc "data_binding terminus for use with localhost face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Localhost::Config[:data]
  end

end
