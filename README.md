# Workstation #

This module provides a new Puppet command, `puppet workstation`.

When `puppet workstation configure` is run, Puppet will set the runtime
$environmentpath to $workstation_environmentpath, set the runtime $environment
to $workstation_environment, and read $workstation_config. A custom node
terminus will be switched to that reads classes from the `classes` config key.
A custom data terminus will be used to bind data from the `data` config key.
The $workstation_environment will be populated to match the modules defined in
the `modules` config key. With this configuration primed, Puppet will be run.

The end result is that users may define a single text file that lists all the
modules they want, the data they want, and the classes they want applied to
their local machine. They may then use the `puppet workstation` command to
easily puppetize their system from that input.

Note that alternatively, a confdir may be specified, in which case all .conf
files inside the confdir will be read and merged into a compositional
configuration. This allows for things such as starting from a common
configuration and adding in personal customization by including an additional
file.

New users can get started with a config provided by their company or team.

    puppet module install tse/workstation
    puppet workstation get http://company.com/puppet-workstation.conf
    puppet workstation configure

## Examples ##

Assume that the Puppet AIO package has just been installed and nothing else.
This is an example of bootstrapping a workstation configuration. Try it!

    puppet module install tse/workstation
    curl -Lo example.conf http://git.io/vswiI
    puppet workstation --workstation-config=example.conf modules install
    puppet workstation --workstation-config=example.conf configure

Note on OSX: due to https://tickets.puppetlabs.com/browse/PUP-3450 it is
necessary to update root CA bundles used by Puppet to get the module tool
working (to install modules). The following can be used to do that:

    export OPENSSL=/opt/puppetlabs/puppet/bin/openssl
    sudo /opt/puppetlabs/puppet/bin/c_rehash /opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs
    export SSL_CERT_DIR=/opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs

As long as SSL_CERT_DIR is set correctly any Puppet command that needs access to the
Forge will work.

## Directory structure ##

    $codedir/
    |-- environments/
    `-- workstation_environments/    # $workstation_environmentpath
        `-- default                  # $workstation_environment
            |-- manifests/
            |   `-- site.pp
            |-- modules/
            `-- hieradata/

    $confdir/
    `-- workstation/               # $workstation_confdir
        `-- workstation.conf         # $workstation_config

## Configuration File ##

    # workstation.conf (hocon)
    classes: [
      "git",
      "caffeine",
    ]

    data: {
      "git::version": "2.5.0",
      "caffeine::default_duration": "1h",
    }

    modules: {
      "puppetlabs/git": {
        "version": "1.0.0",
      },
      "macuser/caffeine": {
        "version": "1.0.5",
        "source":  "http://example.com/macuser-caffeine-1.0.5.tar.gz",
      }
    }

## Old Ideas ##

    puppet workstation-environment add --source <uri> --name <name> [--workstation-environmentpath <path>]
    puppet workstation-environment delete --name <name> [--workstation-environmentpath <path>]
    puppet workstation-environment list [--workstation-environmentpath <path>]
