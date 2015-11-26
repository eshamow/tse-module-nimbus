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

## Known Issues ##

Puppet code containing file resources with source parameters set to puppet://
URIs do not work. This is a bug that needs to be resolved in the nimbus module.

## Examples ##

### Basic ###

Assume that the Puppet AIO package has just been installed and nothing else.
This is an example of bootstrapping a nimbus configuration. Try it!

    puppet module install tse/nimbus
    curl -Lo example.conf https://git.io/vZBXu
    puppet nimbus install_modules example.conf
    puppet nimbus apply example.conf

Or:

    puppet module install tse/nimbus
    puppet nimbus install_modules https://git.io/vZBXu
    puppet nimbus apply https://git.io/vZBXu

Or just:

    puppet module install tse/nimbus
    puppet nimbus apply https://git.io/vZBXu

> Note on OSX: due to https://tickets.puppetlabs.com/browse/PUP-3450 it is
> necessary to update root CA bundles used by Puppet to get the module tool
> working (to install modules). The following can be used to do that:
>
>     export OPENSSL=/opt/puppetlabs/puppet/bin/openssl
>     sudo /opt/puppetlabs/puppet/bin/c_rehash /opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs
>     export SSL_CERT_DIR=/opt/puppetlabs/puppet/lib/ruby/2.1.0/rubygems/ssl_certs
>
> As long as SSL\_CERT\_DIR is set correctly any Puppet command that needs
> access to the > Forge will work.

### With Existing Modules ###

In the event an r10k control repo is used to define the environment, nimbus may be used for classification and data while referencing the environment r10k sets up.

    r10k puppetfile install /path/to/prod/Puppetfile
    puppet module install tse/nimbus
    curl -Lo example.conf http://git.io/vZBXu

r10k of course isn't strictly necessary. Any means of populating the modules will work.

After the modules have been configured, use one of:

    puppet nimbus apply example.conf --modulepath=/path/to/prod/modules

or

    puppet nimbus apply example.conf --environmentpath=/path/to --environment=prod

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
