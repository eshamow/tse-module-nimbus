require 'puppet/application'

class Puppet::Application::Workstation < Puppet::Application
  option('--workstation-confdir VALUE') do |arg|
    options[:workstation_confdir] = arg
  end

  option('--workstation-config VALUE') do |arg|
    options[:workstation_config] = arg
  end

  option('--workstation-environmentpath VALUE') do |arg|
    options[:workstation_environmentpath] = arg
  end

  option('--workstation-environment VALUE') do |arg|
    options[:workstation_environment] = arg
  end

  def run_command
    options[:directive] = command_line.args.shift
    options[:keys] = command_line.args
    puts "Hello World!"
    puts options
  end 
end
