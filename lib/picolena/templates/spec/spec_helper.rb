# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

def revert_changes!(file,content)
  File.open(file,'w'){|might_have_been_modified|
    might_have_been_modified.write content
  }
end

module Spec
  module Matchers
    class Change
      alias_method :evaluate_value_proc, :evaluate_value_proc_without_ensured_evaluation_of_proxy
    end
  end
end
