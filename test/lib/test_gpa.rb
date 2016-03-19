require 'minitest/autorun'
require 'gpa'

class TestGPA < Minitest::Test

  def test_letter_a
    assert_equal 'A', GPA.new(0).letter
    assert_equal 'A', GPA.new(2000000).letter
  end

  def test_letter_b
    assert_equal 'B', GPA.new(2000001).letter
    assert_equal 'B', GPA.new(4000000).letter
  end

  def test_letter_c
    assert_equal 'C', GPA.new(4000001).letter
    assert_equal 'C', GPA.new(8000000).letter
  end

  def test_letter_d
    assert_equal 'D', GPA.new(8000001).letter
    assert_equal 'D', GPA.new(16000000).letter
  end

  def test_letter_f
    assert_equal 'F', GPA.new(16000001).letter
    assert_equal 'F', GPA.new(100000000).letter
  end

  def test_score_a
    assert_equal 4.00, GPA.new(0).score
    assert_equal 3.75, GPA.new(500000).score
    assert_equal 3.50, GPA.new(1000000).score
    assert_equal 3.25, GPA.new(1500000).score
    assert_equal 3.00, GPA.new(2000000).score
  end

  def test_score_b
    assert_equal 3.00, GPA.new(2000000).score
    assert_equal 2.75, GPA.new(2500000).score
    assert_equal 2.50, GPA.new(3000000).score
    assert_equal 2.25, GPA.new(3500000).score
    assert_equal 2.00, GPA.new(4000000).score
  end

  def test_score_c
    assert_equal 2.00, GPA.new(4000000).score
    assert_equal 1.75, GPA.new(5000000).score
    assert_equal 1.50, GPA.new(6000000).score
    assert_equal 1.25, GPA.new(7000000).score
    assert_equal 1.00, GPA.new(8000000).score
  end

  def test_score_d
    assert_equal 1.00, GPA.new(8000000).score
    assert_equal 0.75, GPA.new(10000000).score
    assert_equal 0.50, GPA.new(12000000).score
    assert_equal 0.25, GPA.new(14000000).score
    assert_equal 0.00, GPA.new(16000000).score
  end

  def test_score_f
    assert_equal 0.00, GPA.new(16000000).score
    assert_equal 0.00, GPA.new(100000000).score
  end

end