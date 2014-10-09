#!/usr/bin/env ruby
# encoding: UTF-8

require 'mysql2'
require 'yaml'
require 'csv'

db_config_path = '/home/etienne/workspace/test/asset-declaration-scraper/database.yml'

db_config = YAML.load_file(db_config_path)
$mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], 
			   :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])
			   
$current_folder = Dir.pwd
$csv_folder = "output"

$main_headers = ["Declaration id","Submission date","Public official (en)","Public official (geo)","Position (en)","Position (geo)"]

Dir.foreach("#{$current_folder}/#{$csv_folder}") do |item|
    next if item == '.' or item == '..'
    if item.include? '.csv'
        File.delete("#{$current_folder}/#{$csv_folder}/#{item}")
    end
end

def writeInfoToCsv(table,result,cols)
	
	declaration_id = result['declaration_id']
	filename = "#{table}.csv"

	query = "SELECT tab.*, fam.role_en, fam.role_ka FROM #{table} tab, family_members fam WHERE tab.declaration_id = #{declaration_id} AND fam.declaration_id = tab.declaration_id AND fam.name_ka = tab.name_ka;"
	page_results = $mysql.query(query)
	
	page_results.each do |res|
		CSV.open("#{$csv_folder}/#{filename}", "a") do |csv|
			row = ["#{declaration_id}","#{result['submission_date']}","#{result['name_en']}","#{result['name_ka']}","#{result['position_en']}","#{result['position_ka']}"]
			row << res[cols[0]]
			row << res[cols[1]]
			row << res['role_en']
			row << res['role_ka']
			for i in 2..cols.length-1
			#cols.each do |col|
				row << res[cols[i]]
			end
			csv << row
		end
		
	end
end

def writeHeadersToCsv(csv,question,headers)
	row = [question]
	csv << row
	row = $main_headers + [headers[0],headers[1]] + ["Relationship (en)","Relationship (ka)"]
	for i in 2..headers.length-1
		row << headers[i]
	end
	csv << row
	#row = main_headers + ["Owner name (en)","Owner name (geo)","Property type (en)","Property type (geo)","Location (en)","Location (geo)","Common possession (en)","Common possession (geo)"]
	#csv << row
	return csv
end

# Initializing the csv files with questions and headers
CSV.open("#{$csv_folder}/property_assets.csv", "a") do |csv|
	question = "# Do you or your family members own real estate?"
	headers = ["Owner name (en)","Owner name (geo)","Property type (en)","Property type (geo)","Location (en)","Location (geo)","Common possession (en)","Common possession (geo)"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/movable_properties.csv", "a") do |csv|
	question = "# Do you or your family members own any movable property (except for cash/securities/bank deposits/etc.) valued at more than 10000 GEL (6100 USD approximately)?"
	headers = ["Property owner (en)","Property owner (geo)","Property type (en)","Property type (geo)","Ownership details (en)","Ownership details (geo)","Common possession (en)","Common possession (geo)"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/securities.csv", "a") do |csv|
	question = "# Do you or your family members own any securities?"
	headers = ["Owner name (en)","Owner name (geo)","Security issuer (en)","Security issuer (geo)","Type (en)","Type (geo)","Nominal value (en)","Nominal value (geo)","Quantity"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/bank_accounts.csv", "a") do |csv|
	question = "# Do you or your family members have bank accounts in Georgian or foreign banks?"
	headers = ["Account owner (en)","Account owner (geo)","Bank name (en)","Bank name (geo)","Account type (en)","Account type (geo)","Amount credit/debit"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/cash.csv", "a") do |csv|
	question = "# Do you or your family members hold cash valued at more than 4000 GEL (2400 USD approximately)?"
	headers = ["Cash owner (en)","Cash owner (geo)","Amount of cash"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/entrepreneurial_activities.csv", "a") do |csv|
	question = "# Have you or your family members undertaken any type of entrepreneurial activity?"
	headers = ["Name (en)","Name (geo)","Full address (en)","Full address (geo)","Partnership (en)","Partnership (geo)","Registration (en)","Registration (geo)","Activity period (en)","Activity period (geo)","Income received within reporting period"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/family_income.csv", "a") do |csv|
	question = "# Have you or your family members undertaken any type of paid work in Georgia or abroad; except for working in an enterprise?"
	headers = ["Name (en)","Name (geo)","Organisation (en)","Organisation (geo)","Job title (en)","Job title (geo)","Income"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/active_contracts.csv", "a") do |csv|
	question = "# Have you or your family members had any active contracts dating back from 1 January; in Georgia or abroad exceeding 3000 GEL (1800 USD approximately)?"
	headers = ["Name (en)","Name (geo)","Subject and value (en)","Subject and value (geo)","Signature (en)","Signature (geo)","Income contract (en)","Income contract (geo)"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/gifts.csv", "a") do |csv|
	question = "# Have you or your family members received any gifts valued at more than 500 GEL (300 USD approximately) during the reporting period (1 January - 31 December)?"
	headers = ["Person who received gift (en)","Person who received gift (geo)","Type and market price (en)","Type and market price (geo)","Relationship (en)","Relationship (geo)"]
	csv = writeHeadersToCsv(csv,question,headers)
end

CSV.open("#{$csv_folder}/expenses.csv", "a") do |csv|
	question = "# Have you or your family members received any income or had any expenditures during the reporting period (1 January - 31 December) valued at more than 1500 GEL (900 USD approximately) that you did not indicate on the pages above?"
	headers = ["Person who has income/expenditures (en)","Person who has income/expenditures (geo)","Type of income/expenditures (en)","Type of income/expenditures (geo)","Amount income/expenditures (en)","Amount income/expenditures (geo)"]
	csv = writeHeadersToCsv(csv,question,headers)
end


CSV.foreach('input.csv',:headers => false) do |court_array|
	
	court = court_array[0]
	
	puts "Processing information about '#{court}'"

	query = "SELECT fam.name_en, decl.name_ka, decl.declaration_id, decl.submission_date, fam.position_en, fam.position_ka
			 FROM family_members fam, declarations decl
			 WHERE fam.declaration_id = decl.declaration_id
			 AND fam.position_en = '#{court}'
			 ORDER BY fam.name_en ASC, decl.submission_date DESC;"
			 
	results = $mysql.query(query)
	
	results.each do |result|
		
		# Getting information about properties
		table = 'property_assets'
		cols = ['name_share_en','name_share_ka','property_en','property_ka','location_en','location_ka','common_owners_en','common_owners_ka']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about movable properties
		table = 'movable_properties'
		cols = ['owner_name_en','owner_name_ka','property_type_en','property_type_ka','details_en','details_ka','common_owners_en','common_owners_ka']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about securities
		table = 'securities'
		cols = ['name_en','name_ka','issuer_en','issuer_ka','type_en','type_ka','value_en','value_ka','quantity']
		writeInfoToCsv(table,result,cols)
			
		# Getting information about bank accounts
		table = 'bank_accounts'
		cols = ['name_en','name_ka','bank_name_en','bank_name_ka','account_type_en','account_type_ka','amount']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about holding cash
		table = 'cash'
		cols = ['name_en','name_ka','amount']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about entrepreneurial activities
		table = 'entrepreneurial_activities'
		cols = ['name_en','name_ka','address_en','address_ka','partnership_en','partnership_ka','registration_en','registration_ka','period_en','period_ka','income']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about family income (main salaries)
		table = 'family_income'
		cols = ['name_en','name_ka','organisation_en','organisation_ka','job_title_en','job_title_ka','income']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about active contracts
		table = 'active_contracts'
		cols = ['name_en','name_ka','subject_en','subject_ka','signature_en','signature_ka','income_en', 'income_ka']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about gifts
		table = 'gifts'
		cols = ['name_en','name_ka','type_price_en','type_price_ka','relationship_en','relationship_ka']
		writeInfoToCsv(table,result,cols)
		
		# Getting information about expenses
		table = 'expenses'
		cols = ['name_en','name_ka','income_en','income_ka','amount_en','amount_ka']
		writeInfoToCsv(table,result,cols)
				
	end
	
end
