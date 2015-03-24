
# Manages a rule element in the firewalld direct mode.
# Note: although the name of the resource is unique in the Puppet catalog,
#  it doesn't actually exist on the system so you have to be careful not to
#  define two separate resources with the exact same properties, as they'll
#  map to the same rule on the system. This is mainly fine as rules are immutable,
#  so a change to a rule is really a new rule.
Puppet::Type.newtype(:firewalld_direct_rule) do
  desc "Describes a <rule> in firewalld direct mode"

  ensurable

  newparam(:name, :namevar => true) do
    desc "The rule name"
    newvalues(/[a-zA-Z_]+/)
  end

  newproperty(:table) do
    desc "The table this rule is in"
    defaultto 'filter'
    newvalues(/.+/)
  end

  newproperty(:ipv) do
    desc "The IP version"
    defaultto :ipv4
    newvalues(:ipv4, :ipv6, :eb)
  end

  newproperty(:rule) do
    desc "The actual rule options"
  end

  newproperty(:chain) do
    desc "The chain that the rule is part of"
    newvalues(/.+/)
  end

  newproperty(:priority) do
    desc "The priority of the rule"
    defaultto 0
    newvalues(/\d+/)
  end

end
