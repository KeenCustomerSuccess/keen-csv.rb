# keen-csv.rb

Adds an option to the [official Keen gem](https://github.com/keenlabs/keen-gem) for converting hte Keen response into a multiline CSV string.

### Installation

Install this gem from Rubygems:

```bash
  gem install keen-csv
```

or add it directly to your Gemfile:

```ruby
  gem 'keen-csv', '~>1.0.0'
```

### Usage

Perform a Keen query as documented in the [official Keen gem](https://github.com/keenlabs/keen-gem), but include an additional `:csv` property in the query hash. The value can either be `true` or an _options_ hash

```ruby
  require('keen')
  require('keen-csv')

  ENV['KEEN_PROJECT_ID'] = 'YOUR_PROJECT_ID'
  ENV['KEEN_READ_KEY'] = 'YOUR_READ_KEY'

  query = {
    timeframe: {
      start: '2017-04-08',
      end: '2017-04-011'
    },
    interval: 'daily',
    group_by: ['user_agent.info.browser.family'],
    csv: {
      delimiter: '&'
    }
  }

  puts Keen.query(:count, 'pageviews', query)
```

### Options
*  `delimiter`:        Use this character rather than a comma
*  `delimiterSub`:     If we encounter any `delimiter` characters, we'll substitute them for this
*  `nestedDelimiter`:  The nature of a Keen response sometimes entails nested objects. In these cases we'll flatten the keys using this character/string
*  `filteredColumns`:  An array of column headers to filter out of the final CSV results
