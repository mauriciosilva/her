require "spec_helper.rb"

describe Her::Model::Remote do
  context "setting relationships without details" do
    before do 
      spawn_model "Organization"
      spawn_active_record_model "Agent"
    end 

    it "handles a single 'has_many' relationship" do 
      Organization.has_many :workgroups
      Organization.relationships[:has_many].should == [
        { :name => :workgroups, :class_name => "Workgroup", :path => "/workgroups" }]
    end 

    it "handles an active record relationship" do 
      Organization.has_many :agents, :active_record => false
      Organization.relationships[:has_many].should == [ 
        { :name => :agents, :class_name => "Agent", :path => "/agents", :active_record => false }]
      Organization.instance_methods.include?(:agents).should == true
    end
  end
end


