#!/usr/bin/env ruby
# encoding: utf-8

####################################################
#
# This script loads the information available on MP's declaration (XML files) onto a MySQL database.
# The goal is to reorganize data available in different places on the declarations,
# into 2 tables.
#
# The loaded data in the table will be read by another Ruby script, in order to create
# a MySQL script, that will update MP's information on myparliament.ge
#
# Please make sure you do the following:
# - indicate the folder where the XML files are (en_xml_folder variable)
# - create a database.yml file, that has the following keys, and the appropriate values:
#     database: 
#     username: 
#     password: 
#     encoding: utf8
#     host: localhost
#     port: 3306
#     reconnect: true
# - indicate the location of the database.yml file, into the db_config_path variable
# - you will need to create the database and the tables
####################################################

require 'nokogiri'
require 'mysql2'
require 'yaml'

en_xml_folder = '/'
db_config_path = '/'

# method used to extract data on the expenses page, and property assets page
def extract_several_lines(doc, page_number, full_name)
    array = []
    page = doc.xpath("//page[@number='#{page_number}']/text")
    i = 0
    for i in 0..page.length-1
	if page[i].children.text == full_name
	    left_index = page[i].attributes["left"].value 
	    new_left_index = line_index
	    i += 1
	    info = ''
	    while new_line_index.to_i < line_index.to_i
		info += "${page[i].children.text} - "
		i += 1
		new_line_index = page[i].attributes["left"].value
	    end
	    info = info[0..info.length-3]
	    array << info
	end
	i += 1
    end
    return array
end

# create connection to MySql database
db_config = YAML.load_file(db_config_path)
mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], 
			   :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])

# First, make sure the config file exist
if !File.exists?(db_config_path)
  log.error "The #{db_config_path} (config file) does not exist"
  exit
end

# We loop through all the XML declarations
Dir.foreach(en_xml_folder) do |item|
    next if item == '.' or item == '..'
 
    # we open the English XML file
    f = File.open(item)
    doc = Nokogiri::XML(f)

    # we also open the Georgian XML file
    f_ka = File.open("../ka/#{item}")
    doc_ka = nokogiri::XML(f_ka)

    # Initialization of main variables
    full_name = ''
    full_name_ka = ''
    declaration_id = 0
    submission_date = ''
    name_ka = ''

    first_page = doc.xpath('//page[@number="1"]/text')
    # We first try to get the first name and last name of the current person
    if first_page[3].children.text.include? 'First Name, Last Name:'
	full_name = first_page[4].children.text
        declaration_id = first_page[5].children.text.gsub('#','')
        submission_date = first_page[6].children.text.split(': ')[1]
    else
        # If we didn't find the name where it was supposed to be, we have to go through every line of the xml file, until we find it.
    end 

    # As we're dealing with a declaration, we check if there is already information about it in the database.
    query = "SELECT count(1) FROM representative_declaration WHERE ad_id = #{declaration_id};"
    result = mysql.query(query)
    is_already_in_db = false
    result.each do |row|
	is_already_in_db = row['count(1)'] > 0
    end
    
    if !is_already_in_db

        # Extract the family status
        family_status_en = ''
        family_status_ka = ''
	family_member_income = {} # list of keys for this hash: fam_name_en, fam_name_ka, fam_organisation fam_role_en, fam_role_ka, fam_gender, fam_date_of_birth, fam_income, fam_cars
	family_info = [] 
        is_married = false
        i = 0
	for i in 0..first_page.length-1
	    if first_page[i].children.text == "Place of Birth, Date of Birth: "
		place_dob_array = first_page[i+1].children.text.split(', ')
	        if place_dob_array.length == 2
		    family_member_income['place_of_birth'] = place_dob_array[0]
		    family_member_income['date_of_birth'] = place_dob_array[1]
		elsif place_dob_array.length == 3
		    family_member_income['place_of_birth'] = "#{place_dob_array[0]}, #{place_dob_array[1]}"
		    family_member_income['date_of_birth'] = place_dob_array[2]
		end
		family_member_income['role_en'] = '' # No role (relationship) assigned when we're dealing with MP
		family_member_income['role_ka'] = ''

		family_info << family_member_income
	    end

	    if first_page[i].children.text == "Relationship"
		# The next line will be the first relative. And we'll have relative information until we see the data 'www.declaration.gov.ge'
		family_member_income = {}
		i += 1
		while first_page[i].children.text != 'www.declaration.gov.ge'
		    first_name = first_page[i].children.text
		    i += 1
		    last_name = first_page[i].children.text
		    i += 1
		    family_member_income['full_name_en'] = "#{first_name} #{last_name}"
		    family_member_income['place_of_birth_en'] = first_page[i].children.text
		    i += 1
		    family_member_income['date_of_birth'] = first_page[i].children.text
		    i += 1
		    family_member_income['role_en'] = first_page[i].children.text
		    if family_member_income['role_en'] == "Spouse"
			is_married = true
		    end
		    i += 1
		    family_info << family_member_income
		end
	    end
	    i += 1
	end

	# Extracting the Georgian name
        first_page_ka = doc.xpath('//page[@number="1"]/text')
        if first_page_ka[3].children.text.include? 'სახელი, გვარი:'
    	    full_name_ka = first_page[4].children.text
        else
            # If we didn't find the name where it was supposed to be, we have to go through every line of the xml file, until we find it.
        end
	for i in 0..first_page_ka.length-1
	    if first_page_ka[i].children.text == "კავშირი"
		# The next line will be the first relative, this time in Georgian. And like before, we'll have relative information until we see the data 'www.declaration.gov.ge'
		i += 1
		relative_index = 1
		while first_page[i].children.text != 'www.declaration.gov.ge'
		    first_name = first_page[i].children.text
		    i += 1
		    last_name = first_page[i].children.text
		    i += 1
		    family_info[relative_index]['full_name_ka'] = "#{first_name} #{last_name}"
		    family_info[relative_index]['place_of_birth_ka'] = first_page[i].children.text
		    i += 1
		    #family_member_income['date_of_birth'] = first_page[i].children.text
		    i += 1
		    family_info[relative_index]['role_ka'] = first_page[i].children.text
		    i += 1
		    relative_index += 1
		end
	    end
	    i += 1
	end


	insert_query = "INSERT INTO representative_declaration (ad_id, name_ka) VALUES (#{declaration_id},#{full_name_ka});"
        mysql.query(query)

        if is_married
	    family_status_en = "Married"
    	    family_status_ka = "ქორწინებაში"
        else
	    family_status_en = "Single"
   	    family_status_ka = "დასაოჯახებელი"
        end

	family_income_array = []

	# Extracting MP personal info + family members personal info
	personal_info = doc.xpath('')

        # Extracting main salary, and family income
        salary_page = doc.xpath('//page[@number="8"]/text')
        main_salary = 0.0
        i = 0
	col_index = 0
        family_income = {}	
	current_name = ''
        for i in 0..salary_page.length-1
	    if col_index == 0 # "Name" column
		current_name = salary_page[i].children.text
		if !family_income.hasKey?(current_name)
		    family_income[current_name] = 0.0
		end
	    elsif col_index == 1 # "Organisation" column
		#family_income["fam_organisation"] = salary_page[i].children.text
	    elsif col_index == 2 # "Job title" column
		#family_income["fam_title"] = salary_page[i].children.text
	    else # "Income received" column
		family_income[current_name] = salary_page[i].children.text.to_f
	    end
	end

        for i in 0..salary_page.length-1
	    if salary_page[i].children.text == full_name
	        while !salary_page[i].children.text.include? 'GEL'
		    i += 1
	        end
	        amount = salary_page[i].children.text.split(' ')[0].to_f
	        main_salary += amount
   	    end
  	    i += 1
        end

	# Extracting information about car ownership
	car_page = doc.xpath('//page[@number="3"]/text')
	car_info_hash = {}
	for i in 0..car_page.length-1
	    if car_page[i].children.text == "Motor Vehicle"
		car_info = ''
		car_name_owner_en = car_page[i-1].children.text
		i += 1
		while page[i].attributes["left"].value > page[i-1].attributes["left"].value # while we are on the same line
		    car_info += "#{car_page[i].children.text} "
		    i += 1
		end
		car_info_hash[car_name_owner_en] = car_info
	    end
	end
    
        # Extracting entrepreneurial salary
        salary_page = doc.xpath('//page[@number="7"]/text')
        entr_salary = 0.0
        i = 0
        for i in 0..salary_page.length-1
	    if salary_page[i].children.text == full_name
	        while !salary_page[i].children.text.include? 'GEL'
		    i += 1
	        end
	        amount = salary_page[i].children.text.split(' ')[0].to_f
	        entr_salary += amount
  	    end
  	    i += 1
        end

    
        # Extracting the expenses
        en_expenses_array = extract_several_lines(doc, 11, full_name)
        ka_expenses_array = extract_several_lines(doc_ka, 11, full_name)

        # Extracting the property assets
        en_property_asset_array = extract_several_lines(doc, 2, full_name)
        ka_property_asset_array = extract_several_lines(doc_ka, 2, full_name)

        
        insert_query = "INSERT INTO representative_representative (submission_date, name_ka, entrepreneurial_salary, main_salary, declaration_id, family_status_en, \
	  	    family_status_ka, expenses_en, expenses_ka, property_assets_en, property_assets_ka) VALUES\
		    (TO_DATE(#{submission_date},'DD/MM/YYYY'),'#{full_name_ka}', #{entr_salary}, #{main_salary}, #{declaration_id}, '#{family_status_en}', \
		    '#{family_status_ka}', '#{en_expenses_array.join('; ')}', '#{ka_expenses_array.join('; ')}', '#{en_property_asset_array.join('; ')}', '#{ka_property_asset_array.join('; ')}');"
	mysql.query(query)

	# Extracting now information about family members assets

	family_income.each do |key, value| # key is full english name, value is this person's income
	    i = 0
	    family_info.each do |member|
		if member['full_name_en'] == key
		    break;
		else
		    i += 1
		end
	    end
	    insert_query = "INSERT INTO representative_family_income (ad_id,submission_date,fam_name_en,fam_name_ka,fam_role_en,fam_role_ka,fam_gender, \
			    fam_date_of_birth,fam_income,fam_cars) VALUES \
			    (#{declaration_id},TO_DATE(#{submission_date},'DD/MM/YYYY'),'#{family_info[i]['full_name_en']}','#{family_info[i]['full_name_ka']}','#{family_info[i]['role_en']}','#{family_info[i]['role_ka']}','',\
			    TO_DATE(#{family_info[i]['date_of_birth']},'DD/MM/YYYY'),#{family_income[key]},#{car_info_hash[key]});"
	    mysql.query(query)
	end

    end

    f.close
    f_ka.close

    puts "All done."

end


