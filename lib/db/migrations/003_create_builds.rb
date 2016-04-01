require 'bigdecimal'
require 'date'

Sequel.migration do
  up do
    create_table :builds do
      primary_key :id
      foreign_key :project_id, :projects
      DateTime :timestamp
      Integer :number
      String :commit_sha
      TrueClass :pull_request
      String :state
      Integer :lines_of_code
      Integer :lines_tested
      Integer :quality_issues
      Integer :style_issues
      Integer :security_issues
      BigDecimal :coverage
      BigDecimal :gpa
    end
  end

  down do
    drop_table :builds
  end
end
