require 'spec_helper.rb'

describe Her::Model::Remote do
  before do 
    spawn_model               'Organization'
    spawn_active_record_model 'FbAppConfig'
  end
  
  context 'API => AR' do
    context 'belongs_to' do
      it 'when declared defines a method to access the parent object' do
        Organization.belongs_to :fb_app_config
        Organization.instance_methods.include?( :fb_app_config ).should be_true
      end

      it 'without additional attributes the "child" belongs_to "parent" object' do
      end
    end

    context 'has_one' do
      it 'when declared defines a method to access the child object' do
        Organization.has_one :fb_app_config, :active_record => true
        Organization.instance_methods.include?( :fb_app_config ).should be_true
      end

      it 'when declared defines a method to access the child object' do
        Organization.has_one :fb_app_config, :through => :fb_app_configs_organizations, :active_record => true
        Organization.instance_methods.include?( :fb_app_config ).should be_true
      end

      it 'without additional attributes the "parent" has_one "child" object' do
      end
    end

    context 'has_many' do
    end
  end
end


