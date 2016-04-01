require 'forwardable'
require 'sequel'
require 'sqlite3'

module Metrix
  class Store
    extend Forwardable

    MIGRATIONS_PATH = "#{__dir__}/../db/migrations"

    delegate [:[], :transaction] => :db

    def initialize(path)
      @path = path
    end

    def reset_connection!
      @db = nil
    end

    def run_migrations!
      Sequel.extension(:migration)
      Sequel::Migrator.run(db, MIGRATIONS_PATH)
    end

    def migration_needed?
      Sequel.extension(:migration)
      Sequel::Migrator.check_current(db, MIGRATIONS_PATH)
    end

    private

    attr_reader :path

    def db

      @db.
      @db ||= Sequel.connect("sqlite://#{path}")
    end
  end
end
