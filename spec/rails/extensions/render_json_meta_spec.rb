require 'spec_helper'

class AssociatedRenderJsonMetaTest < ActiveRecord::Base
end

class RenderJsonMetaTest < ActiveRecord::Base
  has_many :children, class_name: 'AssociatedRenderJsonMetaTest'

  accepts_nested_attributes_for :children
end

# this implicitly tests read_only attributes
class ActiveModel::Serializer
  binding.pry
  
  def build_json(controller, resource, options)
    # All modules that are included will be able to add to the metadata hash
    binding.pry
    metadata = (options[:meta] || {}).tap do |metadata|
      _add_metadata(resource, metadata)
    end
    options[:meta] = metadata unless metadata.blank?

    super
  end


  ##
  # Default metadata method (a no-op) that does not call `super`
  module MetadataDefault
    def _add_metadata(resource, metadata); end
  end

  ##
  # For AssociationRelations, add known `where_values_hash` to the meta data
  module MetadataWhereValues
    def _add_metadata(resource, metadata)
      if ActiveRecord::AssociationRelation === resource && resource.respond_to?(:where_values_hash)
        metadata[:where_values] = resource.where_values_hash
      end

      super
    end
  end

  ##
  # Returns the `natural_key` for the resource
  module MetadataNaturalKey
    def _add_metadata(resource, metadata)
      _collect_metadata(:natural_key, resource, metadata) do |model|
        model.class.natural_key if model.class.respond_to?(:natural_key) && model.class.natural_key
      end
    end
  end

  ##
  # For AssociationRelations, add known `nested_resource_names` to the meta data
  module MetadataNestedResources
    def _add_metadata(resource, metadata)
      _collect_metadata(:nested_resources, resource, metadata) do |model|
        model.class.nested_resource_names if model.class.respond_to?(:nested_resource_names)
      end

      super
    end
  end

  ##
  # Adds `read_only` attributes from the serializer of the resource, or traverse
  # the AssociationRelation/Relation for each one of the collection's `read_only` attributes
  module MetadataReadOnly
    def _add_metadata(resource, metadata)
      _collect_metadata(:read_only, resource, metadata) do |model|

        serializer = model.try(:active_model_serializer)
        if serializer.respond_to?(:read_only)
          serializer._read_only if serializer.read_only
        end
      end

      super
    end
  end

  private
  def _collect_metadata(key, resource, metadata, &block)
    if ActiveRecord::AssociationRelation === resource || ActiveRecord::Relation === resource
      resource.each { |model| _assign_metadata(key, model, metadata, &block) }
    else
      _assign_metadata(key, resource, metadata, &block)
    end
  end

  def _assign_metadata(attribute_key, resource, metadata)
    class_key = resource.class.name.underscore

    # quick return if attribute is already computed
    return if metadata[class_key] && metadata[class_key][attribute_key]

    if results = yield(resource)
      metadata[class_key] ||= {}
      metadata[class_key].merge!({ attribute_key => results })
    end
  end
end

class RenderJsonMetaTestSerializer < ActiveModel::Serializer
  read_only :name, :valid?

  def valid?; true; end
end

class RenderJsonMetaTestController < ActionController::Base
  # The read_only values will be activated based on Serializer
  def index
    render json: RenderJsonMetaTest.all
  end

  def show
    render json: RenderJsonMetaTest.find(params[:id])
  end

  # AssociatonRelation will activate where_values
  def associated
    render json: RenderJsonMetaTest.find(params[:id]).children.where(name: params[:name])
  end

  def child
    render json: AssociatedRenderJsonMetaTest.find(params[:id])
  end
end



RSpec.describe RenderJsonMeta, type: :controller do

  def self.controller_class
    RenderJsonMetaTestController
  end

  migrate do
    create_table :render_json_meta_tests do |t|
      t.string  :name
    end

    create_table :associated_render_json_meta_tests do |t|
      t.string  :name
      t.integer :render_json_meta_test_id
    end
  end

  before do
    @routes.draw do
      resources :render_json_meta_test do
        get 'associated', on: :member
        get 'child',      on: :member
      end
    end
  end

  before :all do
    FactoryGirl.define do
      factory :render_json_meta_test do
        name { Faker::Name.name }
      end

      factory :associated_render_json_meta_test do
        name { Faker::Name.name }
      end
    end
  end

  after :all do
    Rails.application.reload_routes!
  end

  let!(:record1)    { create(:render_json_meta_test) }
  let!(:record2)    { create(:render_json_meta_test) }
  let!(:associated) { create(:associated_render_json_meta_test, render_json_meta_test_id: record1.id) }

  describe "read_only" do
    it 'renders on record' do
      get :show, id: record1.id
      # tests for no '?' on valid in both the attribute and read_only names
      json = JSON.parse(response.body)
      binding.pry
      json['render_json_meta_test'].keys.should include('valid')
      json['meta']['render_json_meta_test'].should include({'read_only' => ['name', 'valid']})
    end

    it 'renders on collection' do
      get :index

      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'read_only' => ['name', 'valid'] })
    end

    it 'renders no metadata' do
      get :child, id: associated.id

      json = JSON.parse(response.body)
      json.keys.should_not include('meta')
    end
  end

  describe "nested_resources" do
    it 'renders on record' do
      get :show, id: record1.id

      # tests for no '?' on valid in both the attribute and read_only names
      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'nested_resources' => ['children']})
    end

    it 'renders on collection' do
      get :index

      json = JSON.parse(response.body)
      json['meta']['render_json_meta_test'].should include({'nested_resources' => ['children']})
    end

    it 'renders no metadata' do
      get :child, id: associated.id

      json = JSON.parse(response.body)
      json.keys.should_not include('meta')
    end
  end

  it 'renders where_values' do
    get :associated, id: record1.id, name: associated.name

    json = JSON.parse(response.body)
    json['meta']['where_values'].should == {'render_json_meta_test_id' => associated.render_json_meta_test_id , 'name' => associated.name }
  end
end
