# filepath: /home/runner/work/hockey_bet/hockey_bet/spec/base_tracker_spec.rb

require_relative '../lib/base_tracker'
require 'tempfile'
require 'json'

# Test class that includes BaseTracker
class TestTracker
  include BaseTracker
  
  def initialize(data_file, verbose: true)
    initialize_tracker(data_file, verbose: verbose)
  end
end

RSpec.describe BaseTracker do
  let(:temp_file) { Tempfile.new(['test_tracker', '.json']) }
  let(:tracker) { TestTracker.new(temp_file.path, verbose: false) }
  
  after do
    temp_file.close
    temp_file.unlink
  end
  
  describe '#initialize_tracker' do
    it 'sets data_file and verbose' do
      expect(tracker.data_file).to eq(temp_file.path)
      expect(tracker.verbose).to be false
    end
    
    it 'creates data file if it does not exist' do
      new_file_path = File.join(Dir.tmpdir, 'new_tracker_test.json')
      File.delete(new_file_path) if File.exist?(new_file_path)
      
      new_tracker = TestTracker.new(new_file_path, verbose: false)
      expect(File.exist?(new_file_path)).to be true
      
      File.delete(new_file_path)
    end
  end
  
  describe '#load_data_safe' do
    it 'returns default value for non-existent file' do
      non_existent_path = File.join(Dir.tmpdir, 'non_existent_test.json')
      File.delete(non_existent_path) if File.exist?(non_existent_path)
      
      # Create tracker but don't initialize file
      test_tracker = TestTracker.allocate
      test_tracker.instance_variable_set(:@data_file, non_existent_path)
      test_tracker.instance_variable_set(:@verbose, false)
      
      expect(test_tracker.load_data_safe({})).to eq({})
      expect(test_tracker.load_data_safe([])).to eq([])
    end
    
    it 'loads valid JSON data' do
      data = { 'key' => 'value' }
      File.write(temp_file.path, JSON.generate(data))
      
      expect(tracker.load_data_safe({})).to eq(data)
    end
    
    it 'returns default value for invalid JSON' do
      File.write(temp_file.path, 'invalid json')
      expect(tracker.load_data_safe({})).to eq({})
    end
    
    it 'logs warning for invalid JSON when verbose' do
      verbose_tracker = TestTracker.new(temp_file.path, verbose: true)
      File.write(temp_file.path, 'invalid json')
      
      expect { verbose_tracker.load_data_safe({}) }.to output(/Warning:/).to_stdout
    end
  end
  
  describe '#save_data_safe' do
    it 'saves data as pretty JSON' do
      data = { 'test' => 'data', 'number' => 42 }
      tracker.save_data_safe(data)
      
      saved_content = File.read(temp_file.path)
      expect(JSON.parse(saved_content)).to eq(data)
      expect(saved_content).to include("\n") # Pretty formatted
    end
    
    it 'creates directory if needed' do
      nested_path = File.join(Dir.tmpdir, 'test_dir', 'nested', 'file.json')
      FileUtils.rm_rf(File.join(Dir.tmpdir, 'test_dir'))
      
      nested_tracker = TestTracker.new(nested_path, verbose: false)
      nested_tracker.save_data_safe({ 'test' => 'data' })
      
      expect(File.exist?(nested_path)).to be true
      
      FileUtils.rm_rf(File.join(Dir.tmpdir, 'test_dir'))
    end
  end
  
  describe '#validate_not_empty!' do
    it 'does not raise for valid strings' do
      expect { tracker.validate_not_empty!('valid', 'Test') }.not_to raise_error
      expect { tracker.validate_not_empty!('  valid  ', 'Test') }.not_to raise_error
    end
    
    it 'raises ArgumentError for nil' do
      expect {
        tracker.validate_not_empty!(nil, 'Test field')
      }.to raise_error(ArgumentError, /Test field cannot be empty/)
    end
    
    it 'raises ArgumentError for empty string' do
      expect {
        tracker.validate_not_empty!('', 'Test field')
      }.to raise_error(ArgumentError, /Test field cannot be empty/)
    end
    
    it 'raises ArgumentError for whitespace only' do
      expect {
        tracker.validate_not_empty!('   ', 'Test field')
      }.to raise_error(ArgumentError, /Test field cannot be empty/)
    end
  end
  
  describe 'logging methods' do
    describe '#log_info' do
      it 'outputs when verbose is true' do
        verbose_tracker = TestTracker.new(temp_file.path, verbose: true)
        expect { verbose_tracker.log_info('test message') }.to output(/test message/).to_stdout
      end
      
      it 'does not output when verbose is false' do
        expect { tracker.log_info('test message') }.not_to output.to_stdout
      end
    end
    
    describe '#log_warning' do
      it 'outputs warning when verbose is true' do
        verbose_tracker = TestTracker.new(temp_file.path, verbose: true)
        expect { verbose_tracker.log_warning('test warning') }.to output(/Warning: test warning/).to_stdout
      end
      
      it 'does not output when verbose is false' do
        expect { tracker.log_warning('test warning') }.not_to output.to_stdout
      end
    end
    
    describe '#log_error' do
      it 'always outputs error regardless of verbose flag' do
        expect { tracker.log_error('test error') }.to output(/Error: test error/).to_stderr
      end
      
      it 'outputs to stderr' do
        expect { tracker.log_error('test error') }.not_to output.to_stdout
        expect { tracker.log_error('test error') }.to output(/Error: test error/).to_stderr
      end
    end
  end
end
