# xml-parser
Task : Extract information from a structured XML file and store into mysql database with the heirarchy information intact.

Input: a xml file captured from a site (sample file included)

Ouput: table with all the relevant information required by the client.

DETAILED EXPLANATION OF THE XML FORMAT

<template>
  |
  |----<sections>
  		|
  		|----<section>
  			  |
  			  |----<menu1>
  			  		|
  			  		|----<m1_item>
  			  		|		|
  			  		|		|----<label>
  			  		|		|----<macro>
  			  		|		|----<menu2>
  			  		|		     |
  			  		|		     |----<m2_item>
  			  		|		     	   |
  			  		|		     	   |----<label>
  			  		|		     	   |----<text>
  			  		|
  			  		|----<m1_item>
  			  			  |
  			  			  |-----<...

* Each XML file is a template in the application.
* The <template> tag in the XML has an attribute, title:"name_of_the_template".
* The processing starts under template tag >> sections tag >> section tag
* The <section> has an attribute, key:"component", where the component determines its immediate parent.
	Example: The templates under subjective has key:"subjective"
			 The templates under objective has key:"exam-name" where each template is associated with exam-name template (many-one relation).
* The hierarchy in the menus is represented as <menu1> -- level 1, <menu2> -- level 2, and so on.
* There are two functionalities incorporated in the templates,
	* Selection of the menu-item depending on the type of selection
	* Generation of strings corresponding to the selection in grammatically (close to) correct syntax.
* Each <menu1>, <menu2> etc has only one attribute, seltype:"stype" where stype can be 
	* 'multiple'			--this selectiontype enables selection of multiple menu-items
	* 'single'				--this selectiontype enables selection of only one menu-item.
* Each <m1_item>, <m2_item> etc has an attribute, childtype:"ctype" where ctype can be
	* 'menu2' or 'menu3'	--this childtype indicates the existence of submenu according to the hierarchy( menu1 << menu2 << menu3)
	* 'none'				--this childtype indicates checkbox input.
	* 'yn' 					--this childtype indicates Yes/No input(buttons).
	* 'picker'				--this childtype indicates presence of <picker> in that item
* The <picker> has an attribute, pickertype="ptype" where ptype can be
	* 'alpha'				--this pickertype accepts short text containing alphanumeric or symbols,
	* 'number'				--this pickertype accepts only number input(keypad),
	* 'date'				--this pickertype accepts only calender input(calender picker).
* The value under <label> in each menu-item is the text displayed in the UI menu.
* The value under <macro> and <text> is the string used in sentence creation upon completion of selection.
* If the <text> is missing under a menu-item, then by default the value from <label> is used for sentence generation
* Few symbols used under <text> and <macro>,
	* {cr}					--carriage return, during generation of string.
	* {xxx}					--placeholder for the corresponding text generated lower down the hierarchy of the menu.




# Usage: ruby parseXML.rb sample.xml
