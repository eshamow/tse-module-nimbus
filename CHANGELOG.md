# Change Log

## 0.7.1 (2016-02-16)

Bug Fixes:

  - Corrected how hocon gem was being required for compatibility with version 1.0.0 of the gem and newer.

## 0.7.0 (2015-11-30)

New Features:

  - Added "variables" key to config file. The variables key can be used to provide static variables which will be available to Puppet in top scope, similar to facts.

Improvements:

  - Added support Hocon config files using substitution. Previously trying to parse a file that contained substitution would cause an error.

## 0.6.4 (2015-11-28)

Improvements:

  - Updated README to remove known issue note about puppet:// uris not working correctly
  - Added CHANGELOG

## 0.6.3 (2015-11-26)

Bug Fixes:

  - Resolved issue wherein Puppet file resources with a source parameter set to a puppet:// uri value would not function correctly under Nimbus
