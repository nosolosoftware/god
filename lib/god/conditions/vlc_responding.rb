require 'net/telnet'
include Socket::Constants

module God
  module Conditions
    # Condition Symbol :vlc_running
    # Type: Poll
    #
    # Trigger when vlc telnet connection is not responding
    #
    # Parameters
    # Required
    #   +port+ is the port
    #   +passwd+ is the vlc password for the telnet interface
    #   +timeout+ is the vlc connection timeout for the telnet interface
    #
    # Examples
    #
    # Trigger if the Vlc telnet server on port 4212 is not responding or the connection is refused
    #
    # on.condition(:vlc_responding) do |c|
    #   c.passwd = 'videolan'
    #   c.port = 4212
    #   c.timeout = 10
    # end
    #
    # Trigger if vlc is not responding or the connection is refused 5 times in a row
    #
    # on.condition(:socket_responding) do |c|
    #   c.passwd = 'videolan'
    #   c.port = 80
    #   c.times = 5
    # end
    #
    class VlcResponding < PollCondition
      attr_accessor :addr, :port, :passwd, :timeout, :times
      SUCCESS_MSG = "\nWelcome, Master\n> "

      def initialize
        super
        self.addr = '127.0.0.1'
        self.port = 4212
        self.passwd = 'videolan'
        self.timeout = 20

        self.times = [1, 1]
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
        if @port == 0
          valid &= complain("Attribute 'port' must be specified", self)
        end
        if @passwd == nil
          valid &= complain("Attribute 'password' must be specified", self)
        end
        valid
      end

      def test
        self.info = []
        begin
          connection = Net::Telnet::new( "Host" => @addr, "Port" => @port, "Timeout" => @timeout, "Prompt" => />\s/ )
          response = connection.cmd( @passwd )
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error
        end
        status = ( response == nil ? true : !response.include?( SUCCESS_MSG ) )
        self.info = "Got Vlc telnet response: #{!status}"
        @timeline.push(status)
        if @timeline.select { |x| x }.size >= self.times.first
          self.info = "Vlc is not responding"
          return true
        else
          return false
        end
      end
    end
  end
end
