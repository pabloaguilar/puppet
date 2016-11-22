Puppet::Type.newtype(:github) do
  @doc = "Manages GitHub repositories"

	# TODO(lhchavez): Make this support ensure => latest.
  ensurable

  newparam(:path, :namevar => true) do
    desc "Path of the checkout"
  end

	newparam(:repo) do
		desc "The repository"
		isrequired
	end

	newparam(:origin) do
		desc "The name of the origin"
		defaultto 'upstream'
	end

	newparam(:branch) do
		desc "The branch to clone"
		defaultto 'master'
	end

  newparam(:owner) do
    desc "The file's owner"
		isrequired
  end

  newparam(:group) do
    desc "The file's owner"
		isrequired
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
