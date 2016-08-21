require File.join(File.dirname(__FILE__), '..', 'dbmigrate')

Puppet::Type.type(:dbmigrate).provide(:mysql, :parent => Puppet::Provider::DbMigrate) do
  desc "Applies a database migration with MySQL"

  commands :python3 => "/usr/bin/python3"

  def exists?
    output = execute([command(:python3),
                      "#{resource[:name]}/stuff/db-migrate.py", defaults_file,
                      'exists'], { :failonfail => false })
    return output.exitstatus == 0
  end

  def latest?
    output = execute([command(:python3),
                      "#{resource[:name]}/stuff/db-migrate.py", defaults_file,
                      'latest'], { :failonfail => false })
    return output.exitstatus == 0
  end

  def migrate
    args = ["#{resource[:name]}/stuff/db-migrate.py", defaults_file,
            'migrate']
    if resource[:development_environment]
      args += ['--development-environment']
    end
    python3(args)
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
