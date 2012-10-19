module Her
  module Model
    # This module adds relationships to models
    module Relationships
          
      # Return @her_relationships, lazily initialized with copy of the
      # superclass' her_relationships, or an empty hash.
      # @private
      def relationships # {{{
        @her_relationships ||= begin
          if superclass.respond_to?(:relationships)
            superclass.relationships.dup
          else
            {}
          end
        end
      end # }}}

      # Parse relationships data after initializing a new object
      # @private
      def parse_relationships(data) # {{{
        relationships.each_pair do |type, definitions|
          definitions.each do |relationship|
            name = relationship[:name]
            klass = self.nearby_class(relationship[:class_name])
            next if !data.include?(name) or data[name].nil?
            data[name] = case type
              when :has_many
                Her::Model::ORM.initialize_collection(klass, :data => data[name])
              when :has_one, :belongs_to
                klass.new(data[name])
              else
                nil
            end
          end
        end
        data
      end # }}}

      # Define an *has_many* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     has_many :articles
      #   end
      #
      #   class Article
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.articles # => [#<Article(articles/2) id=2 title="Hello world.">]
      #   # Fetched via GET "/users/1/articles"
      def has_many(name, attrs={}) # {{{

        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :path => "/#{name}"
        }.merge(attrs)

        (relationships[:has_many] ||= []) << attrs
        
        if attrs.has_key? :active_record 
          active_record_finder attrs
        else
          has_many_finder attrs
        end

      end

      def active_record_finder(attrs={})
        ## TODO: refactor vars
        parent = self
        child  = self.nearby_class(attrs[:class_name])

        if attrs.has_key? :as 
          find_by_polymorphic_id(parent, child, attrs[:as]) 
        else
          find_by_parent_id(parent,child)
        end
        find_parent_by_child_id(parent,child)
      end

      def find_by_polymorphic_id(parent, child, foreign_key_name)
        define_method("#{child.name.pluralize.underscore}") do 
          child.send(:where, {foreign_key_name.to_s.foreign_key.to_sym => id, "#{foreign_key_name}_type".to_sym => parent.name})
        end

        child.class_eval do
          define_method(foreign_key_name)  do
            child_model = self.send("#{foreign_key_name}_type")
            child_model.constantize.find(self.send(foreign_key_name.to_s.foreign_key.to_sym))
          end
        end
      end

      def find_by_parent_id(parent, child)
        define_method("#{child.name.pluralize.underscore}") do 
          child.send(:where, {"#{parent.name.foreign_key}" => id})
        end
      end

      def find_single_by_parent_id(parent, child)
        define_method("#{child.name.underscore}") do 
          child.send(:where, {"#{parent.name.foreign_key}" => id}).first
        end
      end

      def find_parent_by_child_id(parent, child)
        ##  find belongs_to by a has_many
        child.class_eval do 
          define_method("#{parent.name.singularize.underscore}") do 
            parent.find(self.send(parent.name.foreign_key.to_sym))
          end
        end
      end
 
      def has_many_finder(attrs={})
          define_method(attrs[:name]) do |*method_attrs|

            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])

            if method_attrs.any?
              klass.get_collection("#{self.class.build_request_path(method_attrs.merge(:id => id))}#{attrs[:path]}")
            else
              @data[name] ||= klass.get_collection("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
            end
          end
      end # }}}

      # Define an *has_one* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     has_one :organization
      #   end
      #
      #   class Organization
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.organization # => #<Organization(organizations/2) id=2 name="Foobar Inc.">
      #   # Fetched via GET "/users/1/organization"
      def has_one_finder_ar(attrs={})
        parent = self
        child = self.nearby_class(attrs[:class_name])

        find_single_by_parent_id(parent, child)

        find_parent_by_child_id(parent, child)

      end

      def blew
        define_method(name.to_s) do
          ## add Channel.find_by_organization_id(self.id) to Organization instance
          unless attrs[:as]
            klass.send("find_by_#{sklass.name.downcase}_id",id) 
          else
            as = attrs[:as]
            method = :where # attrs[:via][:method]
            id_field = "#{as}_id".to_sym # attrs[:via][:id]
            owner = "#{as}_type".to_sym # attrs[:via].key(self.class.name)

            klass.send(method, {id_field => id, owner => self.class.name})
          end
        end
        klass.class_eval do
          define_method(sklass.name.downcase)  do
            ## add Organization.find(organization_id) to Channel instance
            unless attrs[:as]
              sklass.find(self.send("#{sklass.name.downcase}_id"))
            else
              sklass.find(self.send("#{attrs[:as]}_id"))
            end
          end
        end
      end

      def has_one(name, attrs={}) # {{{
        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :path => "/#{name}"
        }.merge(attrs)
        (relationships[:has_one] ||= []) << attrs

        if attrs.has_key? :active_record
          has_one_finder_ar attrs
        else
          has_one_finder attrs
        end
      end

      def has_one_finder
        define_method(name) do |*method_attrs|
          method_attrs = method_attrs[0] || {}
          klass = self.class.nearby_class(attrs[:class_name])
          if method_attrs.any?
            klass.get_resource("#{self.class.build_request_path(method_attrs.merge(:id => id))}#{attrs[:path]}")
          else
            @data[name] ||= klass.get_resource("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
          end
        end
      end # }}}

      # Define a *belongs_to* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     belongs_to :team, :class_name => "Group"
      #   end
      #
      #   class Group
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.team # => #<Team(teams/2) id=2 name="Developers">
      #   # Fetched via GET "/teams/2"


      def belongs_to(name, attrs={}) # {{{
        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :foreign_key => "#{name}_id",
          :path => "/#{name.to_s.pluralize}/:id"
        }.merge(attrs)
        (relationships[:belongs_to] ||= []) << attrs

        define_method(name) do |*method_attrs|
          method_attrs = method_attrs[0] || {}
          klass = self.class.nearby_class(attrs[:class_name])
          if method_attrs.any?
            klass.get_resource("#{klass.build_request_path(method_attrs.merge(:id => @data[attrs[:foreign_key].to_sym]))}")
          else
            @data[name] ||= klass.get_resource("#{klass.build_request_path(:id => @data[attrs[:foreign_key].to_sym])}")
          end
        end
      end # }}}

      # @private
      def relationship_accessor(type, attrs) # {{{
        name = attrs[:name]
        class_name = attrs[:class_name]
        define_method(name) do
          klass = self.class.nearby_class(attrs[:class_name])
          @data[name] ||= klass.get_resource("#{klass.build_request_path(attrs[:path], :id => @data[attrs[:foreign_key].to_sym])}")
        end
      end # }}}
    end
  end
end
