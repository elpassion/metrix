require 'fileutils'
require 'json'
require 'open3'
require 'rugged'
require_relative 'importer'

class IssuesImporter < Importer

  def initialize(*)
    super

    @current_path = FileUtils.pwd
    @repo         = Rugged::Repository.new(project.path)
  end

  def import(truncate: false)
    truncate_issues if truncate
    analyze_builds(builds_scope(truncate))
    reset_git_repository
  end

  private

  attr_reader :current_path, :repo

  def analyze_builds(builds)
    builds_count = builds.count
    index        = 0

    builds.order(:number).each do |build|
      puts "-----> Build: ##{build[:number]} (#{index += 1} / #{builds_count})"

      analyze_build(build)
    end
  end

  def analyze_build(build)
    truncate_build_issues(build)

    unless repo.exists?(build[:commit_sha])
      puts "     ! Skipping - commit does not exist: #{build[:commit_sha]}"

      return
    end

    goto_build(build)

    return unless raw_issues = analyze_issues

    import_raw_issues(build, raw_issues)
  end

  def goto_build(build)
    FileUtils.chdir(project.path)

    puts "       Resetting to #{build[:commit_sha]}"
    repo.reset(build[:commit_sha], :hard)
    `git clean -f`

    FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), project.path)
  end

  def truncate_issues
    puts '-----> Deleting all project issues'

    project.issues.delete
  end

  def truncate_build_issues(build)
    project.issues.where(build_id: build[:id]).delete
  end

  def analyze_issues
    puts '       Analyzing'

    FileUtils.chdir(project.path)
    stdout, stderr, status = Open3.capture3('codeclimate analyze -f json')

    if (status && status.exitstatus != 0) || stderr =~ /\S/
      puts "     ! #{stderr.strip.gsub(/\n/, "\n     ! ")}"

      return
    end

    JSON.parse(stdout)
  end

  def import_raw_issues(build, raw_issues)
    puts '       Importing Issues'

    imported_issue_ids = []
    project.db.transaction do
      raw_issues.each do |issue|
        imported_issue_ids << project.issues.insert(
            project_id:       project.id,
            build_id:         build[:id],
            timestamp:        build[:timestamp],
            category:         issue['categories'].join(', '),
            path:             issue['location']['path'],
            remediation_cost: issue['remediation_points'],
            engine_name:      issue['engine_name']
        )
      end
    end

    puts "       Imported #{imported_issue_ids.size} issues"
  end

  def builds_scope(truncate)
    if truncate
      project.db[:builds]
    else
      already = project.issues.distinct.select(:build_id).to_a.map(&:values).flatten

      project.db[:builds].exclude(id: already)
    end
  end

  def reset_git_repository
    FileUtils.chdir(project.path)
    repo.reset('origin/HEAD', :hard)
    `git clean -f`
  end

end