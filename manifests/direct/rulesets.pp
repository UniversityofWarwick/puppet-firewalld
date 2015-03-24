
# It's highly recommended to include this class when using
# any of the firewalld_direct_* types or the firewalld::direct::ruleset
# resource, as it purges unmanaged rules. Otherwise changing and removing
# rules would leave orphaned rules lying around. BUT be aware that this
# means your direct config is now completely managed and any manually-added
# stuff will be removed!
class firewalld::direct::rulesets(
  Boolean $purge = true
) {

  if $purge {
    resources { 'firewalld_direct_rule' :
      purge => true,
    }
    resources { 'firewalld_direct_chain' :
      purge => true,
    }
  }

}
