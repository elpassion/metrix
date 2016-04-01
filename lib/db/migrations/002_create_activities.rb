require 'bigdecimal'
require 'date'

Sequel.migration do
  up do
    create_table :activities do
      primary_key :id
      foreign_key :project_id, :projects
      String :type
      DateTime :timestamp
      Integer :integer_key
      Integer :integer_value
      String :string_key
      String :string_value
      Float :float_key
      Float :float_value
      BigDecimal :decimal_key
      BigDecimal :decimal_value
      DateTime :timestamp_key
      DateTime :timestamp_value
      TrueClass :boolean_key
      TrueClass :boolean_value
    end
  end

  down do
    drop_table :activities
  end
end
