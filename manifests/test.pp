class solo::test (
  $arg1 = undef,
  $arg2 = undef,
  $arg3 = undef,
) {

  [$arg1, $arg2, $arg3].each |$arg| {
    if $arg != undef {
      notify { "received ${arg}": }
    }
  }

  notify { 'solo::test': }
}
