# frozen_string_literal: true

require 'socket'

# Use the Socket.ip_address_list method to retrieve all IP addresses associated with the machine.
# Filters list by Ipv4/6 && non-loopback addresses, and assigns first address on the list as the IP for FDS
class IPFinder
  attr_reader :first_ipv4, :local_ip_list

  def initialize
    @local_ip_list = Socket.ip_address_list
    @first_ipv4 = choose_first4
  end

  def print_list
    @local_ip_list.each do |addr|
      # Determine the type of address
      address_type = addr.ipv4? ? 'IPv4' : 'IPv6'
      # Check if it's a loopback address
      loopback = addr.ipv4_loopback? || addr.ipv6_loopback? ? ' (Loopback)' : ''
      # Print the address with labels
      puts "#{address_type}#{loopback} - Interface: #{addr.ipv4? ? 'Unicast' : 'Unicast'} Address: #{addr.ip_address}"
    end
  end

  def print_list4
    ipv4_filter.each { |addr| puts addr.ip_address }
  end

  private

  def choose_first4
    ipv4_filter.first.ip_address
  end

  def ipv4_filter
    filter_list = []
    @local_ip_list.each do |addr|
      filter_list << addr if addr.ipv4? && !addr.ipv4_loopback?
    end
    filter_list
  end

  def ipv6_filter
    filter_list = []
    @local_ip_list.each do |addr|
      filter_list << addr if addr.ipv6? && !addr.ipv6_loopback?
    end
    filter_list
  end
end
