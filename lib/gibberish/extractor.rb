module Gibberish
  class Extractor
    # Extract all Gibberish message lookups in a Rails application
    # Assumes that all message texts are either
    # in double quotes (") or in single quotes (').
    #
    # Ruby example:
    #
    # flash[:notice] = "The booking was accepted and the administrators have been
    #    notified by email to make the booking."[:bookings_accept_confirm]
    #
    # ERB example:
    #
    # <%= 'Hello {user_name}!
    # {booking_user_name} has signed up for the course {course_name}. To accept or reject the application, visit:
    #
    # {accept_url}
    #
    # {signature}'[:email_signed_up, 
    # @options[:user].name, 
    # @booking.user.name, 
    # @booking.course.name, 
    # @options[:accept_url], 
    # @options[:signature]] %>
    #
    # TODO: Check there are no variable interpolations in strings
    # TODO: Check the regexp doesn't miss any lookups by comparing count to a simple regexp?
    def messages
      if !@messages
        @messages = HashWithIndifferentAccess.new
        extract_messages
      end
      @messages
    end
    
    def reused_keys
      extract_reused_keys if !@reused_keys        
      @reused_keys
    end

    def self.cached_messages
      @@cached_messages ||= Gibberish::Extractor.new.messages
    end

    def self.flush_cache
      @@cached_messages = nil
    end
    
    private
    def files_with_messages
      `find #{dirs_to_search.join(" ")} -type f -regex '.*rb'`.split.map(&:chomp)
    end

    def dirs_to_search
      %w(app config lib).map { |dir| "#{RAILS_ROOT}/#{dir}" }
    end

    def message_pattern(start_token, end_token)
      /#{start_token}((?:[^#{end_token}](?:\\#{end_token})?)+)#{end_token}\[:([a-z_]+)/m
      # Non greedy, simpler alternative:
      #/#{start_token}(.+?)#{end_token}\[:([a-z_]+)/m
    end

    def add_messages(contents, start_token, end_token)
      contents.scan(message_pattern(start_token, end_token)).each do |text, key|
        add_message(key, remove_quotes(text, end_token))
      end
    end

    def remove_quotes(text, end_token)
      text.gsub(/\\#{end_token}/, end_token)
    end

    def add_message(key, text)
      if messages[key] && messages[key] != text
        raise("Message key '#{key}' found in lookups with different texts, " +
          "first text: '#{messages[key]}', second text: '#{text}'")
      end
      @messages[key] = text
    end

    def extract_messages
      files_with_messages.each do |file|
        contents = IO.read(file)
        add_messages(contents, '"', '"')
        add_messages(contents, "'", "'")
      end      
    end
    
    def extract_reused_keys
      @reused_keys = []
      files_with_messages.each do |file|
        @reused_keys += IO.read(file).scan(/:([a-z_]+)\.l/).map(&:first)
      end
      @reused_keys.uniq!
      @reused_keys.sort!      
    end
  end # class Extractor
end # module Gibberish
