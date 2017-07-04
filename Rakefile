require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs = %w(lib spec)
  t.pattern = 'spec/**/*_spec.rb'
end

task default: :test
