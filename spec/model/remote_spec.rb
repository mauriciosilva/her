require "spec_helper.rb"

describe Her::Model::Remote do
  context "setting relationships without details" do
    before do 
      spawn_model "Organization"
      spawn_active_record_model "Channel"
    end 

    it "handles a single 'has_many' relationship" do 
      Organization.has_many :workgroups
      Organization.relationships[:has_many].should == [
        { :name => :workgroups, :class_name => "Workgroup", :path => "/workgroups" }]
    end 
    
    context "Parent class associations" do 
      before do 
        Organization.has_many :channels, :active_record => true
      end

      it "handles an active record has_many relationship" do 
        Organization.relationships[:has_many].should == [ 
          { :name => :channels, :class_name => "Channel", :path => "/channels", :active_record => true }]
      end
      it 'adds some finder methods' do 
        Organization.instance_methods.include?(:channels).should == true
      end

      it 'sets finders on the child class' do 
        Channel.instance_methods.include?(:organization).should == true
      end

      it 'handles attrs in the association macro' do 
        Organization.has_many :settings, :as => :owner
      end

    end
  end
end


