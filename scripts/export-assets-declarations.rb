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

	# The threshold is teh minimum number of pixels to consider between 2 fields, on the same line. 
	threshold = 0 
	
	case max_index # the max_index represents also the number of column, in this table.
	when 2
		threshold = 400
	when 3
		threshold = 250
	when 4
		threshold = 165
	when 5
		threshold = 145
	when 6
		threshold = 130
	end

    result = 0
    if page[i+1]
		line_index = page[i].attributes["left"].value.to_i
		next_line_index = page[i+1].attributes["left"].value.to_i
		
        if next_line_index - line_index > threshold
			line_top_index = page[i].attributes["top"].value.to_i
			next_line_top_index = page[i+1].attributes["top"].value.to_i
			if (col_index > max_index) || (next_line_top_index > line_top_index)
				result = -1
			else
				result = col_index + 1
			end
		elsif line_index - next_line_index > threshold
			result = -1
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
# This function defines what page on the PDF document 
# is to be scraped, in order to find specific info.
#
#########################################
def define_page_numbers(doc,title_to_find)
    page_number_array = []
    right_info_found = false
    number_of_pages = doc.xpath('//page').length
    for i in 1..number_of_pages
        page = doc.xpath("//page[@number='#{i}']/text")
        if is_it_the_right_page(page, title_to_find)
			page_number_array << i
		end
    end
    return page_number_array
end


#########################################
#
# Function that gets info from a cell, 
# without forgetting potential next lines, in same cell.
#
#########################################
def writeInfoFromCell(hash,key,text)
	if !text.include?('www.declaration.gov.ge')
		if hash[key]
			hash[key] += " "+text.gsub('\'','').gsub('; ','').gsub(',,','')
		else
			hash[key] = text.gsub('\'','').gsub('; ','').gsub(',,','')
		end
	end
end


def get_info_from_question (doc, doc_ka, messages, headers, keys)
	results = []
	index = 0
	
	istest = (messages['en'] == 'Do you or your family members own any movable property (except for cash, securities, bank')
	
	page_numbers = define_page_numbers(doc, messages['en'])
	
	page_numbers.each do |page_number|
		page = doc.xpath("//page[@number='#{page_number}']/text")
		header_has_several_parts = headers['en'].include? '|'
		
		for i in 0..page.length-1
			
			is_starting_cell = false
			if header_has_several_parts
				is_starting_cell = (page[i].children.text.rstrip == headers['en'].split('|')[1]) && (page[i-1].children.text.rstrip == headers['en'].split('|')[0])
			else
				is_starting_cell = (page[i].children.text.rstrip == headers['en'])
			end
			
			if is_starting_cell
				i += 1
				result = {}
				col_index = 0
				while i < page.length-1
					writeInfoFromCell(result, keys['en'][col_index], page[i].children.text)
					col_index = define_next_index(i, page, col_index, keys['en'].length)
					if col_index == -1
						if (result[keys['en'][0]] != '') # we test if the value of the first cell is empty. This happens when a cell is divided into 2, because of page break.
							results << result
						end
						result = {}
						col_index = 0
					end					
					i += 1
				end
				if (result[keys['en'][0]]) && (!result[keys['en'][0]].include? 'www.tcpdf.org')
					results << result
				end
				
			end
		end
	end
	
	
	page_numbers = define_page_numbers(doc_ka, messages['ka'])
	
	page_numbers.each do |page_number|
		page = doc_ka.xpath("//page[@number='#{page_number}']/text")
		header_has_several_parts = headers['ka'].include? '|'
		
		for i in 0..page.length-1
		
			is_starting_cell = false
			if header_has_several_parts
				is_starting_cell = (page[i].children.text.rstrip == headers['ka'].split('|')[1]) && (page[i-1].children.text.rstrip == headers['ka'].split('|')[0])
			else
				is_starting_cell = page[i].children.text.rstrip == headers['ka']
			end
			
		
			if is_starting_cell
				i += 1
				col_index = 0
				old_col_index = 0
				ka_data = {}
				while i <= page.length-1
					if keys['ka'][col_index] != ''
						writeInfoFromCell(ka_data, keys['ka'][col_index], page[i].children.text)
					end
					
					old_col_index = col_index
					col_index = define_next_index(i, page, col_index, keys['ka'].length)
										
					if col_index < old_col_index
						if (ka_data.has_key?(keys['ka'][0])) && (results[index])
							results[index] = (results[index]).merge(ka_data)
							# New line in the table, we increment the hash index of 1
							index += 1
						else
							# the number of data collected in this line is less than expected. This means that it was a truncated line, caused by page break
						end
						ka_data = {}
						col_index = 0
					end
					
					i += 1
					
				end
			end
		end
	end
		
	return results
	
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


# Postions added on 'declarations' table, to avoid costly query, when creating sql file for myparliament.ge
query = "CREATE TABLE IF NOT EXISTS `declarations` ( \
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `position_en` varchar(100) DEFAULT NULL, \
  `position_ka` varchar(100) DEFAULT NULL, \
  `dob` date DEFAULT NULL, \
  `submission_date` date DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `family_members` ( \
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `position_en` varchar(100) DEFAULT NULL, \
  `position_ka` varchar(100) DEFAULT NULL, \
  `pob_en` varchar(100) DEFAULT NULL, \
  `pob_ka` varchar(100) DEFAULT NULL, \
  `dob` date DEFAULT NULL, \
  `role_en` varchar(45) DEFAULT NULL, \
  `role_ka` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `family_income` ( \
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `organisation_en` varchar(100) DEFAULT NULL, \
  `organisation_ka` varchar(100) DEFAULT NULL, \
  `job_title_en` varchar(100) DEFAULT NULL, \
  `job_title_ka` varchar(100) DEFAULT NULL, \
  `income` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `entrepreneurial_activities` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `address_en` varchar(500) DEFAULT NULL, \
  `address_ka` varchar(500) DEFAULT NULL, \
  `partnership_en` varchar(100) DEFAULT NULL, \
  `partnership_ka` varchar(100) DEFAULT NULL, \
  `registration_en` varchar(300) DEFAULT NULL, \
  `registration_ka` varchar(300) DEFAULT NULL, \
  `period_en` varchar(100) DEFAULT NULL, \
  `period_ka` varchar(100) DEFAULT NULL, \
  `income` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `expenses` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `income_en` varchar(300) DEFAULT NULL, \
  `income_ka` varchar(300) DEFAULT NULL, \
  `amount_en` varchar(100) DEFAULT NULL, \
  `amount_ka` varchar(100) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `property_assets` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `name_share_en` varchar(200) DEFAULT NULL, \
  `name_share_ka` varchar(200) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `property_en` varchar(100) DEFAULT NULL, \
  `property_ka` varchar(100) DEFAULT NULL, \
  `location_en` varchar(300) DEFAULT NULL, \
  `location_ka` varchar(300) DEFAULT NULL, \
  `common_owners_en` varchar(300) DEFAULT NULL, \
  `common_owners_ka` varchar(300) DEFAULT NULL, \  
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `movable_properties` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `owner_name_en` varchar(100) DEFAULT NULL, \
  `owner_name_ka` varchar(100) DEFAULT NULL, \
  `property_type_en` varchar(100) DEFAULT NULL, \
  `property_type_ka` varchar(100) DEFAULT NULL, \
  `details_en` varchar(300) DEFAULT NULL, \
  `details_ka` varchar(300) DEFAULT NULL, \
  `common_owners_en` varchar(300) DEFAULT NULL, \
  `common_owners_ka` varchar(300) DEFAULT NULL, \  
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `securities` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `declaration_id` int(11) DEFAULT NULL, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `issuer_en` varchar(100) DEFAULT NULL, \
  `issuer_ka` varchar(100) DEFAULT NULL, \
  `type_en` varchar(100) DEFAULT NULL, \
  `type_ka` varchar(100) DEFAULT NULL, \
  `value_en` varchar(100) DEFAULT NULL, \
  `value_ka` varchar(100) DEFAULT NULL, \
  `quantity` varchar(100) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `bank_accounts` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `bank_name_en` varchar(500) DEFAULT NULL, \
  `bank_name_ka` varchar(500) DEFAULT NULL, \
  `account_type_en` varchar(500) DEFAULT NULL, \
  `account_type_ka` varchar(500) DEFAULT NULL, \
  `amount` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `cash` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `amount` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `active_contracts` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `subject_en` varchar(300) DEFAULT NULL, \
  `subject_ka` varchar(300) DEFAULT NULL, \
  `signature_en` varchar(300) DEFAULT NULL, \
  `signature_ka` varchar(300) DEFAULT NULL, \
  `income_en` varchar(45) DEFAULT NULL, \
  `income_ka` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

mysql.query(query)

query = "CREATE TABLE IF NOT EXISTS `gifts` (\
  `id` int(11) NOT NULL AUTO_INCREMENT, \
  `name_en` varchar(100) DEFAULT NULL, \
  `name_ka` varchar(100) DEFAULT NULL, \
  `declaration_id` int(11) DEFAULT NULL, \
  `type_price_en` varchar(100) DEFAULT NULL, \
  `type_price_ka` varchar(100) DEFAULT NULL, \
  `relationship_en` varchar(45) DEFAULT NULL, \
  `relationship_ka` varchar(45) DEFAULT NULL, \
  PRIMARY KEY (`id`) \
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"

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
    dob = ''
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
    query = "SELECT count(1) FROM declarations WHERE declaration_id = #{declaration_id};"
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

        # Extract the family status (first page)
	    # --------------------------------------
        family_status_en = ''
        family_status_ka = ''
		position_en = ''
		position_ka = ''
		family_member = {} # list of keys for this hash: name_en, name_ka, organisation, role_en, role_ka, gender, date_of_birth, income, cars
        is_married = false
        i = 0
		for i in 0..first_page.length-1

			if first_page[i].children.text == "Place of Birth, Date of Birth: "
    			# We get information about the MP.
    			family_member['full_name_en'] = full_name
    			family_member['full_name_ka'] = full_name_ka
    			place_dob_array = first_page[i+1].children.text.split(', ')
    			if place_dob_array.length == 2
				    family_member['place_of_birth'] = place_dob_array[0]
				    family_member['date_of_birth'] = place_dob_array[1]
			    elsif place_dob_array.length > 2
				    family_member['place_of_birth'] = "#{place_dob_array[0..place_dob_array.length-2].join(', ')}"
				    family_member['date_of_birth'] = place_dob_array[place_dob_array.length-1]
			    end
			    dob = family_member['date_of_birth']
			end

			if first_page[i].children.text == "Organisation, Position:"
    			# We get information about the person's position
    			family_member['position_en'] = first_page[i+1].children.text
			end

			i += 1
		end

		for i in 0..first_page_ka.length-1
			relative_index = 0
			
			# We get information about the MP, in Georgian
			if first_page_ka[i].children.text == "დაბადების ადგილი, დაბადების თარიღი: "
    			place_dob_array = first_page_ka[i+1].children.text.split(', ')
    			#all_info = {}
				if place_dob_array.length == 2
			        family_member['place_of_birth_ka'] = place_dob_array[0]
			    elsif place_dob_array.length > 2
				    family_member['place_of_birth_ka'] = "#{place_dob_array[0..place_dob_array.length-2].join(', ')}"	
			    end
			end

			if first_page_ka[i].children.text == "სამსახური, დაკავებული (ყოფილი) თანამდებობა:"
    			# We get information about the person's position, in Georgian
    			j = i+1
    			position_ka = first_page_ka[j].children.text
    			line_index = first_page_ka[j].attributes["left"].value.to_i
    			next_line_index = first_page_ka[j+1].attributes["left"].value.to_i
			    while next_line_index - line_index > 100
    				# we're still on the same line, and gathering information about the position.
    				position_ka += " " + first_page_ka[j+1].children.text
    				j += 1
    				next_line_index = first_page_ka[j+1].attributes["left"].value.to_i
		    	end
		    	family_member['position_ka'] = position_ka
			end

			i += 1
		end
		
		if is_married
	        family_status_en = "Married"
    	    family_status_ka = "ქორწინებაში"
        else
    	    family_status_en = "Single"
       	    family_status_ka = "დასაოჯახებელი"
        end


		# We insert the main information about the current public official.
		insert_query = "INSERT INTO family_members (declaration_id, name_en, name_ka, position_en, position_ka, pob_en, pob_ka, dob, role_en, role_ka) VALUES\
				(#{declaration_id}, '#{family_member['full_name_en']}', '#{family_member['full_name_ka']}', '#{family_member['position_en']}', '#{family_member['position_ka']}', '#{family_member['place_of_birth']}', \
				 '#{family_member['place_of_birth_ka']}', STR_TO_DATE('#{family_member['date_of_birth']}','%d/%m/%Y'), '#{family_status_en}', '#{family_status_ka}');"
        mysql.query(insert_query)


		insert_query = "INSERT INTO declarations (declaration_id, name_en, name_ka, position_en, position_ka, dob, submission_date) VALUES (#{declaration_id}, '#{full_name}', '#{full_name_ka}', '#{family_member['position_en']}', '#{family_member['position_ka']}', STR_TO_DATE('#{dob}','%d/%m/%Y'), STR_TO_DATE('#{submission_date}','%d/%m/%Y'));"
        mysql.query(insert_query)
        
        
        # Extracting data about family members
        # ------------------------------------
        messages = {}
		messages['en'] = 'Data about family members (spouse, children, other persons)'
		messages['ka'] = 'თქვენი ოჯახის წევრების (მეუღლე, არასრულწლოვანი შვილი, (გერი),'
		headers = {}
		headers['en'] = 'Relationship'
		headers['ka'] = 'ნათესაური ან სხვაგვარი|კავშირი'
		keys = {}
		keys['en'] = ['first_name_en','last_name_en','pob_en','dob','relationship_en']
		keys['ka'] = ['first_name_ka','last_name_ka','pob_ka','dob','relationship_ka']
		
		members = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		members.each do |member|
			insert_query = "INSERT INTO family_members (declaration_id, name_en, name_ka, position_en, position_ka, pob_en, pob_ka, dob, role_en, role_ka) VALUES\
				(#{declaration_id}, '#{member['first_name_en']} #{member['last_name_en']}', '#{member['first_name_ka']} #{member['last_name_ka']}', '', '', '#{member['pob_en']}', \
				 '#{member['pob_ka']}', STR_TO_DATE('#{member['dob']}','%d/%m/%Y'), '#{member['relationship_en']}', '#{member['relationship_ka']}');"

			mysql.query(insert_query)
		end
		
		
		# Extracting data about securities
        # --------------------------------
        messages = {}
		messages['en'] = 'Do you or your family members own any securities?'
		messages['ka'] = 'თქვენი, თქვენი ოჯახის წევრის საკუთრებაში არსებული ფასიანი ქაღალდები'
		headers = {}
		headers['en'] = 'Quantity'
		headers['ka'] = 'ფასიანი ქაღალდების|რაოდენობა'
		keys = {}
		keys['en'] = ['owner_en','issuer_en','type_en','value_en','quantity']
		keys['ka'] = ['owner_ka','issuer_ka','type_ka','value_ka','quantity']
		
		securities = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		securities.each do |security|
			insert_query = "INSERT INTO securities (declaration_id, name_en, name_ka, issuer_en, issuer_ka, type_en, type_ka, value_en, value_ka, quantity) VALUES\
				(#{declaration_id}, '#{security['owner_en']}', '#{security['owner_ka']}', '#{security['issuer_en']}', '#{security['issuer_ka']}', '#{security['type_en']}', '#{security['type_ka']}', \
				 '#{security['value_en']}', '#{security['value_ka']}', '#{security['quantity']}');"

			mysql.query(insert_query)
		end
		        

		# Extracting main salary, and family income. 
		# ------------------------------------------
        messages = {}
		messages['en'] = 'Have you or your family members undertaken any type of paid work in Georgia or abroad,'
		messages['ka'] = 'თველოში ან სხვა ქვეყანაში, თქვენი, თქვენი ოჯახის წევრის მიერ შესრულებული ნებისმიერი ა'
		headers = {}
		headers['en'] = 'December)'
		headers['ka'] = 'პირველი იანვრიდან 31 დეკემბრის|ჩათვლით მიღებული შემოსავალი'
		keys = {}
		keys['en'] = ['name_en','organisation_en','title_en','income']
		keys['ka'] = ['name_ka','organisation_ka','title_ka','income']
		
		members = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		members.each do |member|
			insert_query = "INSERT INTO family_income (declaration_id, name_en, name_ka, organisation_en, organisation_ka, job_title_en, job_title_ka, income) VALUES\
				(#{declaration_id}, '#{member['name_en']}', '#{member['name_ka']}', '#{member['organisation_en']}', '#{member['organisation_ka']}', '#{member['title_en']}', \
				 '#{member['title_ka']}', '#{member['income']}');"

			mysql.query(insert_query)
		end
			
					
		# Extracting information about movable properties
		# -----------------------------------------------
		messages = {}
		messages['en'] = 'Do you or your family members own any movable property (except for cash, securities, bank'
		messages['ka'] = 'თქვენი, თქვენი ოჯახის წევრის საკუთრებაში არსებული მოძრავი ქონება (ფასიანი ქაღალდების'
		headers = {}
		headers['en'] = 'percentages should be|indicated)'
		headers['ka'] = 'თანამესაკუთრე თქვენი ოჯახის წევრია|მიუთითეთ მისი პროცენტული წილი)'
		keys = {}
		keys['en'] = ['owner_en','type_en','details_en','common_owners_en']
		keys['ka'] = ['owner_ka','type_ka','details_ka','common_owners_ka']
		
		properties = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		properties.each do |property|
			this_name_en = ''
			this_name_ka = ''
			if property['owner_en']
				name_en_array = property['owner_en'].split(' ')
				if (name_en_array) && (name_en_array.length >= 2)
					this_name_en = name_en_array[0] + ' ' + name_en_array[1]
				end
			end
			if property['owner_ka']
				name_ka_array = property['owner_ka'].split(' ')
				if (name_ka_array) && (name_ka_array.length >= 2)
					this_name_ka = name_ka_array[0] + ' ' + name_ka_array[1]
				end
			end
			insert_query = "INSERT INTO movable_properties (name_en, name_ka, owner_name_en, owner_name_ka, declaration_id, property_type_en, property_type_ka, details_en, details_ka, common_owners_en, common_owners_ka) VALUES\
				('#{this_name_en}','#{this_name_ka}','#{property['owner_en']}', '#{property['owner_ka']}', #{declaration_id}, '#{property['type_en']}', '#{property['type_ka']}', \
				'#{property['details_en']}', '#{property['details_ka']}', '#{property['common_owners_en']}', '#{property['common_owners_ka']}');"

			mysql.query(insert_query)
		end

	
		# Extracting information about bank accounts
		# ------------------------------------------
		messages = {}
		messages['en'] = 'Do you or your family members have bank accounts in Georgian or foreign banks?'
		messages['ka'] = 'საქართველოს ან სხვა ქვეყნის საბანკო ან/და სხვა საკრედიტო დაწესებულებებში არსებული ანგარიში ან/და შენატან'
		headers = {}
		headers['en'] = 'Amount of credit or debit on|the account'
		headers['ka'] = 'ანგარიშზე ან/და შენატანზე არსებული|ნაშთი (კრედიტი ან დებეტი)'
		keys = {}
		keys['en'] = ['owner_en','bank_name_en','account_type_en','amount']
		keys['ka'] = ['owner_ka','bank_name_ka','account_type_ka','amount_ka']
		
		bank_accounts = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		bank_accounts.each do |account|
			insert_query = "INSERT INTO bank_accounts (name_en, name_ka, declaration_id, bank_name_en, bank_name_ka, account_type_en, account_type_ka, amount) VALUES\
				('#{account['owner_en']}', '#{account['owner_ka']}', #{declaration_id}, '#{account['bank_name_en']}', '#{account['bank_name_ka']}', \
				'#{account['account_type_en']}', '#{account['account_type_ka']}', '#{account['amount']}');"

			mysql.query(insert_query)
		end
		

		# Extracting information about gifts
		# ----------------------------------
		messages = {}
		messages['en'] = 'Have you or your family members received any gifts valued at more than 500 GEL'
		messages['ka'] = 'თქვენი, თქვენი ოჯახის წევრის მიერ წინა წლის პირველი იანვრიდან 31 დეკემბრის ჩათვლით მიღებული'
		headers = {}
		headers['en'] = 'Relationship'
		headers['ka'] = 'გამცემის მიმღებთან კავშირი'
		keys = {}
		keys['en'] = ['name_en','type_price_en','relationship_en']
		keys['ka'] = ['name_ka','type_price_ka','relationship_ka']
		
		gifts = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		gifts.each do |gift|
			insert_query = "INSERT INTO gifts (name_en, name_ka, declaration_id, type_price_en, type_price_ka, relationship_en, relationship_ka) VALUES\
				('#{gift['name_en']}', '#{gift['name_ka']}', #{declaration_id}, '#{gift['type_price_en']}', '#{gift['type_price_ka']}', \
				'#{gift['relationship_en']}', '#{gift['relationship_ka']}');"

			mysql.query(insert_query)
		end
    
       
		# Extracting hold cash information
		# --------------------------------
		messages = {}
		messages['en'] = 'Do you or your family members hold cash valued at more than 4,000 GEL (2,400 USD approximately)?'
		messages['ka'] = 'თქვენი, თქვენი ოჯახის წევრის საკუთრებაში არსებული ნაღდი ფულადი თანხა, რომლის ოდენობა აღემატება 4 000 ლარს'
		headers = {}
		headers['en'] = 'Amount of cash in the original currency'
		headers['ka'] = 'ფულადი თანხის ოდენობა შესაბამის ვალუტაში'
		keys = {}
		keys['en'] = ['name_en','amount']
		keys['ka'] = ['name_ka','amount_ka']
		
		cashs = get_info_from_question(doc, doc_ka, messages, headers, keys)
		
		cashs.each do |cash|
			insert_query = "INSERT INTO cash (name_en, name_ka, declaration_id, amount) VALUES\
				('#{cash['name_en']}', '#{cash['name_ka']}', #{declaration_id}, '#{cash['amount']}');"

			mysql.query(insert_query)
		end
		

		# Extracting active contracts information
		# ---------------------------------------
		messages = {}
		messages['en'] = 'Have you or your family members had any active contracts dating back from 1 January'
		messages['ka'] = 'დადებული ან/და მოქმედი ხელშეკრულება, რომლის საგნის ღირებულება აღემატება 3000 ლარს'
		headers = {}
		headers['en'] = 'December)'
		headers['ka'] = 'დეკემბრის ჩათვლით ხელშეკრულებით|მიღებული მატერიალური შედეგი'
		keys = {}
		keys['en'] = ['name_en','subject_en','signature_en','income_en']
		keys['ka'] = ['name_ka','subject_ka','signature_ka','income_ka']
		
		contracts = get_info_from_question(doc, doc_ka, messages, headers, keys)

		contracts.each do |contract|
			insert_query = "INSERT INTO active_contracts (name_en, name_ka, declaration_id, subject_en, subject_ka, signature_en, signature_ka, income_en, income_ka) VALUES\
				('#{contract['name_en']}', '#{contract['name_ka']}', #{declaration_id}, '#{contract['subject_en']}', '#{contract['subject_ka']}', '#{contract['signature_en']}', '#{contract['signature_ka']}', \
				 '#{contract['income_en']}', '#{contract['income_ka']}');"

			mysql.query(insert_query)
		end

	
		# Extracting entrepreneurial salary
		# ---------------------------------
		messages = {}
		messages['en'] = 'Have you or your family members undertaken any type of entrepreneurial activity?'
		messages['ka'] = 'საქართველოში ან სხვა ქვეყანაში თქვენი, თქვენი ოჯახის წევრის მონაწილეობა სამეწარმეო საქმიანობაში'		
		headers = {}
		headers['en'] = '31 December)'
		headers['ka'] = 'მიღებული შემოსავალი'
		keys = {}
		keys['en'] = ['name_en','address_en','partnership_en','registration_en','period_en','income']
		keys['ka'] = ['name_ka','address_ka','partnership_ka','registration_ka','period_ka','income_ka']
		
		entrepreneurs = get_info_from_question(doc, doc_ka, messages, headers, keys)

		entrepreneurs.each do |activity|
			insert_query = "INSERT INTO entrepreneurial_activities (name_en, name_ka, declaration_id, address_en, address_ka, partnership_en, partnership_ka, registration_en, registration_ka, period_en, period_ka, income) VALUES\
				('#{activity['name_en']}', '#{activity['name_ka']}', #{declaration_id}, '#{activity['address_en']}', '#{activity['address_ka']}', '#{activity['partnership_en']}', '#{activity['partnership_ka']}', \
				 '#{activity['registration_en']}', '#{activity['registration_ka']}', '#{activity['period_en']}', '#{activity['period_ka']}', '#{activity['income']}');"
			
			mysql.query(insert_query)
		end		
		

		# Extracting the property assets
		# ------------------------------
		messages = {}
		messages['en'] = 'Do you or your family members own real estate?'
		messages['ka'] = 'თქვენი, თქვენი ოჯახის წევრის საკუთრებაში არსებული უძრავი ქონება'		
		headers = {}
		headers['en'] = 'the property, as well as their|share in percentage'
		headers['ka'] = 'მიუთითეთ მისი პროცენტული წილი)'
		keys = {}
		keys['en'] = ['name_share_en','property_en','location_en','common_owners_en']
		keys['ka'] = ['name_share_ka','property_ka','location_ka','common_owners_ka']
		
		assets = get_info_from_question(doc, doc_ka, messages, headers, keys)

		assets.each do |asset|
			this_name_en = ''
			this_name_ka = ''
			if asset['name_share_en']
				name_en_array = asset['name_share_en'].split(' ')
				if (name_en_array) && (name_en_array.length >= 2)
					this_name_en = name_en_array[0] + ' ' + name_en_array[1]
				end
			end
			if asset['name_share_ka']
				name_ka_array = asset['name_share_ka'].split(' ')
				if (name_ka_array) && (name_ka_array.length >= 2)
					this_name_ka = name_ka_array[0] + ' ' + name_ka_array[1]
				end
			end
			insert_query = "INSERT INTO property_assets (name_en, name_ka, name_share_en, name_share_ka, declaration_id, property_en, property_ka, location_en, location_ka, common_owners_en, common_owners_ka) VALUES\
				('#{this_name_en}','#{this_name_ka}','#{asset['name_share_en']}', '#{asset['name_share_ka']}', #{declaration_id}, '#{asset['property_en']}', '#{asset['property_ka']}', '#{asset['location_en']}', '#{asset['location_ka']}', \
				 '#{asset['common_owners_en']}', '#{asset['common_owners_ka']}');"

			mysql.query(insert_query)
		end


		# Extracting the expenses 
		# -----------------------	
		messages = {}
		messages['en'] = 'your family members received any income or had any expenditures during the reporting'
		messages['ka'] = 'პირველი იანვრიდან 31 დეკემბრის ჩათვლით თქვენი ან თქვენი ოჯახის წევრის ნებისმიერი შემოსავალი'		
		headers = {}
		headers['en'] = 'Amount (price) of income or/and|expenditures'
		headers['ka'] = 'შემოსავლის ან/და გასავლის ოდენობა|(ღირებულება)'
		keys = {}
		keys['en'] = ['name_en','income_en','amount_en']
		keys['ka'] = ['name_ka','income_ka','amount_ka']
		
		expenses = get_info_from_question(doc, doc_ka, messages, headers, keys)

		expenses.each do |expense|
			insert_query = "INSERT INTO expenses (name_en, name_ka, declaration_id, income_en, income_ka, amount_en, amount_ka) VALUES\
				('#{expense['name_en']}', '#{expense['name_ka']}', #{declaration_id}, '#{expense['income_en']}', '#{expense['income_ka']}', '#{expense['amount_en']}', '#{expense['amount_ka']}');"

			mysql.query(insert_query)
		end		



    end

    f.close
    f_ka.close

    index_folder += 1

end

puts "All done."
