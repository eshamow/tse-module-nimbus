require 'puppet/indirector/face'
require 'puppet_x/nimbus/config'
require 'puppet/application/apply'
require 'puppet/util/command_line'
require 'fileutils'
require 'open-uri'
require 'tempfile'

Puppet::Face.define(:nimbus, '1.0.0') do

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Manage configuration of the local system using an all-in-one (nimbus) input."
  description <<-'EOT'
    This subcommand uses Puppet to configure state on the local system using a
    standalone all-in-one (nimbus) Puppet environment, with all classification,
    data bindings, and modules (code) specified in a unified input.
  EOT

  option('--nimbus-environment <environment>') do |arg|
    default_to { 'default' }
    summary "the nimbus_environment value to use"
  end

  option('--nimbus-environmentpath <path>') do |arg|
    default_to { File.join(Puppet[:codedir], 'nimbus_environments') }
    summary "the nimbus_environmentpath value to use"
  end

  option('--nimbus-confdir <path>') do |arg|
    default_to { File.join(Puppet[:confdir], 'nimbus') }
    summary "the nimbus_confdir value to use"
  end

  option('--nimbus-config <path>') do |arg|
    default_to { nil }
    summary "a specific configuration file to use"
  end

  action :help do
    default
    summary "Display help about the nimbus subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('nimbus')
    end
  end

  action :install_modules do
    summary "Install modules specified by an nimbus configuration file in an nimbus environment."
    when_invoked do |*configs, options|
      options[:argv_configs] = configs
      nimbus_context(options) do
        modules = PuppetX::Nimbus::Config[:modules]
        modules.each do |name,params|
          case params['type']
          when 'forge', nil
            install_module_using_pmt(name, params, options)
          when 'tarball'
            install_module_from_uri(name, params, options)
          else
            puts "Error: unable to install #{name} from type #{params['type']}"
          end
        end
      end
      "Done"
    end
  end

  action :list_modules do
    when_invoked do |options|
      nimbus_context(options) do
        Puppet::Face[:module, '1.0.0'].list(:environment => options[:nimbus_environment])
      end
    end

    when_rendering :console do |result|
      # TODO: do a custom render. For now I'm just hijacking the render
      # method from the module face. This is, of course, terrible.
      Puppet::Face[:module, '1.0.0'].get_action(:list).instance_variable_get(:@when_rendering)[:console].bind(Puppet::Face[:module, '1.0.0']).call(result, {})
    end
  end

  action :apply do
    summary "Configure the local system using Puppet all-in-one."
    when_invoked do |*configs, options|
      options[:argv_configs] = configs
      nimbus_context(options) do
        argv = ['--execute', '']
        command_line = Puppet::Util::CommandLine.new('puppet', argv)
        apply = Puppet::Application::Apply.new(command_line)
        apply.parse_options
        apply.run_command
      end
    end
  end

  action :get do
    summary "Retrieve and install a nimbus configuration file."
    arguments "<uri>"
    when_invoked do |uri, options|
      set_global_config(options)
      raise ":get action not implemented"
    end
  end

  def install_module_from_uri(name, params, options)
    file = Tempfile.new("#{name.gsub(/(\\|\/)/, '_')}_")
    begin
      file.binmode
      open(params['source']) do |uri|
        file.write(uri.read)
      end
      install_module_using_pmt(file.path, params, options)
    ensure
      file.close
      file.unlink
    end
  end

  def install_module_using_pmt(name, params, options)
    install = Puppet::Face[:module, '1.0.0'].install(name,
      :environment => options[:nimbus_environment],
      :ignore_dependencies => true,
      :force => true,
      :version => params['version']
    )
    if install[:result] == :failure
      raise install[:error][:multiline]
    else
      puts "Notice: Installed #{name} (#{params['version']})"
    end
  end

  def nimbus_context(options, &block)
    set_global_config(options)
    Puppet[:node_terminus] = 'nimbus'
    Puppet[:data_binding_terminus] = 'nimbus'
    Puppet[:environmentpath] = options[:nimbus_environmentpath]
    Puppet[:environment] = options[:nimbus_environment]

    loader = Puppet::Environments::Directories.new(
      Puppet[:environmentpath],
      Puppet[:basemodulepath].split(':')
    )

    Puppet.override(:environments => loader) do
      block.call
    end
  end

  def set_global_config(options)
    PuppetX::Nimbus::Config.environment = options[:nimbus_environment]
    PuppetX::Nimbus::Config.environmentpath = options[:nimbus_environmentpath]
    PuppetX::Nimbus::Config.confdir = options[:nimbus_confdir]

    options[:argv_configs] = nil unless options[:argv_configs] != [{}]
    PuppetX::Nimbus::Config.config = [options[:nimbus_config], options[:argv_configs]].flatten.compact

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ options[:nimbus_environmentpath],
      options[:nimbus_confdir],
      File.join(options[:nimbus_environmentpath], options[:nimbus_environment]),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Nimbus::Config.parse_config!
  end

end
