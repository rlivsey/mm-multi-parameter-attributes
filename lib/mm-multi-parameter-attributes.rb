require 'mongo_mapper'

module MongoMapper
  module Plugins
    module MultiParameterAttributes
      extend ActiveSupport::Concern

      def attributes=(new_attributes)
        return if new_attributes.nil?

        multi_parameter_attributes = []
        normal_attributes = {}

        new_attributes.each do |k, v|
          if k.to_s.include?("(")
            multi_parameter_attributes << [ k.to_s, v ]
          else
            normal_attributes[k] = v
          end
        end

        assign_multiparameter_attributes(multi_parameter_attributes)

        super(normal_attributes)
      end

      # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
      # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
      # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
      # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
      # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum, f for Float,
      # s for String, and a for Array. If all the values for a given attribute are empty, the attribute will be set to nil.
      def assign_multiparameter_attributes(pairs)
        execute_callstack_for_multiparameter_attributes(
          extract_callstack_for_multiparameter_attributes(pairs)
        )
      end

      def execute_callstack_for_multiparameter_attributes(callstack)
        callstack.each do |name, values_with_empty_parameters|
          # in order to allow a date to be set without a year, we must keep the empty values.
          # Otherwise, we wouldn't be able to distinguish it from a date with an empty day.
          values = values_with_empty_parameters.reject(&:nil?)

          if !values.reject{|x| x.blank? }.empty?
            values = values.map(&:to_i)

            key = self.class.keys[name]
            raise ArgumentError, "Unknown key #{name}" if key.nil?
            klass = key.type

            value = if Time == klass
              Time.zone.local(*values)
            elsif Date == klass
              begin
                values = values_with_empty_parameters.map{|v| v.blank? ? 1 : v.to_i}
                Date.new(*values)
              rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                Time.zone.local(*values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
              end
            else
              klass.new(*values)
            end
            writer_method = "#{name}="
            if respond_to?(writer_method)
              self.send(writer_method, value)
            else
              self[name.to_s] = value
            end
          end
        end
      end

      def extract_callstack_for_multiparameter_attributes(pairs)
        attributes = { }

        for pair in pairs
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = [] unless attributes.include?(attribute_name)

          attributes[attribute_name] << [ find_parameter_position(multiparameter_name), value ]
        end

        attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
      end

      def find_parameter_position(multiparameter_name)
        multiparameter_name.scan(/\(([0-9]*).*\)/).first.first
      end
    end
  end
end