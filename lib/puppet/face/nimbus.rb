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

  action :help do
    default
    summary "Display help about the nimbus subcommand."
    when_invoked do |*args|
      Puppet::Face[:help, '0.0.1'].help('nimbus')
    end
  end

  action :install_modules do
    summary "Install modules specified in given nimbus configuration file(s) in a nimbus environment."
    when_invoked do |*user_arguments, options|
      set_global_config(user_arguments)
      install_all_modules
      "Done"
    end
  end

  action :list_modules do
    when_invoked do |options|
      list_modules_using_pmt
    end

    when_rendering :console do |result|
      # TODO: do a custom render. For now I'm just hijacking the render
      # method from the module face. This is, of course, terrible.
      Puppet::Face[:module, '1.0.0'].get_action(:list).instance_variable_get(:@when_rendering)[:console].bind(Puppet::Face[:module, '1.0.0']).call(result, {})
    end
  end

  action :apply do
    summary "Configure the local system using given Puppet all-in-one configuration file(s)."
    when_invoked do |*user_arguments, options|
      set_global_config(user_arguments)
      install_all_modules unless all_modules_installed?
      nimbus_context do
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
      raise ":get action not implemented"
    end
  end

  def setting_environment
    if Puppet.settings.set_by_cli?(:environment)
      Puppet[:environment]
    else
      'nimbus'
    end
  end

  def setting_environmentpath
    if Puppet.settings.set_by_cli?(:environmentpath)
      Puppet[:environmentpath]
    else
      File.join(Puppet[:codedir], 'nimbus_environments')
    end
  end

  def install_all_modules
    raise "Premature internal method call" unless PuppetX::Nimbus::Config.config_parsed?
    nimbus_context do
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
  end

  def install_module_from_uri(name, params, options)
    file = Tempfile.new("#{name.gsub(/(\\|\/)/, '_')}_")
    begin
      file.binmode
      open(params['source']) do |uri|
        file.write(uri.read)
        file.flush
      end
      install_module_using_pmt(file.path, params, options)
    ensure
      file.close
      file.unlink
    end
  end

  def install_module_using_pmt(name, params, options)
    install = Puppet::Face[:module, '1.0.0'].install(name,
      :environment => setting_environment,
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

  def list_modules_using_pmt
    nimbus_context do
      Puppet::Face[:module, '1.0.0'].list(:environment => setting_environment)
    end
  end

  def all_modules_installed?
    raise "Premature internal method call" unless PuppetX::Nimbus::Config.config_parsed?

    installed_module_names = []
    list_modules_using_pmt[:modules_by_path].each do |path|
      path[1].each do |mod|
        installed_module_names << mod.name
        installed_module_names << mod.forge_name
      end
    end

    installed_module_names.compact!

    PuppetX::Nimbus::Config[:modules].all? do |name,params|
      installed_module_names.include?(name)
    end
  end

  def nimbus_context(user_arguments = [], &block)

    set_global_config(user_arguments)
    Puppet[:node_terminus]         = 'nimbus'
    Puppet[:data_binding_terminus] = 'nimbus'
    Puppet[:environmentpath]       = setting_environmentpath
    Puppet[:environment]           = setting_environment

    loader = Puppet::Environments::Directories.new(
      Puppet[:environmentpath],
      Puppet[:basemodulepath].split(':')
    )

    Puppet.override(:environments => loader) do
      block.call
    end
  end

  def set_global_config(user_arguments)
    return if PuppetX::Nimbus::Config.config_parsed?
    # If no arguments are given, for some reason that's not an empty array but
    # is instead an array with an empty hash in it.
    user_arguments.delete({})

    PuppetX::Nimbus::Config.environment     = setting_environment
    PuppetX::Nimbus::Config.environmentpath = setting_environmentpath
    PuppetX::Nimbus::Config.config          = [user_arguments].flatten.compact

    # Make a best-effort to create the working directories if they don't
    # already exist. Note the use of mkdir instead of mkdir_p; this will only
    # work if the parent directories already exist.
    [ setting_environmentpath,
      File.join(setting_environmentpath, setting_environment),
    ].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Load config, if there is any
    PuppetX::Nimbus::Config.parse_config!
  end

end
