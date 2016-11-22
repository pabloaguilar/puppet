Puppet::Type.newtype(:config_php) do
  @doc = "Adds entries to config.php"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Title of the resource"
  end

  newparam(:path) do
    desc "Path of the config file"
  end

  newparam(:settings) do
    desc "The settings"
  end

  newproperty(:owner) do
    desc "The file's owner"
  end

  newproperty(:group) do
    desc "The file's owner"
  end

  newproperty(:mode) do
    desc "The file's mode"
		defaultto 0644
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
