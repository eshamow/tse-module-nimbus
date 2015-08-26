require 'puppet/indirector/face'
require 'puppet_x/solo/config'
require 'puppet/application/apply'
require 'puppet/util/command_line'
require 'fileutils'

Puppet::Face.define(:solo, '1.0.0') do

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Manage configuration of the local system."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone Puppet environment.
  EOT

  option('--solo-environment <environment>') do |arg|
    default_to { 'default' }
    summary "the solo_environment value to use"
  end

  option('--solo-environmentpath <path>') do |arg|
    default_to { File.join(Puppet[:codedir], 'solo_environments') }
    summary "the solo_environmentpath value to use"
  end

  option('--solo-confdir <path>') do |arg|
    default_to { File.join(Puppet[:confdir], 'solo') }
    summary "the solo_confdir value to use"
  end

  option('--solo-config <path>') do |arg|
    default_to { nil }
    summary "a specific configuration file to use"
  end

  action :help do
    default
    summary "Display help about the solo subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('solo')
    end
  end

  action :modules do
    summary "Manage solo modules."
    when_invoked do |command, options|
      solo_context(options) do
        case command
        when "install"
          modules = PuppetX::Solo::Config[:modules]
          modules.each do |key,value|
            install = Puppet::Face[:module, '1.0.0'].install(key,
              :environment => options[:solo_environment],
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
          Puppet::Face[:module, '1.0.0'].list(:environment => options[:solo_environment])
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
      solo_context(options) do
        argv = ['--execute', '']
        command_line = Puppet::Util::CommandLine.new('puppet', argv)
        apply = Puppet::Application::Apply.new(command_line)
        apply.parse_options
        apply.run_command
      end
    end
  end

  action :get do
    summary "Retrieve and install a solo configuration file."
    arguments "<uri>"
    when_invoked do |uri, options|
      set_global_config(options)
      raise ":get action not implemented"
    end
  end

  def solo_context(options, &block)
    set_global_config(options)
    Puppet[:node_terminus] = 'solo'
    Puppet[:data_binding_terminus] = 'solo'
    Puppet[:environmentpath] = options[:solo_environmentpath]
    Puppet[:environment] = options[:solo_environment]

    loader = Puppet::Environments::Directories.new(
      Puppet[:environmentpath],
      Puppet[:basemodulepath].split(':')
    )

    Puppet.override(:environments => loader) do
      block.call
    end
  end

  def set_global_config(options)
    PuppetX::Solo::Config.environment = options[:solo_environment]
    PuppetX::Solo::Config.environmentpath = options[:solo_environmentpath]
    PuppetX::Solo::Config.confdir = options[:solo_confdir]
    PuppetX::Solo::Config.config = options[:solo_config]

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ options[:solo_environmentpath],
      options[:solo_confdir],
      File.join(options[:solo_environmentpath], options[:solo_environment]),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Solo::Config.parse_config!
  end

end