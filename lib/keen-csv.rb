require_relative('keen/query_wrapper')

class Keen::CSV
  @@defaultOptions = {
    delimiter:        ',',
    delimiterSub:     '.',
    nestedDelimiter:  '.',
    filteredColumns:  nil,
  }

  def initialize(response, options = {})
    @rawResponse = response
    @options = options.is_a?(Hash) ? @@defaultOptions.merge(options) : @@defaultOptions
  end

  # ---------------------------------------------------------------------------
  # csvString
  # Generates and returns a CSV for this Keen response
  # ---------------------------------------------------------------------------
  def csvString
    resultColumns = self.generateResultColumns
    headers = resultColumns[:columns].keys
    # Start off instantiating the csv string with the header values
    csvString = headers.map{|s| self.filterValue(s)}.join(@options[:delimiter])

    # Now iterate over each row, sticking its value under each header
    (0..resultColumns[:maxRowIndex]).each do |rowIndex|
      csvString << "\r\n"
      csvString << headers.map{ |header|
        self.filterValue(resultColumns[:columns][header][rowIndex])
      }.join(@options[:delimiter])
    end
    return csvString
  end

protected

  # ---------------------------------------------------------------------------
  # generateResultColumns
  # Transforms the Keen result columnar Map, keyed by header
  # ---------------------------------------------------------------------------
  def generateResultColumns
    resultColumns = {
      columns: {},
      maxRowIndex: 0 # We're going to count the rows, for future use
    }

    # Using a lambda to add the right columns into resultColumns, and keep track
    # of maxRowIndex
    setColumnValue = lambda do |column, rowIndex, value|
      unless self.columnIsFiltered?(column)
        resultColumns[:columns][column] ||= []
        resultColumns[:columns][column][rowIndex] = value
      end

      # Gotta keep track of how many rows we're working with.
      resultColumns[:maxRowIndex] = rowIndex if rowIndex > resultColumns[:maxRowIndex]
    end

    # Exit early if this is a simple math operation
    if @rawResponse.is_a? Numeric
      resultColumns[:columns]['result'] = [@rawResponse]
      resultColumns[:maxRowIndex] = 1
      return resultColumns
    end

    rowIndex = 0
    @rawResponse.each do |object|
      if object["value"].is_a? Array
        # This result is grouped! We're gonna have to create alot more columns and rows
        object["value"].each do |group|

          # iterate over each value grouping, and store the values
          self.flatten(group).each do |column, value|
            setColumnValue.call(column, rowIndex, value)
          end
          if object["timeframe"]
            self.flatten({"timeframe" => object["timeframe"]}).each do |column, value|
              setColumnValue.call(column, rowIndex, value)
            end
          end
          rowIndex += 1

        end
      else
        # Not grouped: This either an Extraction or a math operation on an interval.
        self.flatten(object).each do |column, value|
          setColumnValue.call(column, rowIndex, value)
        end
        rowIndex += 1

      end
    end

    resultColumns
  end

  # ---------------------------------------------------------------------------
  # columnIsFiltered?
  # Takes a column header, and determines whether that column should be
  # filtered out
  # ---------------------------------------------------------------------------
  def columnIsFiltered?(header)
    return @options[:filteredColumns] &&
           @options[:filteredColumns].is_a?(Array) &&
           @options[:filteredColumns].include?(header)
  end

  # ---------------------------------------------------------------------------
  # filterValue
  # Takes a scalar value, and returns a CSV-compatible one
  # ---------------------------------------------------------------------------
  def filterValue(value)
    if value == nil
      return ''
    else
      return value.to_s.gsub(/#{Regexp.escape(@options[:delimiter])}/, @options[:delimiterSub])
    end
  end

  # ---------------------------------------------------------------------------
  # flatten
  # Converts any nested dictionaries into a flattened/delimited one.
  # ---------------------------------------------------------------------------
  def flatten(object, flattened = {}, prefix = "")
    handleValue = lambda do |value, newPrefix|
      if value.is_a?(Hash) || value.is_a?(Array)
        # recurse!
        flatten(value, flattened, newPrefix + @options[:nestedDelimiter])
      else
        flattened[newPrefix] = value
      end
    end

    if object.is_a? Hash
      object.each do |key, value|
        handleValue.call(value, prefix + key)
      end
    elsif object.is_a? Array
      object.each_with_index do |value, index|
        handleValue.call(value, prefix + index.to_s)
      end
    else
      return object
    end

    return flattened
  end
end
