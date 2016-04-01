require 'date'

Sequel.migration do
  up do
    create_table :issues do
      primary_key :id
      foreign_key :project_id, :projects
      foreign_key :build_id, :builds
      DateTime :timestamp
      String :category
      String :path
      Integer :remediation_cost
      String :engine_name
    end

  end

  down do
    drop_table :issues
  end
end
