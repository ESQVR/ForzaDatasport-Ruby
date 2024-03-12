# frozen_string_literal: true

require 'sinatra'
require 'socket'
require 'faye/websocket'
require 'logger'
require 'json'

# Initialize the logger to output to STDOUT
logger = Logger.new(STDOUT)

# Helper method to format bytes as a hexadecimal string
def bytes_to_hex(bytes)
  bytes.unpack1('H*')
end

# Helper method to parse signed integers from the data
def parse_signed_integer(data, offset, size)
  data[offset, size].unpack1('l')
end

# Helper method to parse signed integers from the data
def parse_signed_integer8(data, offset, size)
  data[offset, size].unpack1('c')
end

# Helper method to parse 32bit unsigned integers from the data
def parse_unsigned_integer(data, offset, size)
  data[offset, size].unpack1('L')
end

# Helper method to parse 16bit unsigned integers from the data
def parse_unsigned_integer16(data, offset, size)
  data[offset, size].unpack1('S')
end

# Helper method to parse 8bit unsigned integers from the data
def parse_unsigned_integer8(data, offset, size)
  data[offset, size].unpack1('C')
end

# Helper method to parse floating-point numbers from the data
def parse_floating_point(data, offset, size)
  data[offset, size].unpack1('e')
end

# Global variable to store the latest UDP data
$udp_data = {}

# need a list of clients to send the messages to
$websocket_clients = []

# Thread to listen for UDP data
Thread.new do
  udp = UDPSocket.new
  udp.bind('10.0.0.145', 9876)

  loop do
    data, addr = udp.recvfrom(331)

    # Parse data based on the provided data structure information
    is_race_on = parse_signed_integer(data, 0, 4)
    timestamp_ms = parse_unsigned_integer(data, 4, 4)
    engine_max_rpm = parse_floating_point(data, 8, 4)
    engine_idle_rpm = parse_floating_point(data, 12, 4)
    current_engine_rpm = parse_floating_point(data, 16, 4)
    acceleration_x = parse_floating_point(data, 20, 4)
    acceleration_y = parse_floating_point(data, 24, 4)
    acceleration_z = parse_floating_point(data, 28, 4)

    velocity_x = parse_floating_point(data, 32, 4)
    velocity_y = parse_floating_point(data, 36, 4)
    velocity_z = parse_floating_point(data, 40, 4)

    angular_velocity_x = parse_floating_point(data, 44, 4)
    angular_velocity_y = parse_floating_point(data, 48, 4)
    angular_velocity_z = parse_floating_point(data, 52, 4)

    yaw = parse_floating_point(data, 56, 4)
    pitch = parse_floating_point(data, 60, 4)
    roll = parse_floating_point(data, 64, 4)

    normalized_suspension_travel_front_left = parse_floating_point(data, 68, 4)
    normalized_suspension_travel_front_right = parse_floating_point(data, 72, 4)
    normalized_suspension_travel_rear_left = parse_floating_point(data, 76, 4)
    normalized_suspension_travel_rear_right = parse_floating_point(data, 80, 4)

    tire_slip_ratio_front_left = parse_floating_point(data, 84, 4)
    tire_slip_ratio_front_right = parse_floating_point(data, 88, 4)
    tire_slip_ratio_rear_left = parse_floating_point(data, 92, 4)
    tire_slip_ratio_rear_right = parse_floating_point(data, 96, 4)

    wheel_rotation_speed_front_left = parse_floating_point(data, 100, 4)
    wheel_rotation_speed_front_right = parse_floating_point(data, 104, 4)
    wheel_rotation_speed_rear_left = parse_floating_point(data, 108, 4)
    wheel_rotation_speed_rear_right = parse_floating_point(data, 112, 4)

    wheel_on_rumble_strip_front_left = parse_signed_integer(data, 116, 4)
    wheel_on_rumble_strip_front_right = parse_signed_integer(data, 120, 4)
    wheel_on_rumble_strip_rear_left = parse_signed_integer(data, 124, 4)
    wheel_on_rumble_strip_rear_right = parse_signed_integer(data, 128, 4)

    wheel_in_puddle_depth_front_left = parse_floating_point(data, 132, 4)
    wheel_in_puddle_depth_front_right = parse_floating_point(data, 136, 4)
    wheel_in_puddle_depth_rear_left = parse_floating_point(data, 140, 4)
    wheel_in_puddle_depth_rear_right = parse_floating_point(data, 144, 4)

    surface_rumble_front_left = parse_floating_point(data, 148, 4)
    surface_rumble_front_right = parse_floating_point(data, 152, 4)
    surface_rumble_rear_left = parse_floating_point(data, 156, 4)
    surface_rumble_rear_right = parse_floating_point(data, 160, 4)

    tire_slip_angle_front_left = parse_floating_point(data, 164, 4)
    tire_slip_angle_front_right = parse_floating_point(data, 168, 4)
    tire_slip_angle_rear_left = parse_floating_point(data, 172, 4)
    tire_slip_angle_rear_right = parse_floating_point(data, 176, 4)

    tire_combined_slip_front_left = parse_floating_point(data, 180, 4)
    tire_combined_slip_front_right = parse_floating_point(data, 184, 4)
    tire_combined_slip_rear_left = parse_floating_point(data, 188, 4)
    tire_combined_slip_rear_right = parse_floating_point(data, 192, 4)

    suspension_travel_meters_front_left = parse_floating_point(data, 196, 4)
    suspension_travel_meters_front_right = parse_floating_point(data, 200, 4)
    suspension_travel_meters_rear_left = parse_floating_point(data, 204, 4)
    suspension_travel_meters_rear_right = parse_floating_point(data, 208, 4)

    car_ordinal = parse_signed_integer(data, 212, 4)
    car_class = parse_signed_integer(data, 216, 4)
    car_performance_index = parse_signed_integer(data, 220, 4)
    drivetrain_type = parse_signed_integer(data, 224, 4)
    num_cylinders = parse_signed_integer(data, 228, 4)

    position_x = parse_floating_point(data, 232, 4)
    position_y = parse_floating_point(data, 236, 4)
    position_z = parse_floating_point(data, 240, 4)
    speed = (parse_floating_point(data, 244, 4) * 2.23694)
    power = parse_floating_point(data, 248, 4)
    torque = parse_floating_point(data, 252, 4)

    tire_temp_front_left = parse_floating_point(data, 256, 4)
    tire_temp_front_right = parse_floating_point(data, 260, 4)
    tire_temp_rear_left = parse_floating_point(data, 264, 4)
    tire_temp_rear_right = parse_floating_point(data, 268, 4)

    boost = parse_floating_point(data, 272, 4)
    fuel = parse_floating_point(data, 276, 4)
    distance_traveled = parse_floating_point(data, 280, 4)
    best_lap = parse_floating_point(data, 284, 4)
    last_lap = parse_floating_point(data, 288, 4)
    current_lap = parse_floating_point(data, 292, 4)
    current_race_time = parse_floating_point(data, 296, 4)

    lap_number = parse_unsigned_integer16(data, 300, 2)
    race_position = parse_unsigned_integer8(data, 302, 1)
    accel = parse_unsigned_integer8(data, 303, 1)
    brake = parse_unsigned_integer8(data, 304, 1)
    clutch = parse_unsigned_integer8(data, 305, 1)
    hand_brake = parse_unsigned_integer8(data, 306, 1)
    gear = parse_unsigned_integer8(data, 307, 1)
    steer = parse_signed_integer8(data, 308, 1)
    normalized_driving_line = parse_signed_integer8(data, 309, 1)
    normalized_aibrake_difference = parse_signed_integer8(data, 310, 1)

    tire_wear_front_left = parse_floating_point(data, 311, 4)
    tire_wear_front_right = parse_floating_point(data, 315, 4)
    tire_wear_rear_left = parse_floating_point(data, 319, 4)
    tire_wear_rear_right = parse_floating_point(data, 323, 4)

    track_ordinal = parse_signed_integer(data, 327, 4)

    # Update $udp_data with the new UDP data
    $udp_data = {
      is_race_on: is_race_on,
      timestamp_ms: timestamp_ms,
      engine_max_rpm: engine_max_rpm,
      engine_idle_rpm: engine_idle_rpm,
      current_engine_rpm: current_engine_rpm,
      acceleration_x: acceleration_x,
      acceleration_y: acceleration_y,
      acceleration_z: acceleration_z,
      velocity_x: velocity_x,
      velocity_y: velocity_y,
      velocity_z: velocity_z,
      angular_velocity_x: angular_velocity_x,
      angular_velocity_y: angular_velocity_y,
      angular_velocity_z: angular_velocity_z,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      normalized_suspension_travel_front_left: normalized_suspension_travel_front_left,
      normalized_suspension_travel_front_right: normalized_suspension_travel_front_right,
      normalized_suspension_travel_rear_left: normalized_suspension_travel_rear_left,
      normalized_suspension_travel_rear_right: normalized_suspension_travel_rear_right,
      tire_slip_ratio_front_left: tire_slip_ratio_front_left,
      tire_slip_ratio_front_right: tire_slip_ratio_front_right,
      tire_slip_ratio_rear_left: tire_slip_ratio_rear_left,
      tire_slip_ratio_rear_right: tire_slip_ratio_rear_right,
      wheel_rotation_speed_front_left: wheel_rotation_speed_front_left,
      wheel_rotation_speed_front_right: wheel_rotation_speed_front_right,
      wheel_rotation_speed_rear_left: wheel_rotation_speed_rear_left,
      wheel_rotation_speed_rear_right: wheel_rotation_speed_rear_right,
      wheel_on_rumble_strip_front_left: wheel_on_rumble_strip_front_left,
      wheel_on_rumble_strip_front_right: wheel_on_rumble_strip_front_right,
      wheel_on_rumble_strip_rear_left: wheel_on_rumble_strip_rear_left,
      wheel_on_rumble_strip_rear_right: wheel_on_rumble_strip_rear_right,
      wheel_in_puddle_depth_front_left: wheel_in_puddle_depth_front_left,
      wheel_in_puddle_depth_front_right: wheel_in_puddle_depth_front_right,
      wheel_in_puddle_depth_rear_left: wheel_in_puddle_depth_rear_left,
      wheel_in_puddle_depth_rear_right: wheel_in_puddle_depth_rear_right,
      surface_rumble_front_left: surface_rumble_front_left,
      surface_rumble_front_right: surface_rumble_front_right,
      surface_rumble_rear_left: surface_rumble_rear_left,
      surface_rumble_rear_right: surface_rumble_rear_right,
      tire_slip_angle_front_left: tire_slip_angle_front_left,
      tire_slip_angle_front_right: tire_slip_angle_front_right,
      tire_slip_angle_rear_left: tire_slip_angle_rear_left,
      tire_slip_angle_rear_right: tire_slip_angle_rear_right,
      tire_combined_slip_front_left: tire_combined_slip_front_left,
      tire_combined_slip_front_right: tire_combined_slip_front_right,
      tire_combined_slip_rear_left: tire_combined_slip_rear_left,
      tire_combined_slip_rear_right: tire_combined_slip_rear_right,
      suspension_travel_meters_front_left: suspension_travel_meters_front_left,
      suspension_travel_meters_front_right: suspension_travel_meters_front_right,
      suspension_travel_meters_rear_left: suspension_travel_meters_rear_left,
      suspension_travel_meters_rear_right: suspension_travel_meters_rear_right,
      car_ordinal: car_ordinal,
      car_class: car_class,
      car_performance_index: car_performance_index,
      drivetrain_type: drivetrain_type,
      num_cylinders: num_cylinders,
      position_x: position_x,
      position_y: position_y,
      position_z: position_z,
      speed: speed,
      power: power,
      torque: torque,
      tire_temp_front_left: tire_temp_front_left,
      tire_temp_front_right: tire_temp_front_right,
      tire_temp_rear_left: tire_temp_rear_left,
      tire_temp_rear_right: tire_temp_rear_right,
      boost: boost,
      fuel: fuel,
      distance_traveled: distance_traveled,
      best_lap: best_lap,
      last_lap: last_lap,
      current_lap: current_lap,
      current_race_time: current_race_time,
      lap_number: lap_number,
      race_position: race_position,
      accel: accel,
      brake: brake,
      clutch: clutch,
      hand_brake: hand_brake,
      gear: gear,
      steer: steer,
      normalized_driving_line: normalized_driving_line,
      normalized_aibrake_difference: normalized_aibrake_difference,
      tire_wear_front_left: tire_wear_front_left,
      tire_wear_front_right: tire_wear_front_right,
      tire_wear_rear_left: tire_wear_rear_left,
      tire_wear_rear_right: tire_wear_rear_right,
      track_ordinal: track_ordinal
    }

    if $udp_data[:hand_brake] == 255
      # Log the JSON data to the terminal
      logger.info($udp_data.to_json)
    end
  end
end

# WebSocket server route
get '/websocket' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    # Add the WebSocket to the list of clients
    $websocket_clients << ws

    ws.on(:open) do |_event|
      # Send initial data to the client
      ws.send($udp_data.to_json)
    end

    ws.on(:message) do |event|
      # Handle messages from clients (if needed)
    end

    ws.on(:close) do |_event|
      # Remove the closed connection from the list
      $websocket_clients.delete(ws)
    end

    ws.rack_response
  else
    # Normal HTTP request
    [200, {}, ['Hello']]
  end
end

# Thread to periodically send updates to all connected WebSocket clients
Thread.new do
  loop do
    # Sleep for a while before sending updates
    sleep 0.001

    # Send the latest UDP data to all connected WebSocket clients
    $websocket_clients.each do |client|
      client.send($udp_data.to_json)
    end
  end
end

# Sinatra route to serve the HTML page
get '/' do
  erb :index, locals: { data: $udp_data }
end
