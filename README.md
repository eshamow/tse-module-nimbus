# Workstation #

This module provides a new Puppet command, `puppet workstation`.

## Examples ##

    puppet workstation enable
    puppet workstation configure

## Directory structure

    --environmentpath
    --environment

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


    # workstation.conf
    classes: [
      "git",
      "caffeine",
    ]

    data: {
      "git::version": "2.5.0",
      "caffeine::default_duration": "1h",
    }
