module Slop
  class Parser
    attr_reader :options, :used_options

    def initialize(options)
      @options = options

      reset
    end

    # Reset the parser, useful to use the same instance
    # to parse a second time without duplicating state.
    def reset
      @used_options = []
      @options.each(&:reset)
      self
    end

    def parse(strings)
      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      pairs.each do |flag, arg|
        break if !flag || flag == '--'

        if flag.include?("=")
          flag, arg = flag.split("=")
        end

        try_process(flag, arg)
      end

      Result.new(self).tap do |result|
        used_options.each { |o| o.finish(result) }
      end
    end

    def unused_options
      options.to_a - used_options
    end

    private

    # We've found an option, process it
    def process(option, arg)
      used_options << option
      option.ensure_call(arg)
    end

    # Try and find an option to process
    def try_process(flag, arg)
      if option = matching_option(flag)
        process(option, arg)
      elsif flag =~ /-[^-]/ && flag.size > 2
        # try and process as a set of grouped short flags
        flags = flag.split("").drop(1).map { |f| "-#{f}" }
        last  = flags.pop

        flags.each { |f| try_process(f, nil) }
        try_process(last, arg) # send the argument to the last flag
      end
    end

    def matching_option(flag)
      options.find { |o| o.flags.include?(flag) }
    end
  end
end
