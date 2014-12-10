#!/usr/bin/env ruby
# encoding: utf-8

####################################################
#
# This script creates the SQL script to be run on the PSQL MyParliament DB
# It reads info from the DB filled by export-assets-declarations.rb
#
# Please make sure you do the following:
# - create a database.yml file, that has the following keys, and the appropriate values:
#     database: 
#     username: 
#     password: 
#     encoding: utf8
#     host: localhost
#     port: 3306
#     reconnect: true
# - run 'export-assets_declarations.rb' so you make sure you have the DB structure needed 
#   for this script to run correctly.
#
####################################################


require 'mysql2'
require 'yaml'

filename = "RepresentativeTableUpdate.sql"

# First, make sure the main config file exists
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
mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], 
			   :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])

# Writing first group of statements to update representative_representative.
query = "SELECT decl.name_ka, decl.declaration_id, decl.submission_date \
	 FROM declarations decl \
	 INNER JOIN \
    	    (SELECT decl2.name_ka, MAX(decl2.submission_date) AS MaxDateTime \
    	     FROM declarations decl2 \
    	     GROUP BY decl2.name_ka) grouped_decl \
	 ON decl.name_ka = grouped_decl.name_ka \
	 AND decl.submission_date = grouped_decl.MaxDateTime \
	 WHERE decl.position_en = 'Parliament of Georgia'";
	 
results = mysql.query(query)	
decl_results_count = results.count.to_f 

row_count = 1.0

results.each do |row|

	declaration_id = row['declaration_id']
	name_ka = row['name_ka']
	
	percentage_done = ((row_count / (decl_results_count)) * 100).round(2)
	puts "Processing declaration #{declaration_id}  \t\t (1/3 - #{percentage_done}% done)"
	
	query = "SELECT fam1.role_en, fam1.role_ka \
	 FROM family_members fam1 \
	 WHERE fam1.declaration_id = #{declaration_id} \
	 AND fam1.name_ka = '#{name_ka}';"
	 
	fam_results = mysql.query(query)
	fam_results.each do |fam_row|
		line = "UPDATE representative_representative SET submission_date=TO_DATE('#{row['submission_date']}','YYYY-MM-DD'), declaration_id=#{declaration_id}, family_status_en='#{fam_row['role_en']}', family_status_ka='#{fam_row['role_ka']}' WHERE person_ptr_id=(SELECT person_id FROM popit_personname WHERE name_ka='#{name_ka}');"
		File.open(filename,'a') { |file| file.write(line+"\n") } 
	end
	
	# MP's entrepreneurial salary
    query = "SELECT entr.income FROM entrepreneurial_activities entr WHERE name_ka='#{name_ka}' AND declaration_id='#{declaration_id}';"
    entr_results = mysql.query(query)
    
    entr_income = 0.0
    entr_results.each do |entr_row|
		income = entr_row['income']
		if (income != '') && (income.include? 'GEL')
			entr_income += income.gsub(' GEL', '').to_f
		end
    end
    
    # MP's main salary
    query = "SELECT income FROM family_income WHERE name_ka='#{name_ka}' AND declaration_id='#{declaration_id}';"
    salary_results = mysql.query(query)
    main_salary = 0.0
    salary_results.each do |salary_row|
		salary = salary_row['income']
		if (salary != '') && (salary.include? 'GEL')
			main_salary += salary.gsub(' GEL', '').to_f
		end
    end
    
    # MP's expenses
    query = "SELECT amount_en, amount_ka FROM expenses WHERE name_ka='#{name_ka}' AND declaration_id='#{declaration_id}';"
    expenses_results = mysql.query(query)
    expenses_en = []
    expenses_ka = []
	expenses_results.each do |expense_row|
		expenses_en << expense_row['amount_en']
		expenses_ka << expense_row['amount_ka']
	end
	
	# MP's property assets
	query = "SELECT location_en, location_ka FROM property_assets WHERE name_share_ka='#{name_ka}' AND declaration_id='#{declaration_id}';"
	assets_results = mysql.query(query)
	assets_en = []
	assets_ka = []
	assets_results.each do |asset_row|
		assets_en << asset_row['location_en']
		assets_ka << asset_row['location_ka']
	end
    
    line = "UPDATE representative_representative SET entrepreneurial_salary=#{entr_income}, main_salary=#{main_salary}, expenses_en='#{expenses_en.join('; ')}', expenses_ka='#{expenses_ka.join('; ')}', property_assets_en='#{assets_en.join('; ')}', property_assets_ka='#{assets_ka.join('; ')}' WHERE person_ptr_id=(SELECT person_id FROM popit_personname WHERE name_ka='#{name_ka}');"
    
    File.open(filename,'a') { |file| file.write(line+"\n") } 
    
    row_count += 1.0
    
end


# Writing statement to update the representative_urls table now
#query = "SELECT distinct(name_ka) FROM family_members WHERE (position_en is not null && position_en != '')"
query = "SELECT distinct(name_ka) FROM family_members WHERE position_en = 'Parliament of Georgia'"

results = mysql.query(query)

rep_ad_hash = {} # key => declaration_id, value => name_ka
row_count = 1.00

results.each do |row|

	name_ka = row['name_ka']
	
	percentage_done = ((row_count / (results.count.to_f)) * 100).round(2)
	puts "Processing representative urls #{name_ka}  \t\t (2/3 - #{percentage_done}% done)"
		
    query_to_write = "DELETE FROM representative_url WHERE representative_id=(SELECT person_id FROM popit_personname WHERE name_ka='#{name_ka}') AND (label LIKE 'Asset%');"
    File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

    query = "SELECT declaration_id, name_ka, submission_date FROM declarations WHERE name_ka = '#{name_ka}';"
    results_declaration = mysql.query(query)

    results_declaration.each do |decl|
		query_to_write = "INSERT INTO representative_url (representative_id,label,label_en,label_ka,url) VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='#{decl['name_ka']}'),'Asset Declaration (#{decl['submission_date']})','Asset Declaration (#{decl['submission_date']})','ქონებრივი დეკლარაცია (#{decl['submission_date']})','#{decl['declaration_id']}');"
		File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

		rep_ad_hash[decl['declaration_id']] = decl['name_ka']
    end
    
    row_count += 1

end

# Writing statements to update representative_familyincome table now
query = "SELECT min(declaration_id) as min_ad, max(declaration_id) as max_ad FROM declarations WHERE position_en = 'Parliament of Georgia';"
results = mysql.query(query)


results.each do |row|

	query_to_write = "\nDELETE FROM representative_familyincome WHERE ad_id >= #{row['min_ad']} and ad_id <= #{row['max_ad']};"
    File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

	query = "SELECT fam.name_ka, fam.declaration_id, decl.submission_date, fam.name_en, fam.role_ka, fam.dob \
			 FROM family_members fam, declarations decl \
			 WHERE fam.declaration_id = decl.declaration_id AND fam.declaration_id >= #{row['min_ad']} AND fam.declaration_id <= #{row['max_ad']} AND decl.position_en = 'Parliament of Georgia'";

    results_fam = mysql.query(query)
    row_count = 1.00
	
    results_fam.each do |fam|
		member_name_ka = fam['name_ka']
		declaration_id = fam['declaration_id']
		
		percentage_done = ((row_count / (results_fam.count.to_f)) * 100).round(2)
		puts "Processing family income from declaration #{declaration_id}  \t\t (3/3 - #{percentage_done}% done)"
		
		# Family member income
		query = "SELECT income FROM family_income WHERE name_ka = '#{member_name_ka}' AND declaration_id = #{declaration_id};"
		results_fam = mysql.query(query)
		mem_income = 0.0
		results_fam.each do |fam_row|
			income = fam_row['income']
			if (income != '') && (income.include? 'GEL')
				mem_income += income.gsub(' GEL', '').to_f
			end
		end
		
		# Family member's cars.
		query = "SELECT details_en FROM movable_properties WHERE owner_name_ka = '#{member_name_ka}' AND declaration_id = #{declaration_id} AND property_type_en = 'Motor Vehicle';"
		results_prop = mysql.query(query)
		cars = []
		results_prop.each do |prop_row|
			cars << prop_row['details_en']
		end
		
    
		query_to_write = "INSERT INTO representative_familyincome (representative_id,ad_id,submission_date,fam_name,fam_role,fam_gender,fam_date_of_birth,fam_income,fam_cars) VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='#{rep_ad_hash[fam['declaration_id']]}'), #{declaration_id}, TO_DATE('#{fam['submission_date']}','YYYY-MM-DD'), '#{member_name_ka}', '#{fam['role_ka']}','', TO_DATE('#{fam['dob']}','YYYY-MM-DD'), #{mem_income}, '#{cars.join('; ')}');"
		
		File.open(filename,'a') { |file| file.write(query_to_write+"\n") }
		
		row_count += 1.00

    end

end

puts "All done."


