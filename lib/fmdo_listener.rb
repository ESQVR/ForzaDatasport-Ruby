# frozen_string_literal: true

require_relative 'ip_finder'
require_relative 'parser_module'
require_relative 'car_info'
require 'logger'

# Forza Motorsport Data Out (FMDO) Listener -
# This class collects and parses data from the Forza Data Out UDP stream.
# Upon initialization, it creates a new thread to open a UDP socket and listen for data.
# UDP binary is parsed using parser_module into @udp_data hash for easy access.
class FMDOListener
  include FMDOParser
  include CarInfo

  attr_reader :udp_data, :my_ip, :static_data

  def initialize
    @collector = spawn_udp_receive_thread
    @udp_data = {}
    @my_ip = IPFinder.new
    @static_data = {}
    @logger = Logger.new($stdout)
  end

  private

  # Initialize a new Thread that initializes a UDPSocket, binds it to the IP selected by IPFinder
  # Static Data (Car ID, PI, Drivetrain / Track Info) is extracted and parsed (and logged) once
  # Thread continues to update @udp_data with every 331 bytes received from FM Data Out stream
  # Checks to see if race is on, and toggles static_data_sent when race is false, to induce refresh.
  def spawn_udp_receive_thread # rubocop:disable Metrics/MethodLength
    Thread.new do
      udp = UDPSocket.new
      udp.bind(@my_ip.first_ipv4, 9876)

      static_data_sent = false
      loop do
        data, _addr = udp.recvfrom(331)
        @udp_data = hash_udp_stream(data)
        static_data_sent = false if (@udp_data[:is_race_on]).zero? && static_data_sent == true
        next unless static_data_sent == false && @udp_data[:is_race_on] == 1

        @static_data = extract_static_values(data)
        static_data_sent = true
        @logger.info("Static Data (car info) sent and status is: #{static_data_sent}")
      end
    end
  end
end
