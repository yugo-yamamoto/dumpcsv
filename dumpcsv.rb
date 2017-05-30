#! /usr/bin/env ruby
require 'mysql2'

fail("usage ./dumpcsv.rb [db name] [table name]") if ARGV.length != 2

table_name = ARGV[1] 
database_name = ARGV[0]

# connection default : localhostroot nopassword
client = Mysql2::Client.new(
  :database => database_name ,
  :host     => ENV.fetch('RAILS_DATABASE_HOST','localhost'), 
  :username => ENV.fetch('RAILS_DATABASE_USERNAME','root'), 
  :password => ENV.fetch('RAILS_DATABASE_PASSWORD','') 
)

query = "select * from #{table_name}"
results = client.query(query)

# puts field names with BOM
print("\uFEFF" + results.fields{|e|"\"#{e}\""}.join(",") + "\r\n") 

results.each(:cache_rows => false){|row|
  values =  row.values
  values.map!{|value|
		if value.class == String
			value.strip!
			value.gsub(/(\r\n|\r|\n|\f)/,"\u2003") #replace newline to emsp
		elsif value.class == Time
			value.strftime("%Y/%m/%d %H:%M:%S") #format localtime
		else
			value.to_s
		end
	}.map!{|value|
    '"' + value.gsub('"','""') + '"'
  }
	print(values.join(",") + "\r\n")
}

