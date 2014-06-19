module God
  module System
    class TopPoller
      Elements = {
        memory: 5,
        percent_cpu: 8,
        percent_memory: 9
      }

      def initialize(pid)
        @pid = pid
      end
      # Memory usage in kilobytes (resident set size)
      def memory
        top_parse( :memory ).to_i
      end

      # Percentage memory usage
      def percent_memory
        top_parse( :percent_memory ).to_f
      end

      # Percentage CPU usage
      def percent_cpu
        top_parse( :cpu ).to_i
      end

      private

      def top_parse( element )
        `top -p #{@pid} -b -n1`.split( "\n" ).last.split( ' ' )[element]
      end

      def time_string_to_seconds(text)
        _, minutes, seconds, useconds = *text.match(/(\d+):(\d{2}).(\d{2})/)
        (minutes.to_i * 60) + seconds.to_i
      end
    end
  end
end
