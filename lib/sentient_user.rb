module SentientUser
  
  def self.included(base)
    base.class_eval {
      def self.current
        Thread.current[:user]
      end

      def self.current=(o)
        raise(ArgumentError,
            "Expected an object of class '#{self}', got #{o.inspect}") unless (o.is_a?(self) || o.nil?)
        Thread.current[:user] = o
      end
  
      def make_current
        Thread.current[:user] = self
      end

      def current?
        !Thread.current[:user].nil? && self.id == Thread.current[:user].id
      end
      
      def self.do_as(user, &block)
        old_user = self.current

        begin
          self.current = user
          response = block.call unless block.nil?
        ensure
          self.current = old_user
        end

        response
      end
    }
  end
end

module SentientController

  # call this in your controller as a before filter.  It should be called
  # after your types are authenticated, but before any other filters in case
  # those filters do anything worth tracking.
  def store_sentient_types
    SentientUser.sentient_types.each do |type|
      clazz = Module.const_get(type.to_s.camelize)
      clazz.current = self.send("current_#{type}".to_sym)
    end
  end

  # Optional after_filter that just sets the current value to nil
  def clear_sentient_types
    SentientUser.sentient_types.each do |type|
      clazz = Module.const_get(type.to_s.camelize)
      clazz.current = nil
    end
  end
end