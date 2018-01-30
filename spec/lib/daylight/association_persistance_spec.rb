require 'spec_helper'

RSpec.describe Daylight::AssociationPersistance do

  class GrandchildPersistanceTestClass < Daylight::API
  end

  class RelatedPersistanceTestClass < Daylight::API
    has_many :grandchildren, class_name: GrandchildPersistanceTestClass
  end

  class PersistanceTestClass < Daylight::API
    has_many :children, class_name: 'RelatedPersistanceTestClass'
    belongs_to :parent, class_name: 'RelatedPersistanceTestClass'

    def parent_id ; 1 ; end
  end

  before do
    data = {id: 1, name: 'test'}
    stub_request(:get, %r{#{PersistanceTestClass.element_path(1)}}).to_return(body: data.to_json)
    stub_request(:get, %r{#{RelatedPersistanceTestClass.element_path(1)}}).to_return(body: data.to_json)
    stub_request(:get, %r{#{RelatedPersistanceTestClass.element_path(2)}}).to_return(body: data.merge(id:2).to_json)
    stub_request(:get, %r{/persistance_test_classes/1/children\.json}).to_return(body: [data, data].to_json)
    stub_request(:get, %r{/related_persistance_test_classes/1/grandchildren\.json}).to_return(body: [data, data].to_json)
  end

  let(:object) { PersistanceTestClass.find(1) }

  describe :changed? do

    it 'returns false if the object is not modified' do
      object.changed?.should be_falsey
    end

    it 'returns true if the object has a field modified' do
      object.name = 'this is a change'

      object.changed?.should be_truthy
    end

    it 'returns true if the object has a modified association' do
      object.parent = RelatedPersistanceTestClass.new

      object.changed?.should be_truthy
    end

    it 'returns true if the object is new' do
      PersistanceTestClass.new.changed?.should be_truthy
    end
  end

  describe :include_child_updates do
    it 'does not include associations if has not been loaded' do
      hash = object.serializable_hash
      hash['parent_attributes'].should be_nil
      hash['children_attributes'].should be_nil
    end

    it 'includes the single belongs_to/has_one assocation if it has changed' do
      object.parent.should_not be_nil
      object.parent.name = 'updated name'
      hash = object.serializable_hash
      hash['parent_attributes'].should be_present
    end

    it 'includes all children in a has_many type relation if any of them have changed' do
      object.children.should be_present
      object.children[0].name = 'updated name'

      hash = object.serializable_hash
      hash['children_attributes'].count.should == 2
    end

    it 'does not include the association attribute if nothing has changed in the collection' do
      object.children.should be_present

      hash = object.serializable_hash
      hash.should_not have_key('children_attributes')
    end

    it 'does not include the single child if it has not changed' do
      object.parent.should be_present

      hash = object.serializable_hash
      hash.should_not have_key('parent_attributes')
    end

    it 'still includes associations when there is a new child object' do
      object.children.should be_present
      object.children << RelatedPersistanceTestClass.new
      object.children.count.should == 3

      hash = object.serializable_hash
      hash['children_attributes'].count.should == 3
    end

    it 'still includes associations when an additional persisted child object is added' do
      object.children.should be_present
      object.children << RelatedPersistanceTestClass.find(1)
      object.children.count.should == 3

      hash = object.serializable_hash
      hash['children_attributes'].count.should == 3
    end

    it 'still includes has_one associations when persisted child object is set' do
      object.parent.should be_present
      object.parent = RelatedPersistanceTestClass.find(2)

      hash = object.serializable_hash
      hash['parent_attributes'].should be_present
    end

    it 'does not include has_one associations when it is replaced with the same object' do
      object.parent.should be_present
      object.parent = RelatedPersistanceTestClass.find(1)

      hash = object.serializable_hash
      hash['parent_attributes'].should_not be_present
    end

    it 'handles grandchild modifications' do
      object.children[0].grandchildren[0].name = 'updated name'
      hash = object.serializable_hash
      hash['children_attributes'][0]['grandchildren_attributes'][0]['name'].should == 'updated name'
    end
  end

end
