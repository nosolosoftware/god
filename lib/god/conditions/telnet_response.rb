require 'net/telnet'

module God
  module Conditions
    class TelnetResponse < PollCondition
      attr_accessor :times,        # e.g. 3 or [3, 5]
                    :host,         # e.g. www.example.com
                    :port,         # e.g. 8080
                    :timeout,      # e.g. 60.seconds
                    :command,      # Command to issue to Telnet server

      def initialize
        super
        self.port = 80
        self.times = [1, 1]
        self.timeout = 60.seconds
      end

      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end

        @timeline = Timeline.new(self.times[1])
        @history = Timeline.new(self.times[1])
      end

      def reset
        @timeline.clear
        @history.clear
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) if self.host.nil?
        valid &= complain("Attribute 'command' must be specified", self) if self.command.nil?
        valid
      end

      def test
        connection = Net::Telnet.new(
          "Host"    => self.host,
          "Port"    => self.port,
          "Timeout" => self.timeout
        )

        connection.cmd( self.command )

        process(true, 'OK')
      rescue Errno::ECONNREFUSED
        process(false, 'Refused')
      rescue Errno::ECONNRESET
        process(false, 'Reset')
      rescue EOFError
        process(false, 'EOF')
      rescue Timeout::Error
        process(false, 'Timeout')
      rescue Errno::ETIMEDOUT
        process(false, 'Timedout')
      rescue Exception => failure
        process(false, failure.class.name)
      end
      private

      def process( tested, code )
        self.info = []
        @timeline.push( tested )

        if @timeline.size >= self.times.last and @timeline.select{ |x| x }.size < self.times.first
          self.info = "Too many error Telnet responses #{history(code, tested)}"
          true
        else
          false
        end
      end

      def history(code, passed)
        entry = code.to_s.dup
        entry = '*' + entry if passed
        @history << entry
        '[' + @history.join(", ") + ']'
      end
    end
  end
end
