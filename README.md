# Workstation #

This module provides a new Puppet command, `puppet workstation`.

## Examples ##

    puppet workstation-environment add --source <uri> --name <name> [--workstation-environmentpath <path>]
    puppet workstation-environment delete --name <name> [--workstation-environmentpath <path>]
    puppet workstation-environment list [--workstation-environmentpath <path>]
    puppet workstation configure [--workstation-environment <environment>] [--workstation-config <path>] [--workstation-environmentpath <path>]

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
    `-- workstation/                 # $workstation_confdir
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
