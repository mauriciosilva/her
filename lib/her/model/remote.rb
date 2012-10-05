module Her
  module Model
    module Booz
      def has_many_active_record(klass, attrs={})
        belongs_to_class    = self
        has_many_class      = self.nearby_class(klass.to_s.classify)

        ##  find has_manies by belongs_to id
        define_method("imh_#{has_many_class.name.pluralize.underscore}") do 
          has_many_class.send(:where, {"#{belongs_to_class.name.underscore}_id" => id})
        end

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


