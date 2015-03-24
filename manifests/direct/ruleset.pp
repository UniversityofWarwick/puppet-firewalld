
# Defines a firewalld set of rules that allow a given
# set of IP addresses/subnets to access a given port range.
# It does this by creating a chain to hold them, which is
# linked from the main INPUT chain.
define firewalld::direct::ruleset(
  Enum[present,absent] $ensure = present,
  Array $sources,
  Integer $start_port,
  Integer $end_port = $start_port,
) {

  if !defined(Class[firewalld::direct::rulesets]) {
    fail "You need to include the firewalld::direct::rulesets class to delcare a ruleset"
  }
  
  $chain_name = "AUTO_${title}_IN"

  $chain_title = "ipv4 filter ${chain_name}"

  firewalld_direct_chain { $chain_title :
    chain => $chain_name,
    ensure => $ensure,
  }

  firewalld_direct_rule { "ipv4 filter INPUT 0 -j ${chain_name}" :
    ensure => $ensure,
    chain => 'INPUT',
    rule  => "-j ${chain_name}",
  }

  $sources.map |$source| {
    $proto = tcp
    $port_spec = ($start_port == $end_port) ? {
      true  => $start_port,
      false => "${start_port}:${end_port}",
    }
    $rule = "-m ${proto} -p ${proto} -s ${source} --dport ${port_spec} -j ACCEPT"
    firewalld_direct_rule { "ipv4 filter ${chain_name} 0 ${rule}" :
      ensure => $ensure,
      priority => 0,
      chain => $chain_name,
      rule  => $rule
    }
  }

  if $ensure == absent {
    # Dependencies are backwards when removing, so that rules are removed before the chain that they reference.
    Firewalld_direct_chain[$chain_title] <- Firewalld_direct_rule["ipv4 filter INPUT 0 -j ${chain_name}"]
    Firewalld_direct_chain[$chain_title] <- Firewalld_direct_rule<| chain == $chain_name |>
  } else {
    Firewalld_direct_chain[$chain_title] -> Firewalld_direct_rule["ipv4 filter INPUT 0 -j ${chain_name}"]
    Firewalld_direct_chain[$chain_title] -> Firewalld_direct_rule<| chain == $chain_name |>
  }

}
