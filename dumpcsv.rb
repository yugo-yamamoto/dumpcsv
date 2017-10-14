#! /usr/bin/env ruby
# frozen_string_literal: true

require 'mysql2'
require 'optparse'
params = ARGV.getopts('d:h:u:p:s:')

database_name = params['d']

host      = params['h'] || 'localhost'
user_name = params['u'] || 'root'
pass_word = params['p'] || ''

if database_name.nil?
  print 'dumpcsv.rb -d [databasename] '
  print ' -u [username] -p [password] -h [host]'
  print ' -s SQL string or STDIN' + "\n"
  puts 'default username:root password:No host:localhost'
  exit
end

query = params['s']
query = STDIN.read if query.nil?

if query.nil?
  puts 'query string required.'
  puts 'please fill sql -s param or STDIN'
  exit
end

# connection default : localhostroot nopassword
client = Mysql2::Client.new(
  database: database_name,
  host:     host,
  username: user_name,
  password: pass_word
)

results = client.query(query)

# puts field names with BOM
print("\uFEFF" + results.fields { |e| "\"#{e}\"" }.join(',') + "\r\n")

results.each(cache_rows: false) do |row|
  values =  row.values
  values.map! do |value|
    if value.class == String
      value.strip!
      value.gsub(/(\r\n|\r|\n|\f)/, "\u2003") # replace newline to emsp
    elsif value.class == Time
      value.strftime('%Y/%m/%d %H:%M:%S') # format localtime
    else
      value.to_s
    end
  end
  values.map! do |value|
    '"' + value.gsub('"', '""') + '"'
  end
  print(values.join(',') + "\r\n")
end
