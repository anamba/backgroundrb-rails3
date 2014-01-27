require 'rake'
require 'rubygems'
require 'rake/testtask'
require 'rdoc/task'
#require 'spec/rake/spectask'
#require 'rspec_helper'
require 'rspec/core/rake_task'
require 'rake/contrib/sshpublisher'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the backgroundrb plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

desc "Run all specs"
#Spec::Rake::SpecTask.new('specs') do |t|
RSpec::Core::RakeTask.new('specs') do |t|
  t.rspec_opts = ["--format", "specdoc"]
  #t.libs = ['lib', 'server/lib' ]
  t.pattern = FileList['specs/**/*_spec.rb']
end

desc "RCov"
task :rcov do
  sh("rcov test/**/*.rb")
end

desc 'Generate documentation for the backgroundrb plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc/output/manual'
  rdoc.title    = 'Backgroundrb'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/backgroundrb/*.rb')
  rdoc.rdoc_files.include('server/*.rb')
  rdoc.rdoc_files.include('server/lib/*.rb')
  rdoc.template = 'jamis'
end

module Rake
  class BackgrounDRbPublisher <  SshDirPublisher
    attr_reader :project, :proj_id, :user
    def initialize(projname, user)
      super(
            "#{user}@rubyforge.org",
            "/var/www/gforge-projects/backgroundrb",
            "doc/output")
    end
  end
end

desc "Publish documentation to Rubyforge"
task :publish_rdoc => [:rdoc] do
  user = ENV['RUBYFORGE_USER']
  publisher = Rake::BackgrounDRbPublisher.new('backgroundrb', user)
  publisher.upload
end

namespace :git do
  def current_branch
    branches = `git branch`
    return branches.split("\n").detect {|x| x =~ /^\*/}.split(' ')[1]
  end

  desc "Push changes to central git repo"
  task :push do
    sh("git push origin master")
  end

  desc "update master branch"
  task :up do
    t_branch = current_branch
    sh("git checkout master")
    sh("git pull")
    sh("git checkout #{t_branch}")
  end

  desc "rebase current branch to master"
  task :rebase => [:up] do
    sh("git rebase master")
  end

  desc "merge current branch to master"
  task :merge => [:up] do
    t_branch = current_branch
    sh("git checkout master")
    sh("git merge #{t_branch}")
    sh("git checkout #{t_branch}")
  end

  desc "commot current branch"
  task :commit => [:merge] do
    t_branch = current_branch
    sh("git checkout master")
    sh("git push origin master")
    sh("git checkout #{t_branch}")
  end
end

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "backgroundrb-rails3"
  gem.homepage = "http://github.com/anamba/backgroundrb-rails3"
  gem.license = "MIT"
  gem.summary = %Q{BackgrounDRb is a Ruby job server and scheduler.}
  gem.description = %Q{
    BackgrounDRb is a Ruby job server and scheduler. Its main intent is to be used with Ruby on Rails applications for offloading long-running tasks. 
    Since a Rails application blocks while serving a request it is best to move long-running tasks off into a background process that is divorced from http request/response cycle.
    This is the RoR 3 version (Railtie based) of the gem. Please read the GitHub homepage for installation instructions.
  }
  gem.email = "aaron@biggerbird.com"
  gem.authors = ["Matteo Latini", "Aaron Namba"]
  gem.version = "1.1.7"
end
Jeweler::RubygemsDotOrgTasks.new
