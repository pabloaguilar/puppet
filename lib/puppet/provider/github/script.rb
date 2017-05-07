require File.join(File.dirname(__FILE__), '..', 'github')
require 'pathname'

Puppet::Type.type(:github).provide(:git, :parent => Puppet::Provider::GitHub) do
  desc "Manages git repositories"

  commands :git => "/usr/bin/git"

  def exists?
    return Pathname(@resource[:path]).join('.git').directory?
  end

  def latest?
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'fetch', '-q',
               @resource[:origin], @resource[:branch]],
              { :failonfail => true, :uid => uid, :gid => gid })
      head, fetch_head = execute([command(:git), 'rev-parse',
                                  'HEAD^{commit}', 'FETCH_HEAD^{commit}'],
                                 { :failonfail => true, :uid => uid,
                                   :gid => gid }).lines()
      return head == fetch_head
    end
  end

  def reset
    if !exists?
      create
      return
    end
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'fetch', '-q',
               @resource[:origin], @resource[:branch]],
              { :failonfail => true, :uid => uid, :gid => gid })
      execute([command(:git), 'reset', '--hard', 'FETCH_HEAD^{commit}'],
              { :failonfail => true, :uid => uid, :gid => gid })
      execute([command(:git), 'submodule', 'update', '--init', '--recursive'],
             { :failonfail => true, :uid => uid, :gid => gid })
    end
  end

  def create
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'clone',
             "https://github.com/#{@resource[:repo]}.git",
             '-o', @resource[:origin], '-b', @resource[:branch], '.'],
             { :failonfail => true, :uid => uid, :gid => gid })
      execute([command(:git), 'submodule', 'update', '--init', '--recursive'],
             { :failonfail => true, :uid => uid, :gid => gid })
    end
  end

  def destroy
    FileUtils.remove_dir(@resource[:path])
  end

  def uid
    Etc.getpwnam(@resource[:owner]).uid
  end

  def gid
    Etc.getgrnam(@resource[:group]).gid
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
