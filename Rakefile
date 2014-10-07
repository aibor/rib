require 'bundler/gem_tasks'
require 'rspec/core/rake_task'


RSpec::Core::RakeTask.new(:test) do |t|
  t.name = :test
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = '-w --color --require spec_helper'
end


desc "Run tests"
task :default => :test

