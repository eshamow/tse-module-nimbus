require 'puppet/indirector/face'
require 'puppet_x/localhost/config'
require 'puppet/application/apply'
require 'puppet/util/command_line'
require 'fileutils'

Puppet::Face.define(:localhost, '1.0.0') do

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Manage configuration of the local system."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone Puppet environment.
  EOT

  option('--localhost-environment <environment>') do |arg|
    default_to { 'default' }
    summary "the localhost_environment value to use"
  end

  option('--localhost-environmentpath <path>') do |arg|
    default_to { File.join(Puppet[:codedir], 'localhost_environments') }
    summary "the localhost_environmentpath value to use"
  end

  option('--localhost-confdir <path>') do |arg|
    default_to { File.join(Puppet[:confdir], 'localhost') }
    summary "the localhost_confdir value to use"
  end

  option('--localhost-config <path>') do |arg|
    default_to { nil }
    summary "a specific configuration file to use"
  end

  action :help do
    default
    summary "Display help about the localhost subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('localhost')
    end
  end

  action :modules do
    summary "Manage localhost modules."
    when_invoked do |command, options|
      localhost_context(options) do
        case command
        when "install"
          modules = PuppetX::Localhost::Config[:modules]
          modules.each do |key,value|
            install = Puppet::Face[:module, '1.0.0'].install(key,
              :environment => options[:localhost_environment],
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
          Puppet::Face[:module, '1.0.0'].list(:environment => options[:localhost_environment])
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
      localhost_context(options) do
        argv = ['--execute', '']
        command_line = Puppet::Util::CommandLine.new('puppet', argv)
        apply = Puppet::Application::Apply.new(command_line)
        apply.parse_options
        apply.run_command
      end
    end
  end

  action :get do
    summary "Retrieve and install a localhost configuration file."
    arguments "<uri>"
    when_invoked do |uri, options|
      set_global_config(options)
      raise ":get action not implemented"
    end
  end

  def localhost_context(options, &block)
    set_global_config(options)
    Puppet[:node_terminus] = 'localhost'
    Puppet[:data_binding_terminus] = 'localhost'
    Puppet[:environmentpath] = options[:localhost_environmentpath]
    Puppet[:environment] = options[:localhost_environment]

    loader = Puppet::Environments::Directories.new(
      Puppet[:environmentpath],
      Puppet[:basemodulepath].split(':')
    )

    Puppet.override(:environments => loader) do
      block.call
    end
  end

  def set_global_config(options)
    PuppetX::Localhost::Config.environment = options[:localhost_environment]
    PuppetX::Localhost::Config.environmentpath = options[:localhost_environmentpath]
    PuppetX::Localhost::Config.confdir = options[:localhost_confdir]
    PuppetX::Localhost::Config.config = options[:localhost_config]

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ options[:localhost_environmentpath],
      options[:localhost_confdir],
      File.join(options[:localhost_environmentpath], options[:localhost_environment]),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Localhost::Config.parse_config!
  end

end
