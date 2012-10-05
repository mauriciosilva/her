module Her
  module Model
    module Remote
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
        belongs_to_class    = self
        has_many_class      = self.nearby_class(klass.to_s.classify)
        ##  find has_manies by belongs_to id
        define_method("#{has_many_class.name.pluralize.underscore}") do 
          has_many_class.send(:where, {"#{belongs_to_class.name.underscore}_id" => id})
        end
        ##  find belongs_to by a has_many
        has_many_class.class_eval do 
          define_method("imh_#{belongs_to_class.name.underscore}") do 
            puts "find org by channel id"
            belongs_to_class.send(:find, self.send("#{belongs_to_class.name.underscore}_id"))
          end
        end
      end
    end
  end
end


