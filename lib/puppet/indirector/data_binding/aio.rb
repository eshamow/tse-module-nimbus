require 'puppet/indirector/terminus'
require 'puppet_x/aio/config'

class Puppet::DataBinding::Aio < Puppet::Indirector::Plain
  desc "data_binding terminus for use with aio face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Aio::Config[:data]
  end

end
