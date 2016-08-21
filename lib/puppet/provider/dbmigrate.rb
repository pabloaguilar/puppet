class Puppet::Provider::DbMigrate < Puppet::Provider
  def self.defaults_file
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      "--config-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end

  def defaults_file
    self.class.defaults_file
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
