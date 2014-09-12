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
# - you will need to create the database. Tables will be created if they don't exist.
####################################################

require 'nokogiri'
require 'mysql2'
require 'yaml'

en_xml_folder = '/home/etienne/workspace/test/xmloutput/en/'
ka_xml_folder = '/home/etienne/workspace/test/xmloutput/ka/'
db_config_path = '/home/etienne/workspace/test/asset-declaration-scraper/database.yml'


#########################################
#
# This function defines if the next index of a page goes to another table column
# or if it stays in the same table column.
#
#########################################
def define_next_index(i,page,col_index,max_index)
    result = 0
    if page[i+1]
	line_index = page[i].attributes["left"].value.to_i
	next_line_index = page[i+1].attributes["left"].value.to_i
        if next_line_index - line_index > 150
	    if col_index > max_index
	        result = 0
	    else
	        result = col_index + 1
	    end
	elsif line_index - next_line_index > 400
	    result = 0
        else
	    result = col_index
        end
    end
    return result 
end


#########################################
#
# This function checks whether or not we're on the right page,
# as some specific page can have different page number,
# between 2 documents.
#
#########################################
def is_it_the_right_page(page,message)
    right_info_found = false
    for i in 0..page.length-1
	if page[i].children.text.include? message
	    right_info_found = true
	    break	    
	end
    end
    return right_info_found
end


#########################################
#
# This function scrapes information on the expenses page, 
# and on the property assets page.
#
#########################################
def get_property_expenses_info(message,previous_message,property_page,full_name)
    i = 0
    property_array = []
    for i in 1..property_page.length-1
	if (property_page[i].children.text.include? message) && (property_page[i-1].children.text.include? previous_message)
	    # The next line will be the first relative. And we'll have relative information until we see the data 'www.declaration.gov.ge'
	    i += 1
	    col_index = 0
	    is_main_person = false
	    info = []
	    while i <= property_page.length-1 && property_page[i].children.text != 'www.declaration.gov.ge'
	    	if col_index == 0
		    if info.length > 0
			property_array << info.join(' ').gsub(',,','')
		    end
		    info = []
		    is_main_person = property_page[i].children.text == full_name
	    	elsif col_index == 2
		    if is_main_person
			# Cleaning the data
			info << property_page[i].children.text.gsub('\'','').gsub('; ','').gsub(',,','')
		    end
	    	end
	        col_index = define_next_index(i,property_page,col_index,3)
	        i += 1
	    end
        end
        i += 1
    end
    return property_array
end

# Program starts here

# First, make sure the config file exists
if !File.exists?(db_config_path)
  log.error "The #{db_config_path} (config file) does not exist"
  exit
end

# Create connection to MySql database
db_config = YAML.load_file(db_config_path)
mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"], :username => db_config["username"], 
			   :password => db_config["password"], :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])

# Tables are created if they don't exist


query = "CREATE TABLE IF NOT EXISTS `representative_declaration` ( \
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `ad_id` int(11) DEFAULT NULL, \
  `name_ka` varchar(300) DEFAULT NULL, \
  `submission_date` date DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=101228 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `representative_family_income` ( \
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `ad_id` int(11) DEFAULT NULL, \
  `submission_date` date DEFAULT NULL, \
  `fam_name_en` varchar(100) DEFAULT NULL, \
  `fam_name_ka` varchar(100) DEFAULT NULL, \
  `fam_role_en` varchar(45) DEFAULT NULL, \
  `fam_role_ka` varchar(45) DEFAULT NULL, \
  `fam_gender` varchar(2) DEFAULT NULL, \
  `fam_date_of_birth` date DEFAULT NULL, \
  `fam_income` varchar(45) DEFAULT NULL, \
  `fam_cars` varchar(100) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=156403 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `representative_representative` (\
  `person_ptr_id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_ka` varchar(300) DEFAULT NULL, \
  `submission_date` date DEFAULT NULL, \
  `entrepreneurial_salary` varchar(45) DEFAULT NULL, \
  `main_salary` varchar(45) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `family_status_en` varchar(45) DEFAULT NULL, \
  `family_status_ka` varchar(45) DEFAULT NULL, \
  `expenses_en` varchar(500) DEFAULT NULL, \
  `expenses_ka` varchar(500) DEFAULT NULL, \
  `property_assets_en` varchar(1500) DEFAULT NULL, \
  `property_assets_ka` varchar(1500) DEFAULT NULL, \
  PRIMARY KEY (`person_ptr_id`) \
) ENGINE=InnoDB AUTO_INCREMENT=101166 DEFAULT CHARSET=utf8;"

mysql.query(query)

# We loop through all the XML declarations files.
index_folder = 1.00
total_number = Dir[File.join(en_xml_folder, '**', '*')].count{ |file| File.file?(file) }
Dir.foreach(en_xml_folder) do |item|
    next if item == '.' or item == '..'
    
    puts "#{item}   \t\t(#{((index_folder / total_number.to_f) * 100).round(2)} % done)"

    # we open the English XML file
    f = File.open(en_xml_folder+item)
    doc = Nokogiri::XML(f)

    # we also open the Georgian XML file
    f_ka = File.open(ka_xml_folder+item)
    doc_ka = Nokogiri::XML(f_ka)

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

	# We're extracting all the necessary information, as this declaration was never inserted in the database.

	# Extracting the Georgian name
        first_page_ka = doc_ka.xpath('//page[@number="1"]/text')
        if first_page_ka[3].children.text.include? 'სახელი, გვარი:'
    	    full_name_ka = first_page_ka[4].children.text
        else
            # If we didn't find the name where it was supposed to be, we have to go through every line of the xml file, until we find it.
        end

        # Extract the family status
        family_status_en = ''
        family_status_ka = ''
	family_member_income = {} # list of keys for this hash: fam_name_en, fam_name_ka, fam_organisation fam_role_en, fam_role_ka, fam_gender, fam_date_of_birth, fam_income, fam_cars
	family_info = []
	all_family_info = []
        is_married = false
        i = 0
	for i in 0..first_page.length-1
	    
	    if first_page[i].children.text == "Place of Birth, Date of Birth: "
		# We first get information about the MP.
		family_member_income['full_name_en'] = full_name
		family_member_income['full_name_ka'] = full_name_ka
		place_dob_array = first_page[i+1].children.text.split(', ')
	        if place_dob_array.length == 2
		    family_member_income['place_of_birth'] = place_dob_array[0]
		    family_member_income['date_of_birth'] = place_dob_array[1]
		elsif place_dob_array.length > 2
		    family_member_income['place_of_birth'] = "#{place_dob_array[0..place_dob_array.length-2].join(', ')}"
		    family_member_income['date_of_birth'] = place_dob_array[place_dob_array.length-1]
		end
		family_member_income['role_en'] = '' # No role (relationship) assigned when we're dealing with MP
		family_member_income['role_ka'] = ''

		family_info << family_member_income
	    end

	    # We get here inforamtion about the relatives (available on the declaration first page)
	    if first_page[i].children.text == "Relationship"
		# The next line will be the first relative. And we'll have relative information until we see the data 'www.declaration.gov.ge'
		i += 1
		col_index = 0
		first_name = []
		last_name = []
		pob = []
		dob = []
		role = []
		family_member_income = {}
		while first_page[i].children.text != 'www.declaration.gov.ge'
		    if col_index == 0
			family_member_income = {}
			first_name = []
			last_name = []
			pob = []
			dob = []
			role = []
			first_name << first_page[i].children.text
		    elsif col_index == 1
			last_name << first_page[i].children.text			
		    elsif col_index == 2
			pob << first_page[i].children.text
		    elsif col_index == 3
			dob << first_page[i].children.text
		    else
			role << first_page[i].children.text

			family_member_income['full_name_en'] = "#{first_name.join(' ')} #{last_name.join(' ')}"
		    	family_member_income['place_of_birth_en'] = pob.join(' ')
		    	family_member_income['date_of_birth'] = dob.join(' ')
			family_member_income['role_en'] = role.join(' ')
			if family_member_income['role_en'] == "Spouse"
			    is_married = true
			end
			family_info << family_member_income
		    end

		    col_index = define_next_index(i,first_page,col_index,4)
		    i += 1
		end
	    end
	    i += 1
	end

	for i in 0..first_page_ka.length-1
	    relative_index = 0
	    
	    # We get information about the MP, in Georgian
	    if first_page_ka[i].children.text == "დაბადების ადგილი, დაბადების თარიღი: "
		place_dob_array = first_page_ka[i+1].children.text.split(', ')
		all_info = {}
	        if place_dob_array.length == 2
		    all_info['place_of_birth_ka'] = place_dob_array[0]
		elsif place_dob_array.length > 2
		    all_info['place_of_birth_ka'] = "#{place_dob_array[0..place_dob_array.length-2].join(', ')}"	
		end

		all_info = family_info[relative_index].merge(all_info)
		all_family_info << all_info

	    end

	    # We get information about the relatives, in Georgian
	    if first_page_ka[i].children.text == "კავშირი"
		# The next line will be the first relative, this time in Georgian. And like before, we'll have relative information until we see the data 'www.declaration.gov.ge'
		i += 1
		first_name = []
		last_name = []
		pob = []
		dob = []
		role = []
		col_index = 0
		relative_index = 1
		while i < first_page_ka.length && first_page_ka[i].children.text != 'www.declaration.gov.ge' && relative_index < family_info.length
		    if col_index == 0
			first_name = []
			last_name = []
			pob = []
			dob = []
			role = []
			family_member_income = {}
			first_name << first_page_ka[i].children.text
		    elsif col_index == 1
			last_name << first_page_ka[i].children.text			
		    elsif col_index == 2
			pob << first_page_ka[i].children.text
		    elsif col_index == 3
			#dob << first_page[i].children.text
		    else
			role << first_page_ka[i].children.text
			all_info = {}
			all_info['full_name_ka'] = "#{first_name.join(' ')} #{last_name.join(' ')}"
		    	all_info['place_of_birth_ka'] = pob.join(' ')
			all_info['role_ka'] = role.join(' ')

			all_info = family_info[relative_index].merge(all_info)
			all_family_info << all_info
			relative_index += 1
		    end
		
		    col_index = define_next_index(i,first_page_ka,col_index,4)
		    i += 1
		end
	    end
	    i += 1
	end

	insert_query = "INSERT INTO representative_declaration (ad_id, name_ka, submission_date) VALUES (#{declaration_id},'#{full_name_ka}',STR_TO_DATE('#{submission_date}','%d/%m/%Y'));"
        mysql.query(insert_query)

        if is_married
	    family_status_en = "Married"
    	    family_status_ka = "ქორწინებაში"
        else
	    family_status_en = "Single"
   	    family_status_ka = "დასაოჯახებელი"
        end

	family_income_array = []

        # Extracting main salary, and family income. 
	# This information can be found on page 8, 9 or even 10.
        salary_page = doc.xpath('//page[@number="8"]/text')
	message = 'Have you or your family members undertaken any type of paid work in Georgia or abroad,'
	right_info_found = is_it_the_right_page(salary_page, message)
	if !right_info_found
	    salary_page = doc.xpath('//page[@number="9"]/text')
	    right_info_found = is_it_the_right_page(salary_page, message)
	end

	if !right_info_found
	    salary_page = doc.xpath('//page[@number="10"]/text')
	    right_info_found = is_it_the_right_page(salary_page, message)
	end

        main_salary = 0.0
        i = 0
	col_index = 0
        family_income = {}	
	current_name = ''
	people_index_found = false
	people_index = 0
	while (people_index <= salary_page.length-1) && (!people_index_found)
	    if salary_page[people_index].children.text.include? 'December)'
		people_index_found = true
		people_index += 1
		break
	    else
		people_index += 1
	    end
	end
        for i in people_index..salary_page.length-1
	    if col_index == 0 # "Name" column
		current_name = salary_page[i].children.text.rstrip
		if !family_income.has_key?(current_name)
		    family_income[current_name] = 0.0
		end
	    elsif col_index == 1 # "Organisation" column
		#family_income["fam_organisation"] = salary_page[i].children.text
	    elsif col_index == 2 # "Job title" column
		#family_income["fam_title"] = salary_page[i].children.text
	    else # "Income received" column
		income_received = salary_page[i].children.text.split(' ')[0]
		family_income[current_name] += income_received.to_f
	    end
	    col_index = define_next_index(i,salary_page,col_index,3)
	end

        for i in 0..salary_page.length-1
	    if salary_page[i].children.text == full_name
	        while (i <= salary_page.length-1) && (!salary_page[i].children.text.include? 'GEL')
		    i += 1
	        end
		if i <= salary_page.length-1
	            amount = salary_page[i].children.text.split(' ')[0].to_f
	            main_salary += amount
		end
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
		while (i <= car_page.length-1) && (car_page[i].attributes["left"].value > car_page[i-1].attributes["left"].value) # while we are on the same line
		    car_info += "#{car_page[i].children.text} "
		    i += 1
		end
		car_info_hash[car_name_owner_en] = car_info
	    end
	end
    
        # Extracting entrepreneurial salary
	# This information can be found on page 7 or 8.
        salary_page = doc.xpath('//page[@number="7"]/text')
	right_info_found = false
        for i in 0..salary_page.length-1
	    if salary_page[i].children.text.include? 'Have you or your family members undertaken any type of entrepreneurial activity?'
		right_info_found = true
		break	    
	    end
	end
	if !right_info_found
	    salary_page = doc.xpath('//page[@number="8"]/text')
	end
        entr_salary = 0.0
        i = 0
        for i in 0..salary_page.length-1
	    if salary_page[i].children.text == full_name
	        while (i <= salary_page.length-1) && (!salary_page[i].children.text.include? 'GEL')
		    i += 1
	        end
		if i <= salary_page.length-1
	            amount = salary_page[i].children.text.split(' ')[0].to_f
	            entr_salary += amount
		end
  	    end
  	    i += 1
        end

    
        # Extracting the property assets
	property_page = doc.xpath('//page[@number="2"]/text')
	en_property_array = get_property_expenses_info("share in percentage","the property, as well as", property_page, full_name)
	property_page = doc_ka.xpath('//page[@number="2"]/text')
	ka_property_array = get_property_expenses_info("მისი პროცენტული წილი","თანამესაკუთრე თქვენი ოჯახის",property_page, full_name_ka)


        # Extracting the expenses from the english file (can be on page 11, 12 or 13)
	expenses_page = doc.xpath('//page[@number="11"]/text')
	message = ' any income or had any expenditures during the reporting period'
	right_info_found = is_it_the_right_page(expenses_page, message)
	if !right_info_found
	    expenses_page = doc.xpath('//page[@number="12"]/text')
	    right_info_found = is_it_the_right_page(expenses_page, message)
	end

	if !right_info_found
	    expenses_page = doc.xpath('//page[@number="13"]/text')
	    right_info_found = is_it_the_right_page(expenses_page, message)
	end
	en_expenses_array = get_property_expenses_info("expenditures","Amount (price) of income", expenses_page, full_name)

        # Extracting the expenses from the georgian file (can be on page 11, 12 or 13)
	expenses_page = doc_ka.xpath('//page[@number="11"]/text')
	message = 'დეკემბრის ჩათვლით თქვენი ან თქვენი ოჯახის წევრის ნებისმიერი შემოსავალი'
	right_info_found = is_it_the_right_page(expenses_page, message)
	if !right_info_found
	    expenses_page = doc_ka.xpath('//page[@number="12"]/text')
	    right_info_found = is_it_the_right_page(expenses_page, message)
	end

	if !right_info_found
	    expenses_page = doc_ka.xpath('//page[@number="13"]/text')
	    right_info_found = is_it_the_right_page(expenses_page, message)
	end
	ka_expenses_array = get_property_expenses_info("(ღირებულება)","ემოსავლის ან/და გასავლის ოდენო", expenses_page, full_name_ka)

        
        insert_query = "INSERT INTO representative_representative (submission_date, name_ka, entrepreneurial_salary, main_salary, declaration_id, family_status_en, \
	  	    family_status_ka, expenses_en, expenses_ka, property_assets_en, property_assets_ka) VALUES\
		    (STR_TO_DATE('#{submission_date}','%d/%m/%Y'),'#{full_name_ka}', #{entr_salary}, #{main_salary}, #{declaration_id}, '#{family_status_en}', \
		    '#{family_status_ka}', '#{en_expenses_array.join('; ')}', '#{ka_expenses_array.join('; ')}', '#{en_property_array.join('; ')}', '#{ka_property_array.join('; ')}');"

	mysql.query(insert_query)


	# Extracting now information about family members assets
	family_income.each do |key, value| # key is full english name, value is this person's income
	    i = 0
	    found_member = false
	    all_family_info.each do |member|
		if member['full_name_en'] == key
		    found_member = true
		    break;
		else
		    i += 1
		end
	    end

	    if found_member	    
		car_value = ''
	        if car_info_hash.has_key?(key)
		    car_value = car_info_hash[key]
	        else
		    car_value = ''
	        end

	        insert_query = "INSERT INTO representative_family_income (ad_id,submission_date,fam_name_en,fam_name_ka,fam_role_en,fam_role_ka,fam_gender, \
			    fam_date_of_birth,fam_income,fam_cars) VALUES \
			    (#{declaration_id},STR_TO_DATE('#{submission_date}','%d/%m/%Y'),'#{all_family_info[i]['full_name_en']}','#{all_family_info[i]['full_name_ka']}','#{all_family_info[i]['role_en']}','#{all_family_info[i]['role_ka']}','',\
			    STR_TO_DATE('#{all_family_info[i]['date_of_birth']}','%d/%m/%Y'),#{family_income[key]},'#{car_value}');"
	        mysql.query(insert_query)
	    end
	end

    end

    f.close
    f_ka.close

    index_folder += 1

end

puts "All done."


