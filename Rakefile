require 'bundler/gem_tasks'
require 'rake/testtask'
#require 'rspec/core/rake_task'
#
#
#RSpec::Core::RakeTask.new(:test) do |t|
#  t.name = :test
#  t.pattern = 'spec/**/*_spec.rb'
#  t.rspec_opts = '-w --color --require spec_helper'
#end

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
end

desc "Run tests"
task :default => :test

