require('keen')

# Monkeypatch the Keen gem to wrap :query and steal the :csv option
module Keen
  class << self

    def query_wrapper(*args)
      # let's optimize for lowest-possible overhead in case 'csv' output isn't requested
      if args[-1][:csv]
        # CSV ouput was requested.
        # First, remove the :csv option to keep from messing up the Keen gem
        options = args[-1].delete(:csv)
        # and perform the query
        response = naked_query(*args)

        # and now for the main event . . . generating the CSV output
        keenCSV = Keen::CSV.new(response, options)
        return keenCSV.csvString
      else
        # not CSV; just pass through to the naked query
        return naked_query(*args)
      end
    end

    # Wrap :query with :query_wrapper via aliases
    alias :naked_query :query
    alias :query :query_wrapper

  end

end
