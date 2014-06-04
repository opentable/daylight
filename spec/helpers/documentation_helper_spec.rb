require 'spec_helper'

describe Daylight::DocumentationHelper do
  include Daylight::DocumentationHelper

  class TestModel < ActiveRecord::Base
    include Daylight::Associations

    has_many :users
  end

  describe :model_verbs_and_routes do
    it "yields the route verb, path, and defaults hash for the model" do
      yielded = false
      verbs = %w[GET POST PUT PATCH DELETE]
      model_verbs_and_routes TestModel do |verb, path, defaults|
        verbs.should include(verb)
        path.to_s.should =~ %r{/test-model}
        defaults.should be_a(Hash)
        yielded = true
      end

      yielded.should be_true
    end
  end

  describe :model_filters do
    it "returns list of the model's filters including attributes" do
      model_filters(TestModel).should include('name')
    end

    it "returns list of the model's filters including associations" do
      model_filters(TestModel).should include('users')
    end
  end

  describe :action_definition do
    it "returns a definition for an action" do
      action_definition({action:'index'}, TestModel).should ==
        "Retrieves a list of test models"
    end

    it "handles associated" do
      action_definition({action:'associated', associated:'foo_bar'}, TestModel).should ==
        "Returns test model's foo bars"
    end

    it "handles remoted" do
      action_definition({action:'remoted', remoted:'baz'}, TestModel).should ==
        "Calls test model's remote method baz"
    end
  end
end