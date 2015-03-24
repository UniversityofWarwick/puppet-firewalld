class Puppet::Provider::Firewalld < Puppet::Provider

  # Prefetch xml data.
  def self.prefetch(resources)
    debug("[prefetch(resources)]")
    Puppet.debug "firewalld prefetch instance: #{instances}"
    instances.each do |prov|
      Puppet.debug "firewalld prefetch instance resource: (#{prov.name})"
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # Matches up existing known resources (`instances`) with the declared resources.
  # Normally this is a simple name match, but as chains don't have names and are only
  # really defined by their attributes, we need to compare all their values to see
  # when a resource already exists.
  # 
  # Not called automatically - call this from within your prefetch method, e.g.
  #     prefetch_by_property(resources, [:ipv, :table, :chain])
  def self.prefetch_by_property(resources, id_properties)
    instances.each do |instance|
      resources.each do |name, resource|
        instance_namedef = id_properties.map { |prop| instance.send(prop) }.join(' ')
        resource_namedef = id_properties.map { |prop| resource[prop] }.join(' ')
        if instance_namedef == resource_namedef
          resource.provider = instance
        end
      end
    end
  end


  # Clear out the cached values.
  def flush
    @property_hash.clear
  end

  # This allows us to conventiently look up existing status with properties[:foo].
  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end

end
