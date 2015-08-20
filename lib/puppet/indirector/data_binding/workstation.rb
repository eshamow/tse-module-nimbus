class Puppet::DataBinding::Workstation < Puppet::Indirector::Terminus

  def find(request)
    raise "not implemented"
  rescue *DataBindingExceptions => detail
    raise Puppet::DataBinding::LookupError.new(detail.message, detail)
  end

end
