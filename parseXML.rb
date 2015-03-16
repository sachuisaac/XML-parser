# SQL TABLE STRUCTURE
# create table templates (id INT NOT NULL AUTO_INCREMENT,
# 						label nvarchar(100) NOT NULL,
# 						parentID INT NOT NULL,
# 						LevelNumber INT NOT NULL,
# 						type nvarchar(100) NOT NULL, text nvarchar(100),
# 						PRIMARY KEY(id),
# 						FOREIGN KEY(parentID) references templates.id); 

require 'rexml/document'
require 'mysql'
include REXML

# SQL configuration and row value insertion.
def dataInsert(label, parentID, levelNumber, type, text)
	conn = Mysql.new("localhost","root","root",'ruby')
	conn.query("set foreign_key_checks = 0")
	puts "INSERT INTO templates VALUES (\'#{label}\', #{parentID}, #{levelNumber}, \'#{type}\', \'#{text}\')"
	rs = conn.query("INSERT INTO templates (label, parentID, LevelNumber, type, text) VALUES (\'#{label}\', #{parentID}, #{levelNumber}, \'#{type}\', \'#{text}\')")
	conn.close
end

# get the rowID of the last inserted row
def getIDofLastInsertedRow()
	conn = Mysql.new("localhost","root","root",'ruby')
	rs = conn.query("SELECT MAX(id) from templates")
	return rs.fetch_row()[0]
	conn.close
end

# return the rowID of the matching key or return nil
def getComponentID(key)
	conn = Mysql.new("localhost","root","root",'ruby')
	rs = conn.query("SELECT id from templates where type=\"#{key}\"")
	return rs.fetch_row()
	conn.close
end

#load the XML file and return the root.
def loadXML(file)
	xmlfile = File.new(file.strip)
	xmldoc = Document.new(xmlfile)
	xmldoc.root	
end

# The extract function is a recursive function to
# extract information from the XML file format and store it to database.
# parentID 	--> database id of the parent (Hierarchial Structure for menu and submenu)
# root 		--> root element of the XML file
# tag		--> XML tag
# label		--> label of each menu (used for storing the parent label)
# text		--> equivalent string of the menu (used for storing the parent text)
# level 	--> depth of the menu and submenu (1, 2, 3, ..)
def extract(parentID, root, tag, label, text=nil, level=nil)
	# substitute the psuedo menu tag or menu-item with the actual menu name along with the id
	# Formats as used in the XML file is menu1, menu2, ... and m1_item, m2_item, ...
	if tag == "menu"
		tag = "menu#{level}"
	elsif tag == "m_item"
		tag = "m#{level}_item"
	end
	# iterate through each tag with the matching tag name
	root.each_element(".//#{tag}") { |child|
		# step into the sections tag
		if child.name == 'sections'
			extract parentID, child, 'section', label
		# step into the section tag
		elsif child.name == 'section'
			# extract the value of key attribute under section tag
			key = child.attributes['key']
			# search for the component key e.g. Subjective have multiple templates etc.
			id = getComponentID(key)
			# if id is nil then new template is created in the database
			if id.nil?
				dataInsert(key, 0, 0, key, "")
			else
				parentID = id[0]
			end
			# step into the menu tag
			extract parentID, child, "menu", label, nil, 1

		elsif child.name == "menu#{level}"
			# extract the select type
			type = child.attributes['seltype']
			# if the select type is 'none' then by default it is a 'checkbox'
			type = type.match('none') ? "checkbox" : type
			label.gsub!("'","\\'")
			text = text.nil? ? label : text.gsub("'","\\'")
			# puts "<#{label},#{parentID},#{level-1},#{type},#{text}>"
			dataInsert( label, parentID, level-1, type, text)
			parentID = getIDofLastInsertedRow()
			extract parentID, child, "m_item", label, text, level

		elsif child.name == "m#{level}_item"
			label = child[1].text
			label.gsub!("'","\\'")
			text = child[3].text
			text = text.nil? ? label : text.gsub("'","\\'")
			type = child.attributes['childtype']
			# skip all that matches menu1, menu2 etc as childtype (the hierarchy is already taken care of)
			if !type.match(/menu./)
				if type.match(/picker/)
					child.each_element_with_attribute("pickertype") { |p|
						type = p.attributes["pickertype"]
					}
				end
				type = type.match('none') ? "checkbox" : type
				# puts "\t\t<#{label},#{parentID},#{level},#{type},#{text}>"

				dataInsert(label, parentID, level, type, text)
			end
			extract parentID, child, "menu", label, text, level.nil? ? 1 : level+1
		end
	}
end


# Accepting one command line arguement which can either be the path to a file
# consisting of all the filenames with the templates to parse,
# or the arguement can be a single template XML file.
# Note: the file should be located in the same directory as the rest of the XML files. 
if ARGV[0].match(/.txt/)
	fileList = File.open(ARGV[0])
	fileList.each { |file|
		root = loadXML(file)
		title = root.attributes['title']
		puts file, title
		extract(0, root, 'sections', title)
	}
else
	root = loadXML(ARGV[0])
	title = root.attributes['title']
	extract(0, root, 'sections', title)
end
