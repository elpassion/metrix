class GPA

  def initialize(remediation_cost)
    @cost = remediation_cost
  end

  def letter
    return unless @cost

    @letter ||= if @cost <= 2000000
                  'A'
                elsif @cost <= 4000000
                  'B'
                elsif @cost <= 8000000
                  'C'
                elsif @cost <= 16000000
                  'D'
                else
                  'F'
                end
  end

  def score
    return unless @cost

    # @score ||= if @cost <= 4000000
    #              4.0 - @cost / 2000000.0
    #            elsif @cost <= 8000000
    #              3.0 - @cost / 4000000.0
    #            elsif @cost <= 16000000
    #              2.0 - @cost / 8000000.0
    #            else
    #              0.0
    #            end

    @score ||= if @cost <= 2000000
                 4.0
               elsif @cost <= 4000000
                 3.0
               elsif @cost <= 8000000
                 2.0
               elsif @cost <= 16000000
                 1.0
               else
                 0.0
               end
  end

end