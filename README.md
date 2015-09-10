# Nimbus #

This module provides a new Puppet command, `puppet nimbus`.

When `puppet nimbus apply` is run, Puppet will set the runtime
$environmentpath to `$nimbus_environmentpath`, set the runtime `$environment`
to `$nimbus_environment`, and read `$nimbus_config`. A custom node
terminus will be switched to that reads classes from the `classes` config key.
A custom data terminus will be used to bind data from the `data` config key.
The `$nimbus_environment` will be populated to match the modules defined in
the `modules` config key. With this configuration primed, Puppet will be run.

The end result is that users may define a single text file or set of text files
to be merged that list all the modules they want, the data they want, and the
classes they want applied to their local machine. They may then use the `puppet
nimbus` command to easily puppetize their system from that input.

Note that alternatively, a confdir may be specified, in which case all .conf
files inside the confdir will be read and merged into a compositional
configuration. This allows for things such as starting from a common
configuration and adding in personal customization by including an additional
file.

New users can get started with a config provided by their company or team.

## Volatility Note ##

This module is in early development and everything is subject to change. That
includes the module name. This subcommand this module provides has previously
been called by many other names including `puppet singleton`, `puppet
workstation`, `puppet solo`, and `puppet aio`. Currently it is called `puppet
nimbus`, which is intended to be a codename which does not convey any
particular function other than serving as an identifier.

## Examples ##

Assume that the Puppet AIO package has just been installed and nothing else.
This is an example of bootstrapping a nimbus configuration. Try it!

    puppet module install tse/nimbus
    curl -Lo example.conf http://git.io/vZBXu
    puppet nimbus install_modules example.conf
    puppet nimbus apply example.conf

> Note on OSX: due to https://tickets.puppetlabs.com/browse/PUP-3450 it is
> necessary to update root CA bundles used by Puppet to get the module tool
> working (to install modules). The following can be used to do that:
>
>     export OPENSSL=/opt/puppetlabs/puppet/bin/openssl
>     sudo /opt/puppetlabs/puppet/bin/c_rehash /opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs
>     export SSL_CERT_DIR=/opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs
>
> As long as SSL_CERT_DIR is set correctly any Puppet command that needs access to the
> Forge will work.

## Directory structure ##

    $codedir/
    |-- environments/
    `-- nimbus_environments/    # $nimbus_environmentpath
        `-- default                  # $nimbus_environment
            |-- manifests/
            |   `-- site.pp
            |-- modules/
            `-- hieradata/

    $confdir/
    `-- nimbus/               # $nimbus_confdir
        `-- nimbus.conf         # $nimbus_config

## Configuration File ##

    # nimbus.conf (hocon)
    classes: [
      "stdlib::stages",
      "nimbus::test",
    ]

    data: {
      "nimbus::test::arg1": "example",
      "nimbus::test::arg2": "like hiera data",
    }

    modules: {
      "puppetlabs/stdlib": {
        "version": "4.9.0",
      },
      "tse/nimbus": {
        "version": "0.5.0",
      },
      "lwf/remote_file": {
        "type": "tarball",
        "source": "https://github.com/lwf/puppet-remote_file/archive/v1.0.1.tar.gz",
        "version": "1.0.1",
      }
    }

## Options ##

### `--nimbus-config <path>` ###

The path to a Hocon configuration file specifying classes, data, and/or modules
to use in nimbus configuration.

### `--nimbus-confdir <path>` ###

The path to a directory containing one or more `*.conf` Hocon configuration
files, each of which may specify classes, data, or modules. All the `*.conf`
files in this directory will be read, merged, and the result used in nimbus
configuration.

### `--nimbus-environment <name>` ###

Puppet nimbus uses environments just like Puppet. This flag sets the name of
the environment the run will use.

### `--nimbus-environmentpath <path>` ###

Puppet nimbus typically uses a subcommand-specific environmentpath. This
flag allows you to set the path used explicitly. It may be useful if you have
manually installed modules or created an environment you want the command to
use.
