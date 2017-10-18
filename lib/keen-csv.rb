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
  # generateResultColumns
  # ---------------------------------------------------------------------------
  def generateResultColumns
    resultColumns = {
      columns: {},
      maxRowIndex: 0 # We're going to count the rows, for future use
    }

    setColumnValue = lambda do |column, rowIndex, value|
      unless self.columnIsFiltered?(column)
        resultColumns[:columns][column] ||= []
        resultColumns[:columns][column][rowIndex] = value
      end
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
        object["value"].each do |group|

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
  # ---------------------------------------------------------------------------
  def columnIsFiltered?(header)
    return @options[:filteredColumns] &&
           @options[:filteredColumns].is_a?(Array) &&
           @options[:filteredColumns].include?(header)
  end

  # ---------------------------------------------------------------------------
  # csvString
  # ---------------------------------------------------------------------------
  def csvString
    resultColumns = self.generateResultColumns
    headers = resultColumns[:columns].keys
    csvString = headers.map{|s| self.filterValue(s)}.join(@options[:delimiter])

    (0..resultColumns[:maxRowIndex]).each do |rowIndex|
      csvString << "\r\n"
      csvString << headers.map{ |header|
        self.filterValue(resultColumns[:columns][header][rowIndex])
      }.join(@options[:delimiter])
    end
    return csvString
  end

  def filterValue(value)
    if value == nil
      return ''
    else
      return value.to_s.gsub(/#{Regexp.escape(@options[:delimiter])}/, @options[:delimiterSub])
    end
  end

  # ---------------------------------------------------------------------------
  # flatten
  # ---------------------------------------------------------------------------
  def flatten(object, flattened = {}, prefix = "")
    object.each do |key, value|
      if value.is_a?(Hash) || value.is_a?(Array)
        flatten(value, flattened, prefix + key + @options[:nestedDelimiter])
      else
        flattened[prefix + key] = value
      end
    end

    return flattened
  end
end
