require 'puppet/indirector/face'
require 'puppet_x/workstation/config'
require 'puppet/application/apply'
require 'puppet/util/command_line'
require 'fileutils'

Puppet::Face.define(:workstation, '1.0.0') do

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Manage configuration of the local system."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone Puppet environment.
  EOT

  option('--workstation-environment <environment>') do |arg|
    default_to { 'default' }
    summary "the workstation_environment value to use"
  end

  option('--workstation-environmentpath <path>') do |arg|
    default_to { File.join(Puppet[:codedir], 'workstation_environments') }
    summary "the workstation_environmentpath value to use"
  end

  option('--workstation-confdir <path>') do |arg|
    default_to { File.join(Puppet[:confdir], 'workstation') }
    summary "the workstation_confdir value to use"
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
      set_global_config(options)
      Puppet[:node_terminus] = 'workstation'
      Puppet[:data_binding_terminus] = 'workstation'
      Puppet[:environmentpath] = options[:workstation_environmentpath]
      Puppet[:environment] = options[:workstation_environment]

      loader = Puppet::Environments::Directories.new(
        Puppet[:environmentpath],
        Puppet[:basemodulepath].split(':')
      )

      Puppet.override(:environments => loader) do
        argv = ['--execute', '']
        command_line = Puppet::Util::CommandLine.new('puppet', argv)
        apply = Puppet::Application::Apply.new(command_line)
        apply.parse_options
        apply.run_command
      end
    end
  end

  action :get do
    summary "Retrieve and install a workstation configuration file."
    when_invoked do |options|
      set_global_config(options)
      raise "not implemented"
    end
  end

  def set_global_config(options)
    PuppetX::Workstation::Config.environment = options[:workstation_environment]
    PuppetX::Workstation::Config.environmentpath = options[:workstation_environmentpath]
    PuppetX::Workstation::Config.confdir = options[:workstation_confdir]

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ options[:workstation_environmentpath],
      options[:workstation_confdir],
      File.join(options[:workstation_environmentpath], options[:workstation_environment]),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Workstation::Config.parse_config!
  end

end
