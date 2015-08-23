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

  option('--workstation-config <path>') do |arg|
    default_to { nil }
    summary "a specific configuration file to use"
  end

  action :help do
    default
    summary "Display help about the workstation subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('workstation')
    end
  end

  action :modules do
    summary "Manage workstation modules."
    when_invoked do |command, options|
      workstation_context(options) do
        case command
        when "install"
          modules = PuppetX::Workstation::Config[:modules]
          modules.each do |key,value|
            install = Puppet::Face[:module, '1.0.0'].install(key,
              :environment => options[:workstation_environment],
              :ignore_dependencies => true,
              :force => true,
              :version => value['version']
            )
            if install[:result] == :failure
              raise install[:error][:multiline]
            else
              puts "Notice: Installed #{key} (#{value['version']})"
            end
          end
        when "list"
          Puppet::Face[:module, '1.0.0'].list(:environment => options[:workstation_environment])
        else
          raise 'specify either "list" or "install".'
        end
      end
    end

    when_rendering :console do |result, command, options|
      case command
      when "list"
        # TODO: do a custom render. For now I'm just hijacking the render
        # method from the module face. This is, of course, terrible.
        Puppet::Face[:module, '1.0.0'].get_action(:list).instance_variable_get(:@when_rendering)[:console].bind(Puppet::Face[:module, '1.0.0']).call(result, {})
      when "install"
        ""
      else
        result
      end
    end
  end

  action :configure do
    summary "Configure the local system using Puppet."
    when_invoked do |options|
      workstation_context(options) do
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
    arguments "<uri>"
    when_invoked do |uri, options|
      set_global_config(options)
      raise ":get action not implemented"
    end
  end

  def workstation_context(options, &block)
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
      block.call
    end
  end

  def set_global_config(options)
    PuppetX::Workstation::Config.environment = options[:workstation_environment]
    PuppetX::Workstation::Config.environmentpath = options[:workstation_environmentpath]
    PuppetX::Workstation::Config.confdir = options[:workstation_confdir]
    PuppetX::Workstation::Config.config = options[:workstation_config]

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
