module Her
  module Model
    module Remote
=begin

      ## handles :as => 
      def has_many_ar(name, attrs={})

        append_relationships(name, attrs)

        klass = self.nearby_class(name.to_s.classify)
        sklass = self

        define_method(name.to_s) do
          ## add Channel.find_by_organization_id(self.id) to Organization instance
          unless attrs[:as]
            klass.send(:where, {"#{sklass.name.downcase.to_sym}_id" => id})
          else
          
            as = attrs[:as]
            method = :where # attrs[:via][:method]
            id_field = "#{as}_id".to_sym # attrs[:via][:id]
            owner = "#{as}_type".to_sym # attrs[:via].key(self.class.name)

            klass.send(method, {id_field => id, owner => self.class.name})
          end
            
        end


      ## better syntax?
      def belongs_to_active_record(attrs={})
        belongs_to_class = attrs[:class_name].constantize
        has_many_class   = self

        define_method("#{belongs_to_class.name.underscore}") do 
            belongs_to_class.send(:find, self.send("#{belongs_to_class.name.foreign_key}"))
        end

        belongs_to_class.class_eval do 
          define_method("#{has_many_class.name.tableize}") do 
            has_many_class.get_collection("#{has_many_class.build_querystring_request_path(has_many_class.collection_path,{"#{belongs_to_class.name.foreign_key}".to_sym => id})}")
          end
        end
      end
=end
      def belongs_to_active_record(klass, attrs={})
        belongs_to_class    = self.nearby_class(klass.to_s.classify)
        has_many_class      = self
        ##  find belongs_to by a has_many
        define_method("#{belongs_to_class.name.underscore}") do 
            belongs_to_class.send(:find, self.send("#{belongs_to_class.name.underscore}_id"))
        end
        ##  find has_manies by belongs_to id
        belongs_to_class.class_eval do 
          define_method("imh_#{has_many_class.name.pluralize.underscore}") do 
            has_many_class.get_collection("#{has_many_class.build_querystring_request_path(has_many_class.collection_path,{"#{belongs_to_class.name.underscore}_id".to_sym => id})}")
          end
        end
      end
      def has_many_active_record(klass, attrs={})
      end
    end
  end
end


