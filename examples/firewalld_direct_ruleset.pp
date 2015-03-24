# How to use firewalld_direct_ruleset to open a port to some addresses
# outside of the normal firewalld zone-service configuration.


firewalld_direct_ruleset { 'elasticsearch-http' :
  start_port => 8200,
  end_port   => 8300,
  sources    => [
    '10.7.8.0/24',
    '10.7.9.0/24'
  ]
}

# To remove a previously added ruleset
# The title of the resource is used in the comment of the rules
# in order to look them up later, so you shouldn't change the
# resource name after creation or you'll end up with duplicate rules.
firewalld_direct_ruleset { 'service-x' :
  ensure => absent
}