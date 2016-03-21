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

db.create_table :commits do
  primary_key :id
  foreign_key :project_id, :projects
  DateTime :timestamp
  String :sha
end

db.create_table :builds do
  primary_key :id
  foreign_key :project_id, :projects
  DateTime :timestamp
  Integer :number
  String :commit_sha
  Boolean :pull_request
  String :state
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

db.create_table :releases do
  primary_key :id
  foreign_key :project_id, :projects
  DateTime :timestamp
  Integer :version
  String :description
end

db.create_table :pull_requests do
  primary_key :id
  foreign_key :project_id, :projects
  DateTime :timestamp
  DateTime :closed_at
  DateTime :merged_at
end

db.create_table :comments do
  primary_key :id
  foreign_key :project_id, :projects
  DateTime :timestamp
end
