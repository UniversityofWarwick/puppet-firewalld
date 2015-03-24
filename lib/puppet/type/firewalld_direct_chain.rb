
# Manages a chain element in the firewalld direct mode.
Puppet::Type.newtype(:firewalld_direct_chain) do
  desc "Describes a <chain> in firewalld direct mode"

  ensurable

  newproperty(:chain) do
    desc "The chain name"
    validate do |value|
      raise ArgumentError.new "Chain name must be less than 29 chars" if value.length > 28
    end
    newvalues(/[a-zA-Z_]+/)
  end 

  newparam(:name, :namevar => true) do
  end

  newproperty(:table) do
    desc "The table this chain is in"
    defaultto 'filter'
  end

  newproperty(:ipv) do
    desc "The IP version"
    defaultto :ipv4
    newvalues(:ipv4, :ipv6, :eb)
  end

end
