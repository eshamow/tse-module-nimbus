require 'puppet/indirector/face'
Puppet::Face.define(:workstation, '1.0.0') do
  copyright "Puppet Labs", 2015
  license   "Commercial"

  summary "Manage configuration of the local system."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone Puppet environment.
  EOT

  option('--workstation-confdir <path>') do |arg|
    default_to { nil }
    summary "the workstation_confdir value to use"
  end
  
  option('--workstation-config <path>') do |arg|
    default_to { nil }
    summary "the workstation_config value to use"
  end
  
  option('--workstation-environmentpath <path>') do |arg|
    default_to { nil }
    summary "the workstation_environmentpath value to use"
  end
  
  option('--workstation-environment <environment>') do |arg|
    default_to { nil }
    summary "the workstation_environment value to use"
  end

  action :help do
    default
    summary "Display help about the workstation subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('workstation')
    end
  end

  action :configure do
    summary "Configure the local system using Puppet."
    when_invoked do |options|
      raise "not implemented"
    end
  end

  action :enable do
    summary "Subject to change. Enable a given environment for configuration."
    when_invoked do |options|
      raise "not implemented"
    end
  end
end
