require 'bigdecimal'
require 'date'
require 'sequel'
require 'sqlite3'
require 'yaml'

config = YAML.load_file('config.yml')
db     = Sequel.connect("sqlite://#{config['db']}")

db.create_table :projects do
  primary_key :id
  String :name
  index :name, unique: true
end

db.create_table :builds do
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

db.create_table :issues do
  primary_key :id
  foreign_key :project_id, :projects
  foreign_key :build_id, :builds
  DateTime :timestamp
  String :category
  String :path
  Integer :remediation_cost
  String :engine_name
end

db.create_table :activities do
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
