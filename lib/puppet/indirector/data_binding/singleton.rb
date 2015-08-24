require 'puppet/indirector/terminus'
require 'puppet_x/singleton/config'

class Puppet::DataBinding::Singleton < Puppet::Indirector::Plain
  desc "data_binding terminus for use with singleton face."

  def find(request)
    data[request.key] || nil
  end

  def data
    @data ||= PuppetX::Singleton::Config[:data]
  end

end
