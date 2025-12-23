require 'spec_helper'
require_relative '../lib/performance_utils'

RSpec.describe PerformanceUtils do
  # Test class that includes PerformanceUtils
  class TestCalculator
    extend PerformanceUtils
    
    attr_accessor :call_count
    
    def initialize
      @call_count = 0
    end
    
    def expensive_calculation(n)
      @call_count += 1
      sleep(0.01) # Simulate expensive operation
      n * 2
    end
    
    memoize :expensive_calculation
    
    def complex_calculation(a, b)
      @call_count += 1
      a + b
    end
    
    memoize :complex_calculation
  end
  
  describe '#memoize' do
    let(:calculator) { TestCalculator.new }
    
    it 'caches the result of expensive calculations' do
      result1 = calculator.expensive_calculation(5)
      result2 = calculator.expensive_calculation(5)
      
      expect(result1).to eq(10)
      expect(result2).to eq(10)
      expect(calculator.call_count).to eq(1) # Only called once
    end
    
    it 'calculates separately for different arguments' do
      result1 = calculator.expensive_calculation(5)
      result2 = calculator.expensive_calculation(10)
      
      expect(result1).to eq(10)
      expect(result2).to eq(20)
      expect(calculator.call_count).to eq(2) # Called twice with different args
    end
    
    it 'works with multiple arguments' do
      result1 = calculator.complex_calculation(2, 3)
      result2 = calculator.complex_calculation(2, 3)
      result3 = calculator.complex_calculation(2, 4)
      
      expect(result1).to eq(5)
      expect(result2).to eq(5)
      expect(result3).to eq(6)
      expect(calculator.call_count).to eq(2) # (2,3) cached, (2,4) new
    end
    
    it 'significantly improves performance for repeated calls' do
      # First call (not cached)
      time1 = Time.now
      calculator.expensive_calculation(100)
      elapsed1 = Time.now - time1
      
      # Second call (cached)
      time2 = Time.now
      calculator.expensive_calculation(100)
      elapsed2 = Time.now - time2
      
      # Cached call should be much faster
      expect(elapsed2).to be < (elapsed1 / 10)
    end
  end
  
  describe '#clear_memoization' do
    let(:calculator) { TestCalculator.new }
    
    it 'clears cache for specific method' do
      calculator.expensive_calculation(5)
      expect(calculator.call_count).to eq(1)
      
      calculator.clear_memoization(:expensive_calculation)
      calculator.expensive_calculation(5)
      expect(calculator.call_count).to eq(2) # Called again after clear
    end
  end
  
  describe '#clear_all_memoization' do
    let(:calculator) { TestCalculator.new }
    
    it 'clears all memoization caches' do
      calculator.expensive_calculation(5)
      calculator.complex_calculation(2, 3)
      expect(calculator.call_count).to eq(2)
      
      calculator.clear_all_memoization
      calculator.expensive_calculation(5)
      calculator.complex_calculation(2, 3)
      expect(calculator.call_count).to eq(4) # Both called again
    end
  end
  
  describe '#measure_time' do
    let(:calculator) { TestCalculator.new }
    
    it 'measures execution time of a block' do
      result = calculator.measure_time("Test operation", verbose: false) do
        sleep(0.02)
        "done"
      end
      
      expect(result).to eq("done")
    end
    
    it 'prints timing information when verbose is true' do
      expect do
        calculator.measure_time("Test operation", verbose: true) do
          sleep(0.01)
        end
      end.to output(/Test operation:.*ms/).to_stdout
    end
    
    it 'does not print when verbose is false' do
      expect do
        calculator.measure_time("Test operation", verbose: false) do
          sleep(0.01)
        end
      end.not_to output.to_stdout
    end
  end
  
  describe '#batch_process' do
    let(:calculator) { TestCalculator.new }
    
    it 'processes items in batches' do
      items = (1..10).to_a
      results = calculator.batch_process(items, batch_size: 3, verbose: false) do |batch|
        batch.map { |n| n * 2 }
      end
      
      expect(results).to eq([2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    end
    
    it 'handles batch processing with exact batch size' do
      items = (1..9).to_a
      results = calculator.batch_process(items, batch_size: 3, verbose: false) do |batch|
        batch.sum
      end
      
      # Batch 1: 1+2+3=6, Batch 2: 4+5+6=15, Batch 3: 7+8+9=24
      expect(results).to eq([6, 15, 24])
    end
    
    it 'prints progress when verbose is true' do
      items = (1..5).to_a
      expect do
        calculator.batch_process(items, batch_size: 2, verbose: true) do |batch|
          batch
        end
      end.to output(/Processing batch/).to_stdout
    end
    
    it 'handles empty arrays' do
      results = calculator.batch_process([], batch_size: 10, verbose: false) do |batch|
        batch
      end
      
      expect(results).to eq([])
    end
    
    it 'handles single item' do
      results = calculator.batch_process([42], batch_size: 10, verbose: false) do |batch|
        batch
      end
      
      expect(results).to eq([42])
    end
  end
end
