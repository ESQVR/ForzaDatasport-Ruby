# frozen_string_literal: true

require 'sinatra'
require 'socket'
require 'faye/websocket'
require 'json'
require_relative 'lib/ip_finder'
require_relative 'lib/fmdo_listener'

set :bind, '0.0.0.0'

# Create a new listener to collect/parse/hash the Data Out Binary stream.
fmdo_stream = FMDOListener.new

# need a list of clients to send the messages to
websocket_clients = []

# Sinatra route to serve the dashboard erb page in /views
get '/' do
  @static_data = fmdo_stream.static_data || {}
  erb :microdash
end

# WebSocket server route
get '/websocket' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    ws.on(:open) do
      # Add the WebSocket to the list of clients
      websocket_clients << ws
    end

    ws.on(:message) do |event|
    end

    ws.on(:close) do |_event|
      # Remove the closed connection from the list
      websocket_clients.delete(ws)
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
    # Sleep for 1/60th of a second (packet-out rate from ForzaDataOut)
    sleep 0.0166
    udp_data = fmdo_stream.udp_data
    # Send the latest UDP data to all connected WebSocket clients
    websocket_clients.each do |client|
      client.send(udp_data.to_json)
    end
  end
end
