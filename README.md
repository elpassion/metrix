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
5. Start **Docker Quickstart Terminal** (found in your Applications)
5. Setup Docker:

    ```` shell
    $ eval "$(docker-machine env default)"
    ````
    
6. Install CodeClimate CLI (follow instructions on https://github.com/codeclimate/codeclimate)
7. Run `ruby lib/migrate.rb` (beware! this will destroy the database!)
8. Run `ruby lib/metrix.rb`

## Obtaining Travis API Token

1. Create [GitHub Personal Access Token](https://github.com/settings/tokens)
2. Use GitHub Token to authenticate the Travis client:

    ```` shell
    $ travis login --pro --github-token XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ````
    
3. Open `~/.travis/config.yml` and copy `access_token` from `https://api.travis-ci.com/` endpoint.
