# frozen_string_literal: true

# **Module:** CarInfo
#
# *Called by:* FMDOParser::extract_static_values
#
# CarInfo offers methods to convert integer values from FMDOParser::extract_static_values
# into readable strings for display in the browser dashboard, or other contexts.
#
# **Methods:**
# - **car_lookup(ordinal):** When provided a valid "Car Ordinal" integer, car_lookup retrives year, make and model info
# for the specified car from the CAR_LIST constant
# car_lookup takes a ForzaDataOut ordinal and retrieves car data from hashed listing
module CarInfo
  # Constant for storing hashed year, make, model info using Car Ordinal keys
  CAR_LIST = {} # rubocop:disable Style/MutableConstant

  # Load (and merge) car_list.json external file into CAR_LIST.
  def self.load_and_merge_list(file_path)
    # Load external list from JSON file (symbolized)
    #   - symbolizes names for use by CarInfo::car_lookup
    external_list = JSON.parse(File.read(file_path), symbolize_names: true)

    # Merge external list with CAR_LIST constant
    # Return the merged list
    CAR_LIST.merge!(external_list)
  end

  # Ensures external list file is loaded when modulue is first loaded
  load_and_merge_list('lib/data/car_list.json')

  # Returns array of strings with :year, :make, :model info for current car
  def car_lookup(ordinal)
    return nil if ordinal.nil?

    # Retrieves current car info by ordinal from CAR_LIST hash
    # Arguments passed by FMDOParser::extract_static_data calls are integers and must be symbolized
    car_info = CAR_LIST[ordinal.to_s.to_sym]
    return "Car Ordinal #{ordinal} is not in data file. Please Update" if car_info.nil?

    [car_info[:year], car_info[:make], car_info[:model]]
  end

  # Converts car-class integers into readable class letters for display
  def convert_class(num)
    conversion = { 0 => 'E', 1 => 'D', 2 => 'C', 3 => 'B', 4 => 'A', 5 => 'S', 6 => 'R', 7 => 'P', 8 => 'X' }
    conversion.keys.include?(num) ? conversion[num] : 'Error: Invalid Class ID Number'
  end

  # Converts drivetrain-type integers into readable drivetrain labels for display
  def convert_drive(num)
    conversion = { 0 => 'FWD', 1 => 'RWD', 2 => 'AWD' }
    conversion.keys.include?(num) ? conversion[num] : 'Error: Invalid drive type'
  end

  # TODO: ADD method for calling file writing class to modify external file (add or modify car list)
end
