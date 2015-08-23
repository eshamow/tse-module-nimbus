# Localhost #

This module provides a new Puppet command, `puppet localhost`.

When `puppet localhost configure` is run, Puppet will set the runtime
$environmentpath to $localhost_environmentpath, set the runtime $environment
to $localhost_environment, and read $localhost_config. A custom node
terminus will be switched to that reads classes from the `classes` config key.
A custom data terminus will be used to bind data from the `data` config key.
The $localhost_environment will be populated to match the modules defined in
the `modules` config key. With this configuration primed, Puppet will be run.

The end result is that users may define a single text file that lists all the
modules they want, the data they want, and the classes they want applied to
their local machine. They may then use the `puppet localhost` command to
easily puppetize their system from that input.

Note that alternatively, a confdir may be specified, in which case all .conf
files inside the confdir will be read and merged into a compositional
configuration. This allows for things such as starting from a common
configuration and adding in personal customization by including an additional
file.

New users can get started with a config provided by their company or team.

    puppet module install tse/localhost
    puppet localhost get http://company.com/puppet-localhost.conf
    puppet localhost configure

## Examples ##

Assume that the Puppet AIO package has just been installed and nothing else.
This is an example of bootstrapping a localhost configuration. Try it!

    puppet module install tse/localhost
    curl -Lo example.conf http://git.io/vswiI
    puppet localhost --localhost-config=example.conf modules install
    puppet localhost --localhost-config=example.conf configure

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
    `-- localhost_environments/    # $localhost_environmentpath
        `-- default                  # $localhost_environment
            |-- manifests/
            |   `-- site.pp
            |-- modules/
            `-- hieradata/

    $confdir/
    `-- localhost/               # $localhost_confdir
        `-- localhost.conf         # $localhost_config

## Configuration File ##

    # localhost.conf (hocon)
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

    puppet localhost-environment add --source <uri> --name <name> [--localhost-environmentpath <path>]
    puppet localhost-environment delete --name <name> [--localhost-environmentpath <path>]
    puppet localhost-environment list [--localhost-environmentpath <path>]
