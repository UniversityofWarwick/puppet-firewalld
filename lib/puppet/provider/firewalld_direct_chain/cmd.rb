
require 'puppet'
require 'optparse'
require 'shellwords'
require 'ostruct'
require 'puppet/provider/firewalld'

####
#
# http://garylarizza.com/blog/2013/12/15/seriously-what-is-this-provider-doing/
#
# FIXME resource title has to exactly match the generated one
#
####
Puppet::Type.type(:firewalld_direct_chain).provide :firewall_direct_chain, :parent => Puppet::Provider::Firewalld do
  @doc = "The zone config manipulator"

  commands :firewall => '/bin/firewall-cmd'

  mk_resource_methods

  class_variable_set(:@@instances_cache, nil)

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def query(*args)
    execute(['firewall-cmd', args].flatten.compact.join(' '), :failonfail => false)
  end

  def execute_change(*args)
    execute(['firewall-cmd', args].flatten.compact.join(' '))
  end

  def self.prefetch(resources)
    prefetch_by_property(resources, [:ipv, :table, :chain])
  end

  def generated_name(props)
    "#{props[:ipv]} #{props[:table]} #{props[:chain]}"
  end

    # This is called to actually flush out all the changes to the system,
  # hopefully in as few firewall-cmd commands as possible.
  def flush
    props = {}
    [:ipv, :table, :chain].each do |prop|
      props[prop] = @property_hash[prop] || resource[prop]
    end

    # If chain not explicitly stated, use the name
    props[:chain] ||= resource[:name]

    # FIXME resource title has to exactly match generated one. Will fix this when I work out how.
    expected_name = generated_name(props)
    raise ArgumentError.new "Due to a bug in this module, the resource name must be '#{expected_name}' instead of '#{resource[:name]}'." unless expected_name == resource[:name]

    if resource[:ensure] == :absent
      Puppet.debug("#{self} ensure absent")
      execute_change('--direct', '--remove-chain', props[:ipv], props[:table], props[:chain])
      @property_hash.clear
      @property_hash[:ensure] = resource[:ensure]
    else 
      Puppet.debug("#{self} ensure present")
      execute_change('--direct', '--add-chain', props[:ipv], props[:table], props[:chain])
      @property_hash = resource
    end

    self.class.class_variable_set(:@@instances_cache, nil)
  end

  def self.instances
    class_variable_set(:@@instances_cache, get_instances) unless class_variable_get(:@@instances_cache)
    class_variable_get(:@@instances_cache)
  end

  def self.get_instances
    firewall_lines('--direct', '--get-all-chains').map do |line|
      ipv, table, chain = line.split(/\s+/)

      new({
              :name   => "#{ipv} #{table} #{chain}",
              :chain  => chain,
              :ensure => :present,
              :ipv    => ipv,
              :table  => table,
          })
    end
  end

  # Runs firewall-cmd and splits by line.
  def self.firewall_lines(*args)
    firewall(*args).split(/\r?\n/)
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end
end
