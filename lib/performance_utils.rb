# Performance utility methods for optimization and caching
# Provides memoization and performance monitoring capabilities
module PerformanceUtils
  # Simple memoization decorator for expensive calculations
  # @param method_name [Symbol] Name of method to memoize
  # @param cache_key_generator [Proc] Optional proc to generate cache key from args
  def memoize(method_name, cache_key_generator: nil)
    original_method = instance_method(method_name)
    cache_var = "@_memoized_#{method_name}"
    
    define_method(method_name) do |*args, **kwargs|
      # Initialize cache if needed
      instance_variable_set(cache_var, {}) unless instance_variable_defined?(cache_var)
      cache = instance_variable_get(cache_var)
      
      # Generate cache key
      cache_key = if cache_key_generator
                    cache_key_generator.call(*args, **kwargs)
                  else
                    [args, kwargs]
                  end
      
      # Return cached value if exists
      return cache[cache_key] if cache.key?(cache_key)
      
      # Calculate and cache result
      result = original_method.bind(self).call(*args, **kwargs)
      cache[cache_key] = result
      result
    end
  end
  
  # Clear memoization cache for a specific method
  # @param method_name [Symbol] Name of method to clear cache for
  def clear_memoization(method_name)
    cache_var = "@_memoized_#{method_name}"
    remove_instance_variable(cache_var) if instance_variable_defined?(cache_var)
  end
  
  # Clear all memoization caches
  def clear_all_memoization
    instance_variables.each do |var|
      remove_instance_variable(var) if var.to_s.start_with?('@_memoized_')
    end
  end
  
  # Measure execution time of a block
  # @param label [String] Label for the measurement
  # @param verbose [Boolean] Whether to print timing info
  # @yield Block to measure
  # @return [Object] Result of the block
  def measure_time(label, verbose: true)
    start_time = Time.now
    result = yield
    elapsed = Time.now - start_time
    
    puts "#{label}: #{(elapsed * 1000).round(2)}ms" if verbose
    result
  end
  
  # Batch process items with progress reporting
  # @param items [Array] Items to process
  # @param batch_size [Integer] Number of items per batch
  # @param verbose [Boolean] Whether to print progress
  # @yield [batch, batch_number] Block to process each batch
  # @return [Array] Results from all batches
  def batch_process(items, batch_size: 100, verbose: true)
    results = []
    total_batches = (items.size.to_f / batch_size).ceil
    
    items.each_slice(batch_size).with_index do |batch, index|
      puts "Processing batch #{index + 1}/#{total_batches}..." if verbose
      batch_results = yield(batch, index + 1)
      results.concat(Array(batch_results))
    end
    
    results
  end
end
