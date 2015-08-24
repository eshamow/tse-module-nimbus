require 'puppet/indirector/face'
require 'puppet_x/singleton/config'
require 'puppet/application/apply'
require 'puppet/util/command_line'
require 'fileutils'

Puppet::Face.define(:singleton, '1.0.0') do

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Manage configuration of the local system."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone Puppet environment.
  EOT

  option('--singleton-environment <environment>') do |arg|
    default_to { 'default' }
    summary "the singleton_environment value to use"
  end

  option('--singleton-environmentpath <path>') do |arg|
    default_to { File.join(Puppet[:codedir], 'singleton_environments') }
    summary "the singleton_environmentpath value to use"
  end

  option('--singleton-confdir <path>') do |arg|
    default_to { File.join(Puppet[:confdir], 'singleton') }
    summary "the singleton_confdir value to use"
  end

  option('--singleton-config <path>') do |arg|
    default_to { nil }
    summary "a specific configuration file to use"
  end

  action :help do
    default
    summary "Display help about the singleton subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('singleton')
    end
  end

  action :modules do
    summary "Manage singleton modules."
    when_invoked do |command, options|
      singleton_context(options) do
        case command
        when "install"
          modules = PuppetX::Singleton::Config[:modules]
          modules.each do |key,value|
            install = Puppet::Face[:module, '1.0.0'].install(key,
              :environment => options[:singleton_environment],
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
          Puppet::Face[:module, '1.0.0'].list(:environment => options[:singleton_environment])
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
      singleton_context(options) do
        argv = ['--execute', '']
        command_line = Puppet::Util::CommandLine.new('puppet', argv)
        apply = Puppet::Application::Apply.new(command_line)
        apply.parse_options
        apply.run_command
      end
    end
  end

  action :get do
    summary "Retrieve and install a singleton configuration file."
    arguments "<uri>"
    when_invoked do |uri, options|
      set_global_config(options)
      raise ":get action not implemented"
    end
  end

  def singleton_context(options, &block)
    set_global_config(options)
    Puppet[:node_terminus] = 'singleton'
    Puppet[:data_binding_terminus] = 'singleton'
    Puppet[:environmentpath] = options[:singleton_environmentpath]
    Puppet[:environment] = options[:singleton_environment]

    loader = Puppet::Environments::Directories.new(
      Puppet[:environmentpath],
      Puppet[:basemodulepath].split(':')
    )

    Puppet.override(:environments => loader) do
      block.call
    end
  end

  def set_global_config(options)
    PuppetX::Singleton::Config.environment = options[:singleton_environment]
    PuppetX::Singleton::Config.environmentpath = options[:singleton_environmentpath]
    PuppetX::Singleton::Config.confdir = options[:singleton_confdir]
    PuppetX::Singleton::Config.config = options[:singleton_config]

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ options[:singleton_environmentpath],
      options[:singleton_confdir],
      File.join(options[:singleton_environmentpath], options[:singleton_environment]),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Singleton::Config.parse_config!
  end

end
