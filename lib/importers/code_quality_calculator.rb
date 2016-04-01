require_relative '../utils/gpa'

class CodeQualityCalculator

  def initialize(project, build)
    @project = project
    @build   = build
  end

  def calculate
    if build[:pull_request]
      {
          quality_issues:  nil,
          style_issues:    nil,
          security_issues: nil,
          gpa:             nil
      }
    else
      {
          quality_issues:  count_issues(build, ['Complexity', 'Duplication', 'Bug Risk']),
          style_issues:    count_issues(build, 'Style'),
          security_issues: count_issues(build, 'Security'),
          gpa:             calculate_gpa(file_costs(build))
      }
    end
  end

  private

  attr_reader :project, :build

  def count_issues(build, categories)
    project.issues.where(build_id: build[:id], category: categories).count
  end

  def calculate_gpa(file_costs)
    return unless file_costs.any?

    file_costs.inject(0) { |sum, cost| sum + GPA.new(cost).score } / file_costs.size
  end

  def file_costs(build)
    project
        .issues
        .select_group(:path)
        .select_append { sum(remediation_cost).as(remediation_sum) }
        .where(build_id: build[:id])
        .to_hash(:path, :remediation_sum)
        .values
  end
end

