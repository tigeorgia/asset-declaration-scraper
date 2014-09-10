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

db_config_path = '/home/etienne/workspace/test/asset-declaration-scraper/database.yml'

filename = "RepresentativeTableUpdate.sql"

# create connection to MySql database
db_config = YAML.load_file(db_config_path)
mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], 
			   :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])

# Writing first group of statements to update representative_representative.
query = "SELECT rep1.person_ptr_id, rep1.name_ka, rep1.submission_date, rep1.entrepreneurial_salary, rep1.main_salary, \
	 rep1.declaration_id, rep1.family_status_en, rep1.family_status_ka, rep1.expenses_en, rep1.expenses_ka, rep1.property_assets_en, rep1.property_assets_ka \
	 FROM representative_representative rep1 \
	 INNER JOIN \
    	    (SELECT name_ka, MAX(submission_date) AS MaxDateTime \
    	     FROM representative_representative \
    	     GROUP BY name_ka) grouped_rep \
	 ON rep1.name_ka = grouped_rep.name_ka \
	 AND rep1.submission_date = grouped_rep.MaxDateTime;"

results = mysql.query(query)

results.each do |row|
    line = "UPDATE representative_representative SET submission_date=TO_DATE('#{row['submission_date']}','YYYY-MM-DD'), entrepreneurial_salary=#{row['entrepreneurial_salary']}, main_salary=#{row['main_salary']}, declaration_id=#{row['declaration_id']}, family_status_en='#{row['family_status_en']}', family_status_ka='#{row['family_status_ka']}', expenses_en='#{row['expenses_en']}', expenses_ka='#{row['expenses_ka']}', property_assets_en='#{row['property_assets_en']}', property_assets_ka='#{row['property_assets_ka']}' WHERE person_ptr_id=(SELECT person_id FROM popit_personname WHERE name_ka='#{row['name_ka']}');"

    File.open(filename,'a') { |file| file.write(line+"\n") } 
end


# Writing statement to update the representative_urls table now
query = "SELECT distinct(name_ka) FROM representative_representative;"

results = mysql.query(query)
	
results.each do |row|
    query_to_write = "DELETE FROM representative_url WHERE representative_id=(SELECT person_id FROM popit_personname WHERE name_ka='#{row['name_ka']}') AND (label LIKE 'Asset%');"
    File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

    query = "SELECT ad_id, name_ka, submission_date FROM representative_declaration WHERE name_ka = '#{row['name_ka']}';"
    results_declaration = mysql.query(query)

    results_declaration.each do |decl|
	query_to_write = "INSERT INTO representative_url (representative_id,label,label_en,label_ka,url) VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='#{decl['name_ka']}'),'Asset Declaration (#{decl['submission_date']})','Asset Declaration (#{decl['submission_date']})','ქონებრივი დეკლარაცია (#{decl['submission_date']})','https://declaration.gov.ge/declaration/#{decl['ad_id']}');"
	File.open(filename,'a') { |file| file.write(query_to_write+"\n") }
    end

end

# Writing statements to update representative_familyincome table now
query = "SELECT min(ad_id) as min_ad, max(ad_id) as max_ad FROM representative_declaration;"
results = mysql.query(query)

results.each do |row|
    query_to_write = "\nDELETE FROM representative_familyincome WHERE ad_id >= #{row['min_ad']} and ad_id <= #{row['max_ad']};"
    File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

    query = "SELECT fam_name_ka, ad_id, submission_date, fam_name_ka, fam_role_ka, fam_date_of_birth, fam_income, fam_cars FROM representative_family_income
	     WHERE ad_id >= #{row['min_ad']} and ad_id <= #{row['max_ad']};"

    results_fam = mysql.query(query)

    results_fam.each do |fam|
	query_to_write = "INSERT INTO representative_familyincome (representative_id,ad_id,submission_date,fam_name,fam_role,fam_gender,fam_date_of_birth,fam_income,fam_cars) VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='#{fam['fam_name_ka']}'),#{fam['ad_id']}, TO_DATE('#{fam['submission_date']}','YYYY-MM-DD'), '#{fam['fam_name_ka']}', '#{fam['fam_role_ka']}','', TO_DATE('#{fam['fam_date_of_birth']}','YYYY-MM-DD'), #{fam['fam_income']}, #{fam['fam_cars']});"

        File.open(filename,'a') { |file| file.write(query_to_write+"\n") }

    end

end

puts "All done."


