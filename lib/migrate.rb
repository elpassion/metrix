require 'sqlite3'
require 'sequel'
require 'yaml'

config  = YAML.load_file('config.yml')
db_file = config['cache_db']
db      = Sequel.connect("sqlite://#{db_file}")

db.create_table :projects do
  primary_key :id
  String :name
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
  Boolean :pull_request
  String :state
  BigDecimal :coverage
end

db.create_table :issues do
  primary_key :id
  foreign_key :project_id, :projects
  foreign_key :commit_id, :commits
  DateTime :timestamp
  String :category
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
