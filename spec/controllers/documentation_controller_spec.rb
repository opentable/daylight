require 'spec_helper'

RSpec.describe DaylightDocumentation::DocumentationController, type: :controller do

  class TestModel < ActiveRecord::Base
  end

  it "renders an index" do
    get :index, params: {use_route: :daylight}

    assert_response :success

    assigns[:models].should include(TestModel)
  end

  it "renders a model view" do
    get :model, params: {model: 'test_model', use_route: :daylight}

    assert_response :success

    assigns[:model].should == TestModel
  end

end
