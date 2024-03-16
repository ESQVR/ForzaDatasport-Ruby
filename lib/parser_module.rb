# frozen_string_literal: true

# MetaParser
module FMDOParser
  def parse_dashdata(data, offset, size, format)
    data[offset, size].unpack1(format)
  end
end
