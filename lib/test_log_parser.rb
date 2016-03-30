class TestLogParser
  COVERAGE_PATTERN_1 = /Coverage\ \=\ (\d+\.\d+)\%/
  COVERAGE_PATTERN_2 = /\((\d+\.\d+)\%\) covered/
  LOC_PATTERN        = /(\d+)\s+\/\s+(\d+)\s+LOC/

  def parse(log)
    coverage = lines_of_code = lines_tested = nil

    if log.include?('Coverage = ')
      coverage = BigDecimal(log.match(COVERAGE_PATTERN_1)[1])
    elsif log.include?('Coverage report generated')
      coverage = BigDecimal(log.match(COVERAGE_PATTERN_2)[1])
    end

    if match = log.match(LOC_PATTERN)
      lines_tested  = match[1].to_i
      lines_of_code = match[2].to_i
    end

    [coverage, lines_of_code, lines_tested]
  end

end