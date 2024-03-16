# frozen_string_literal: true

# Step 1: Read the content of the text file
file_content = File.read('FM23CarID.txt')

# Step 2: Use a regular expression to extract the relevant parts of each line
# This regex assumes that each line is a JSON object with the keys "Ordinal", "Year", "Make", and "Model"
# It captures the values of these keys
regex = /"Ordinal": "(\d+)",\s*"Year": "(\d+)",\s*"Make": "([^"]*)",\s*"Model": "([^"]*)"/
matches = file_content.scan(regex)

# Step 3: Construct a hash with the extracted data
hash = {}
matches.each do |match|
  ordinal, year, make, model = match
  hash[ordinal.to_i] = { year: year.to_i, make: make, model: model }
end

# Step 4: Write the hash to a Ruby file
File.open('output.rb', 'w') do |file|
  file.puts 'hash = {'
  hash.each do |key, value|
    file.puts " #{key} => { :year => #{value[:year]}, :make => '#{value[:make]}', :model => '#{value[:model]}' },"
  end
  file.puts '}'
end
