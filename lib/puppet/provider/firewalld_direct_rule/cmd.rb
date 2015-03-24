
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
Puppet::Type.type(:firewalld_direct_rule).provide :firewall_direct_rule, :parent => Puppet::Provider::Firewalld do
  @doc = "The zone config manipulator"

  commands :firewall => '/bin/firewall-cmd'

  class_variable_set(:@@instances_cache, nil)

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.prefetch(resources)
    prefetch_by_property(resources, [:ipv, :table, :chain, :priority, :rule]) 
  end

  def query(*args)
    execute(['firewall-cmd', args].flatten.compact.join(' '), :failonfail => false)
  end

  def execute_change(*args)
    execute(['firewall-cmd', args].flatten.compact.join(' '))
  end

  def generated_name(props)
    "#{props[:ipv]} #{props[:table]} #{props[:chain]} #{props[:priority]} #{props[:rule]}"
  end

  # This is called to actually flush out all the changes to the system,
  # hopefully in as few firewall-cmd commands as possible.
  def flush
    props = {}
    [:ipv, :table, :chain, :priority, :rule].map do |prop|
      props[prop] = @property_hash[prop] || resource[prop]
    end

    # FIXME resource title has to exactly match generated one. Will fix this when I work out how.
    expected_name = generated_name(props)
    raise ArgumentError.new "Due to a bug in this module, the resource name must be '#{expected_name}' instead of '#{resource[:name]}'." unless expected_name == resource[:name]

    Puppet.debug("Flush: ensure=#{@property_flush[:ensure]}")

    if @property_flush[:ensure] == :absent
      execute_change('--direct', '--remove-rule', props[:ipv], props[:table], props[:chain], props[:priority], props[:rule])
      @property_hash.clear
      @property_hash[:ensure] = :absent
    else 
      execute_change('--direct', '--add-rule', props[:ipv], props[:table], props[:chain], props[:priority], props[:rule])
    end

    self.class.class_variable_set(:@@instances_cache, nil)
  end

  def self.instances
    class_variable_set(:@@instances_cache, get_instances) unless class_variable_get(:@@instances_cache)
    class_variable_get(:@@instances_cache)
  end

  def self.get_instances
    firewall_lines('--direct', '--get-all-rules').map do |line|
      parts = line.split(/\s+/)
      ipv = parts.shift
      table = parts.shift
      chain = parts.shift
      priority = parts.shift
      rule = parts.join(' ')

      new({
          :name   => line,
          :ensure => :present,
          :ipv    => ipv,
          :table  => table,
          :chain  => chain,
          :priority => priority,
          :rule   => rule
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
