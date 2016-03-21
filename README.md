# Metrix

Extract several Code Quality Metrics for a Git repository from several services

## Metrics

* Commits (Git)
* Deploys (Heroku)
* Pull Requests (GitHub)
* Comments (PR / Commit / Issue Comments) (GitHub)
* Builds (Passed + Failed) (TravisCI)
* GPA (CodeClimate)
* Code Quality (Quality / Style / Security Issues) (CodeClimate)
* Code Coverage (CodeClimate)

**TODO:**

* Bugs found (Taiga?)
* Velocity (Taiga?)

## Usage

1. Install [Code Climate CLI](https://github.com/codeclimate/codeclimate)
2. Run `bundle install` to fetch all dependencies.
3. Create a `config.yml` file for your project (see `config.yml.sample` for options)
4. Run `ruby lib/migrate.rb` to create the database structure
5. Setup Docker:

    ```` shell
    $ eval "$(docker-machine env default)"
    ````
    
6. Run `ruby lib/metrix.rb`

