# frozen_string_literal: true

require_relative 'ip_finder'
require_relative 'parser_module'
require_relative 'car_info'
require 'logger'

# Forza Motorsport Data Out (FMDO) Listener
# This class collects and parses data from the Forza Data Out UDP stream.
# Upon initialization, it spawns a new thread to open a UDP socket and listen for data.
# UDP binary is parsed using parser_module into @udp_data hash for easy access.
class FMDOListener # rubocop:disable Metrics/ClassLength
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

  def spawn_udp_receive_thread # rubocop:disable Metrics/MethodLength
    Thread.new do
      udp = UDPSocket.new
      udp.bind(@my_ip.first_ipv4, 9876)

      static_data_sent = false
      loop do
        data, _addr = udp.recvfrom(331)
        parse_and_store_data(data)
        next unless static_data_sent == false && @udp_data[:is_race_on] == 1

        @static_data = extract_static_values(data)
        static_data_sent = true
        @logger.info("Static Data (car info) sent and status is: #{static_data_sent}")
      end
    end
  end

  def parse_and_store_data(data) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @udp_data = {
      is_race_on: parse_dashdata(data, 0, 4, 'l'),
      timestamp_ms: parse_dashdata(data, 4, 4, 'L'),

      # engine_max_rpm: parse_dashdata(data, 8, 4, 'e'),
      # engine_idle_rpm: parse_dashdata(data, 12, 4, 'e'),

      current_engine_rpm: parse_dashdata(data, 16, 4, 'e'),
      acceleration_x: parse_dashdata(data, 20, 4, 'e'),
      acceleration_y: parse_dashdata(data, 24, 4, 'e'),
      acceleration_z: parse_dashdata(data, 28, 4, 'e'),

      velocity_x: parse_dashdata(data, 32, 4, 'e'),
      velocity_y: parse_dashdata(data, 36, 4, 'e'),
      velocity_z: parse_dashdata(data, 40, 4, 'e'),

      angular_velocity_x: parse_dashdata(data, 44, 4, 'e'),
      angular_velocity_y: parse_dashdata(data, 48, 4, 'e'),
      angular_velocity_z: parse_dashdata(data, 52, 4, 'e'),

      yaw: parse_dashdata(data, 56, 4, 'e'),
      pitch: parse_dashdata(data, 60, 4, 'e'),
      roll: parse_dashdata(data, 64, 4, 'e'),

      normalized_suspension_travel_front_left: parse_dashdata(data, 68, 4, 'e'),
      normalized_suspension_travel_front_right: parse_dashdata(data, 72, 4, 'e'),
      normalized_suspension_travel_rear_left: parse_dashdata(data, 76, 4, 'e'),
      normalized_suspension_travel_rear_right: parse_dashdata(data, 80, 4, 'e'),

      tire_slip_ratio_front_left: parse_dashdata(data, 84, 4, 'e'),
      tire_slip_ratio_front_right: parse_dashdata(data, 88, 4, 'e'),
      tire_slip_ratio_rear_left: parse_dashdata(data, 92, 4, 'e'),
      tire_slip_ratio_rear_right: parse_dashdata(data, 96, 4, 'e'),

      wheel_rotation_speed_front_left: parse_dashdata(data, 100, 4, 'e'),
      wheel_rotation_speed_front_right: parse_dashdata(data, 104, 4, 'e'),
      wheel_rotation_speed_rear_left: parse_dashdata(data, 108, 4, 'e'),
      wheel_rotation_speed_rear_right: parse_dashdata(data, 112, 4, 'e'),

      wheel_on_rumble_strip_front_left: parse_dashdata(data, 116, 4, 'l'),
      wheel_on_rumble_strip_front_right: parse_dashdata(data, 120, 4, 'l'),
      wheel_on_rumble_strip_rear_left: parse_dashdata(data, 124, 4, 'l'),
      wheel_on_rumble_strip_rear_right: parse_dashdata(data, 128, 4, 'l'),

      wheel_in_puddle_depth_front_left: parse_dashdata(data, 132, 4, 'e'),
      wheel_in_puddle_depth_front_right: parse_dashdata(data, 136, 4, 'e'),
      wheel_in_puddle_depth_rear_left: parse_dashdata(data, 140, 4, 'e'),
      wheel_in_puddle_depth_rear_right: parse_dashdata(data, 144, 4, 'e'),

      surface_rumble_front_left: parse_dashdata(data, 148, 4, 'e'),
      surface_rumble_front_right: parse_dashdata(data, 152, 4, 'e'),
      surface_rumble_rear_left: parse_dashdata(data, 156, 4, 'e'),
      surface_rumble_rear_right: parse_dashdata(data, 160, 4, 'e'),

      tire_slip_angle_front_left: parse_dashdata(data, 164, 4, 'e'),
      tire_slip_angle_front_right: parse_dashdata(data, 168, 4, 'e'),
      tire_slip_angle_rear_left: parse_dashdata(data, 172, 4, 'e'),
      tire_slip_angle_rear_right: parse_dashdata(data, 176, 4, 'e'),

      tire_combined_slip_front_left: parse_dashdata(data, 180, 4, 'e'),
      tire_combined_slip_front_right: parse_dashdata(data, 184, 4, 'e'),
      tire_combined_slip_rear_left: parse_dashdata(data, 188, 4, 'e'),
      tire_combined_slip_rear_right: parse_dashdata(data, 192, 4, 'e'),

      suspension_travel_meters_front_left: parse_dashdata(data, 196, 4, 'e'),
      suspension_travel_meters_front_right: parse_dashdata(data, 200, 4, 'e'),
      suspension_travel_meters_rear_left: parse_dashdata(data, 204, 4, 'e'),
      suspension_travel_meters_rear_right: parse_dashdata(data, 208, 4, 'e'),

      # car_ordinal: parse_dashdata(data, 212, 4, 'l'),
      # car_class: parse_dashdata(data, 216, 4, 'l'),
      # car_performance_index: parse_dashdata(data, 220, 4, 'l'),
      # drivetrain_type: parse_dashdata(data, 224, 4, 'l'),
      # num_cylinders: parse_dashdata(data, 228, 4, 'l'),

      position_x: parse_dashdata(data, 232, 4, 'e'),
      position_y: parse_dashdata(data, 236, 4, 'e'),
      position_z: parse_dashdata(data, 240, 4, 'e'),
      speed: (parse_dashdata(data, 244, 4, 'e') * 2.23694),
      power: parse_dashdata(data, 248, 4, 'e'),
      torque: parse_dashdata(data, 252, 4, 'e'),

      tire_temp_front_left: parse_dashdata(data, 256, 4, 'e'),
      tire_temp_front_right: parse_dashdata(data, 260, 4, 'e'),
      tire_temp_rear_left: parse_dashdata(data, 264, 4, 'e'),
      tire_temp_rear_right: parse_dashdata(data, 268, 4, 'e'),

      boost: parse_dashdata(data, 272, 4, 'e'),
      fuel: parse_dashdata(data, 276, 4, 'e'),
      distance_traveled: parse_dashdata(data, 280, 4, 'e'),
      best_lap: parse_dashdata(data, 284, 4, 'e'),
      last_lap: parse_dashdata(data, 288, 4, 'e'),
      current_lap: parse_dashdata(data, 292, 4, 'e'),
      current_race_time: parse_dashdata(data, 296, 4, 'e'),

      lap_number: parse_dashdata(data, 300, 2, 'S'),
      race_position: parse_dashdata(data, 302, 1, 'C'),
      accel: parse_dashdata(data, 303, 1, 'C'),
      brake: parse_dashdata(data, 304, 1, 'C'),
      clutch: parse_dashdata(data, 305, 1, 'C'),
      hand_brake: parse_dashdata(data, 306, 1, 'C'),
      gear: parse_dashdata(data, 307, 1, 'C'),
      steer: parse_dashdata(data, 308, 1, 'c'),
      normalized_driving_line: parse_dashdata(data, 309, 1, 'c'),
      normalized_aibrake_difference: parse_dashdata(data, 310, 1, 'c'),

      tire_wear_front_left: parse_dashdata(data, 311, 4, 'e'),
      tire_wear_front_right: parse_dashdata(data, 315, 4, 'e'),
      tire_wear_rear_left: parse_dashdata(data, 319, 4, 'e'),
      tire_wear_rear_right: parse_dashdata(data, 323, 4, 'e'),

      track_ordinal: parse_dashdata(data, 327, 4, 'l')
    }
  end

  def extract_static_values(data)
    {
      "Car Ordinal": car_lookup(parse_dashdata(data, 212, 4, 'l')),
      "Car Class": convert_class(parse_dashdata(data, 216, 4, 'l')),
      "Car PI": parse_dashdata(data, 220, 4, 'l'),
      "Drivetrain": convert_drive(parse_dashdata(data, 224, 4, 'l')),
      "Cylinders": parse_dashdata(data, 228, 4, 'l'),
      "Track Ordinal": parse_dashdata(data, 327, 4, 'l'),
      "Max RPM": parse_dashdata(data, 8, 4, 'e').round(0),
      "Idle RPM": parse_dashdata(data, 12, 4, 'e').round(0)
    }
  end
end
