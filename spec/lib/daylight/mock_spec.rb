# require 'spec_helper'
# require 'daylight/mock'
#
# RSpec.describe Daylight::Mock do
#   class Minitest::Spec ; end
#   class Minitest::Test ; end
#
#   class TestClient < Daylight::API
#     has_many :test_client_children, class_name: 'TestClientChild'
#   end
#
#   class TestClientChild < Daylight::API ; end
#
#   # All clients will do this in their spec_helper.rb/test_helper.rb
#   Daylight::Mock.setup
#
#   describe 'return values' do
#     describe 'show' do
#       it "returns a single object of the correct type" do
#         TestClient.find(1).should be_instance_of(TestClient)
#       end
#
#       it "has the correct ID" do
#         TestClient.find(1).id.should == 1
#       end
#     end
#
#     describe 'index' do
#       it "returns a list of objects of the correct type" do
#         results = TestClient.find(:all)
#         results.should respond_to(:size)
#         results.first.should be_instance_of(TestClient)
#       end
#
#       it "seeds the objects with ids" do
#         TestClient.find(:all).all? {|z| z.id.present? }.should be_truthy
#       end
#
#       it "seeds the objects with any filters" do
#         TestClient.where(foo: 'bar').all? {|z| z.foo == 'bar' }.should be_truthy
#       end
#     end
#
#     describe 'associated' do
#       it "returns a list of objects of the associated type" do
#         results = TestClient.find(1).test_client_children
#         results.should respond_to(:size)
#         results.first.should be_instance_of(TestClientChild)
#       end
#
#       it "seeds the responses with ids" do
#         TestClient.find(1).test_client_children.all? {|z| z.id.present? }.should be_truthy
#       end
#
#       it "seeds the objects with any filters" do
#         TestClient.find(1).test_client_children.where(foo: 'bar').all? {|z| z.foo == 'bar' }.should be_truthy
#       end
#     end
#
#     describe 'update' do
#       it "returns a new object with the updated attributes" do
#         object = TestClient.find(1)
#         object.update_attributes(name: 'wibble').should be_truthy
#       end
#     end
#
#     describe 'patch' do
#       let(:data) { {test_client: {name: 'wibble'}}.to_json }
#
#       it "updates the attributes" do
#         object = TestClient.find(1)
#         object.patch(:test, {}, data).should be_truthy
#       end
#     end
#
#     describe 'create' do
#       it "returns the created object" do
#         object = TestClient.new(name: 'foo')
#         object.name = 'foo'
#         object.save.should be_truthy
#         object.id.should_not be_nil
#       end
#     end
#
#     describe 'destroy' do
#       it "returns a new object with the updated attributes" do
#         object = TestClient.find(1)
#         object.destroy.should be_truthy
#       end
#     end
#   end
#
#   describe 'recorder' do
#     it "keeps track of call counts across actions" do
#       TestClient.find(123)
#       TestClient.find(456)
#
#       daylight_mock.shown(:test_clients).count.should == 2
#     end
#
#     it "keeps track of the requests" do
#       TestClient.find(:all)
#
#       daylight_mock.indexed(:test_client).first.request.method.should == :get
#     end
#
#     it "keeps track of the responses" do
#       object = TestClient.find(1)
#       object.update_attributes(name: 'wibble')
#
#       daylight_mock.updated(:test_client).first.status.should == 201
#     end
#
#     it "returns the last response" do
#       TestClient.find(123)
#       TestClient.find(456)
#
#       daylight_mock.last_shown(:test_clients).response.id.should == 456
#     end
#
#     describe :target_object do
#       it "sets the target_object value for examination on update" do
#         object = TestClient.find(1)
#         object.update_attributes(code: 'wibble')
#
#         daylight_mock.last_updated(:test_clients).target_object.code.should == 'wibble'
#       end
#
#       it "sets the target_object value for examination on create" do
#         object = TestClient.new(code: 'foo')
#         object.name = 'foo'
#         object.save.should be_truthy
#
#         daylight_mock.last_created(:test_clients).target_object.code.should == 'foo'
#       end
#     end
#   end
#
#   describe 'minitest setup' do
#     let(:minitest) { Minitest::Test.new(:foo) rescue MiniTest::Test.new }
#
#     it "adds our mock methods to Minitest::Test" do
#       minitest.should respond_to(:daylight_mock)
#     end
#
#     it "captures API requests" do
#       minitest.should_receive(:stub_request).and_return stub_request(:any, /.*/)
#       minitest.before_setup
#     end
#   end
# end
