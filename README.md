# Singleton #

*TODO:* come up with a snazzier name or commit to the name "singleton".

This module provides a new Puppet command, `puppet singleton`.

When `puppet singleton configure` is run, Puppet will set the runtime
$environmentpath to $singleton_environmentpath, set the runtime $environment
to $singleton_environment, and read $singleton_config. A custom node
terminus will be switched to that reads classes from the `classes` config key.
A custom data terminus will be used to bind data from the `data` config key.
The $singleton_environment will be populated to match the modules defined in
the `modules` config key. With this configuration primed, Puppet will be run.

The end result is that users may define a single text file that lists all the
modules they want, the data they want, and the classes they want applied to
their local machine. They may then use the `puppet singleton` command to
easily puppetize their system from that input.

Note that alternatively, a confdir may be specified, in which case all .conf
files inside the confdir will be read and merged into a compositional
configuration. This allows for things such as starting from a common
configuration and adding in personal customization by including an additional
file.

New users can get started with a config provided by their company or team.

    puppet module install tse/singleton
    puppet singleton get http://company.com/puppet-singleton.conf
    puppet singleton configure

## Examples ##

Assume that the Puppet AIO package has just been installed and nothing else.
This is an example of bootstrapping a singleton configuration. Try it!

    puppet module install tse/singleton
    curl -Lo example.conf http://git.io/vs1kv
    puppet singleton --singleton-config=example.conf modules install
    puppet singleton --singleton-config=example.conf configure

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
    `-- singleton_environments/    # $singleton_environmentpath
        `-- default                  # $singleton_environment
            |-- manifests/
            |   `-- site.pp
            |-- modules/
            `-- hieradata/

    $confdir/
    `-- singleton/               # $singleton_confdir
        `-- singleton.conf         # $singleton_config

## Configuration File ##

    # singleton.conf (hocon)
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

## Options ##

### `--singleton-config <path>` ###

The path to a Hocon configuration file specifying classes, data, and/or modules
to use in singleton configuration.

### `--singleton-confdir <path>` ###

The path to a directory containing one or more `*.conf` Hocon configuration
files, each of which may specify classes, data, or modules. All the `*.conf`
files in this directory will be read, merged, and the result used in singleton
configuration.

### `--singleton-environment <name>` ###

Puppet singleton uses environments just like Puppet. This flag sets the name of
the environment the run will use.

### `--singleton-environmentpath <path>` ###

Puppet singleton typically uses a subcommand-specific environmentpath. This
flag allows you to set the path used explicitly. It may be useful if you have
manually installed modules or created an environment you want the command to
use.

## Old Ideas ##

    puppet singleton-environment add --source <uri> --name <name> [--singleton-environmentpath <path>]
    puppet singleton-environment delete --name <name> [--singleton-environmentpath <path>]
    puppet singleton-environment list [--singleton-environmentpath <path>]
