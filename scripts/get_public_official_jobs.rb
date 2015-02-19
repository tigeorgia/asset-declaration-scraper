#!/usr/bin/env ruby
# encoding: UTF-8

require 'mysql2'
require 'yaml'
require 'csv'

main_config_path = 'config-export-asset-declarations.yml'
if !File.exists?(main_config_path)
  log.error "The config file with paths does not exist"
  exit
end

main_config = YAML.load_file(main_config_path)
db_config_path = main_config['database']

if !File.exists?(db_config_path)
  log.error "The #{db_config_path} (config file) does not exist"
  exit
end

# create connection to MySql database
db_config = YAML.load_file(db_config_path)
$mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])


def get_info_for_position(position_clause, year, position_desc)

=begin
	positions = []
	query = "select distinct(position_ka) from declarations where submission_date >= '#{year}-01-01' and submission_date <= '#{year}-12-31' and position_ka #{position_clause};"

	results = $mysql.query(query)

	results.each do |row|
		positions << "'#{row['position_ka']}'"
	end

	position_string = positions.join(',')
=end

	query = "SELECT decl.declaration_id as declarationid, decl.name_ka as mpname, ent.name_ka as personname, ent.address_ka, ent.partnership_ka, ent.registration_ka, ent.period_ka, ent.income from entrepreneurial_activities ent, declarations decl \
		 where ent.declaration_id = decl.declaration_id \
		 and decl.submission_date >= '#{year}-01-01' \
		 and decl.submission_date <= '#{year}-12-31' \
		 and decl.position_ka #{position_clause};"
			 
	results = $mysql.query(query)


	results.each do |row|

		CSV.open("./public_officials_jobs_2013.csv", "a") do |csv|
			csv << [row['declarationid'],row['mpname'],row['personname'],row['address_ka'],row['name_ka'],row['partnership_ka'],row['registration_ka'],row['period_ka'],row['income']]
		end	
		
	end
	
	puts "#{position_desc} - done"

end


def get_csv_for_year (year)

    puts "Generating public_officials_jobs_#{year}.csv now"

	CSV.open("./public_officials_jobs_#{year}.csv", "a") do |csv|
		csv << ['declaration_id','mp_name','person_name','address','partnership','registration','period','income']
	end

	# Ministers
	get_info_for_position("LIKE '%,  მინისტრი'", year, 'Ministers')

	# Deputy Ministers
	get_info_for_position("LIKE '%,  მინისტრის მოადგილე'", year, 'Deputy Ministers')

	# Members of Parliament
	get_info_for_position("= 'საქართველოს პარლამენტი,  წევრი'", year, 'Members of Parliament')

	# Mayors
	get_info_for_position("LIKE '%,  მერი'", year, 'Mayors')

	# Gamgebelis
	get_info_for_position("LIKE '%,  გამგებელი'", year, 'Gamgebelis')

	# Heads of Sakrebulos
	get_info_for_position("LIKE '%,  თავმჯდომარე'", year, 'Heads of Sakrebulos')

	# Deputy Heads of Sakrebulos
	get_info_for_position("LIKE '%,  თავმჯდომარის მოადგილე'", year, 'Deputy Heads of Sakrebulos')

	# Members of Ajara High Council
	get_info_for_position("= 'აჭარის ავტონომიური რესპუბლიკის უმაღლესი საბჭო,  წევრი'", year, 'Members of Ajara High Council')

	# Member of Abkhazia High Council
	get_info_for_position("= 'აფხაზეთის ავტონომიური რესპუბლიკის უმაღლესი საბჭო,  წევრი'", year, 'Member of Abkhazia High Council')

	puts "public_officials_jobs_#{year}.csv has been generated."

end

get_csv_for_year('2013')
get_csv_for_year('2014')

puts "All done"
