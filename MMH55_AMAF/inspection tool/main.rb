# Author: dredknight
# Requirements: Ruby Shoes 3.3.8 or higher
#
# Usage: Unpack data.pak or MMH55-index.pak and point as @SOURCE GameMechanics\Creature\Creatures directory.
# HP_gain is the % of hp to be added to the current one. 0.25 is 25%. Float results are rounded up.
# Debug: 0 is disabled; 1 will give output of files changed and hp comparison in Shoes console

require 'nokogiri'
require 'fileutils'

def directory_exists? (directory) ( mkpath(directory) unless File.directory?(directory) ) end

def fix_string str
	length, count, new_str = str.length, 0, ""
	str.each_char { |c| c == "\\" ? new_str << "/" : new_str << c }
	return new_str
end

def number_or_nil(string)
	result = Integer(string)
	rescue
		result = string
	return result;
end
	
def getTiles(doc, path, id, n, tileName )
	tileX, tileY = [], []
	doc.xpath(path).each_with_index do |c, i|
		x = c.xpath("x").text
		y = c.xpath("y").text
		tileX << StringToInt(x)
		tileY << StringToInt(y)
	end
	@H5MapObjects[:"#{id}"][:"#{tileName}"][:"#{n}"] = Hash.new(nil);
	@H5MapObjects[:"#{id}"][:"#{tileName}"][:"#{n}"] = { "x": tileX, "y": tileY }
end
	
def getPossessionTile(doc, path, id, n)
	x = doc.xpath("#{path}/x").text
	y = doc.xpath("#{path}/y").text
	possessionTileX = [ StringToInt(x) ]
	possessionTileY = [ StringToInt(y) ]
	@H5MapObjects[:"#{id}"][:"possessionTiles"][:"#{n}"] = Hash.new(nil);
	@H5MapObjects[:"#{id}"][:"possessionTiles"][:"#{n}"] = { "x": possessionTileX, "y": possessionTileY }
end

def printXML(name, item, f, depth, last=0)
	sign = ( last == 0 ? "," : "" )
	depth.times { f.write("\t") }
	if depth == 0 then
		f.write("#{name} = ")
	else
		f.write("[\"#{name}\"] = ")
	end
	i = 0;
	if item.class == Hash then
		f.write("{ \n")
		item.each do |k, v|
			v_last = (k == item.keys.last ? 1 : 0 ) 
			printXML(k, v, f, depth+1, v_last)
		end
		depth.times { f.write("\t") }
		f.write(" }#{sign}\n")
	elsif item.class == Array then
		f.write("{ ")
		item.each_with_index do |b, i|
			char_space = ( b<0 ? " " : "  " )
			char_comma = ( i != item.count-1 ? ", " : "" )
			f.write("[#{i}] =#{char_space}#{b}#{char_comma}")
		end
		f.write(" }#{sign}\n")
	elsif item.class == Fixnum
		f.write("#{item}#{sign}\n")
	else
		f.write("\"#{item}\"#{sign}\n")
	end	
end

def StringToInt(str)

	if str[0] == '-' then
		value = str[1].to_i
		num = 0 - value
	else
		num = str.to_i
	end
	return num
end

def get_tree (src, &block)	
	Dir.entries(src).reject{ |rj| rj == '..' or rj == '.' }.each_with_index do |f, i|
		debug("#{src}\\#{f}") if @var_debug == 1
		curDir = "#{src}\\#{f}"
		File.directory?("#{src}\\#{f}")? get_tree(curDir, &block ) : ( block.call(curDir) )
	end
end
	
def get_and_update_unitHp (file)
	doc = File.open("#{file}") { |f| Nokogiri::XML(f) }
	doc.xpath("Creature/Health").each do |hp|
		hp_num = hp.text.to_i
			debug("old hp_num: #{hp.text}; new hp: #{(hp_num + hp_num*@hp_gain).ceil}") if @var_debug == 1
		hp.content = "#{(hp_num + hp_num*@hp_gain).ceil}"
		File.write(file, doc)
	end
end

def update_objectData_to_xml (file)
	doc = File.open("#{file}") { |f| Nokogiri::XML(f) }
	@AdvMapShared.each do |adv|
		if doc.at_xpath(adv) != nil then
			######### Gatierhing object data
			razed = doc.at_xpath("#{adv}/RazedStatic")
			razed['href'] = '/MapObjects/RazedTowns/Fake_PeasantHut.xdb#xpointer(/AdvMapStaticShared)'
			destDir = ((@f_wr2 + file.split('data')[1]).split('\\'))
			file2 = destDir.pop
			destDir = destDir.join('/')
			directory_exists?(destDir)
			debug("########DestDir is #{destDir}") if @var_debug == 1;
			######### creating pak file for DATA folder
			File.write("#{destDir}/#{file2}", doc)
			break
		end
	end
end

def get_ObjectData_to_lua (file)
	doc = File.open("#{file}") { |f| Nokogiri::XML(f) }
	num = 0
	for c in @AdvMapShared do
		if doc.at_xpath(c) != nil then
			type = doc.at_xpath("#{c}/Type").text
			if @H5MapObjects.key?(:"#{type}") then
				num = @H5MapObjects[:"#{type}"][:"entries"] + 1
				@H5MapObjects[:"#{type}"][:"entries"] = num
			else 
				num = 0
				@H5MapObjects[:"#{type}"] = Hash.new(nil)
				@H5MapObjects[:"#{type}"][:"blockedTiles"] = Hash.new(nil)
				@H5MapObjects[:"#{type}"][:"activeTiles"] = Hash.new(nil)
				@H5MapObjects[:"#{type}"][:"possessionTiles"] = Hash.new(nil)
				@H5MapObjects[:"#{type}"][:"sharedType"] = c
				@H5MapObjects[:"#{type}"][:"entries"] = num
			end
			getTiles(doc, "#{c}/blockedTiles/Item", type, num, "blockedTiles" )
			getTiles(doc, "#{c}/activeTiles/Item", type, num, "activeTiles" )
			getPossessionTile(doc, "#{c}/PossessionMarkerTile", type, num )
		end
	end
end

def draw_matrix(array, box, median)
	array.each_with_index do |y,yi|
		y.each_with_index do |x, xi|
			box.append do
				stroke gray; strokewidth 1
				if yi==median  and xi==median then
					stroke black; strokewidth 2
				end
				case x 
					when 0 then fill red
					when 1 then fill white 
					when 2 then fill orange
				end
				rect 23*xi, 23*yi, 22, 22
			end
		end
	end
end

def fill_matrix(matrix, hash, median, value)
	debug("fill is #{hash[:"x"]}")
	sumX, sumY, sumDiv = 0, 0, hash[:"x"].count
	sumDiv = 1 if sumDiv == 0
	hash[:"x"].each_with_index do |x,i|
		y = hash[:"y"][i]
		matrix[median + y][median + x] = value
		sumX = sumX + x
		sumY = sumY + y
	end
	tiletype = (value == 0? "blockedTiles" : "activeTiles")
end

########### MAIN FUCTIONS #######################

def unitHp
	source = Dir.pwd + '\change unit hp\MMH55-Index\GameMechanics\Creature\Creatures'
	get_tree(source, &method(:get_and_update_unitHp))
end

################### Menu functions #########################################

def mainmenu
	left, top = 300, 30
	@canvas.clear do
		button("Modify AdvMapShared xdbs",   left: left, top: top +   0, width: 300) { modify_AdvMapShared }
		button("Inspect AdvMapShared xdbs",  left: left, top: top +  50, width: 300) { analyze_AdvMapShared }
		button("Modify Creature xdbs", 		 left: left, top: top + 100, width: 300) { nil }
	end
end

def modify_AdvMapShared 
	source = Dir.pwd + '/data/MapObjects'
	@f_wr2 = Dir.pwd  + '/output'
	@canvas.clear do
		button("Main Menu", left: 430, top: 0, width: 140, tooltip: "Go to main menu") { mainmenu }
		## Input dir 
		para "Input dir", left: 30, top: 50
		dir_in = edit_line("#{source}" , left: 115, top: 50, height: 30, width: 550, tooltip: "Directory to inspect from", state: 'disabled') { |t| source = t.text }
		button("Browse", left: 690, top: 50, width: 100, tooltip: "Browse directory") { dir_in.text = fix_string(ask_open_folder) }
		## Output dir
		para "Output dir", left: 30, top: 90
		dir_out = edit_line("#{@f_wr2}", left: 115, top: 90, height: 30, width: 550, tooltip: "Directory to to write in", state: 'disabled') { |t| @f_wr2 = t.text }
		button("Browse", left: 690, top: 90, width: 100, tooltip: "Browse directory") { dir_out.text = fix_string(ask_open_folder) }
		## Files filter
		para "Filter files by XML tree", left: 30, top: 130
		dir_filter = edit_line("#{@AdvMapShared}", left: 115, top: 160, height: 30, width: 676, tooltip: "Directory to to write in") { |t| @@AdvMapShared = t.text }
		
		button("Extract", left: 430, top: 250, width: 140, tooltip: "Copy all files and changes razed object") { get_tree(source, &method(:update_objectData_to_xml)) }
	end
end

def analyze_AdvMapShared 
	source = Dir.pwd + '/output/MapObjects'
	median, medianX, medianY = 10, 0, 0
	
	@canvas.clear do
		button("Main Menu", left: 430, top: 0, width: 140, tooltip: "Go to main menu") { mainmenu }
		@matrixGrid = stack(left: 65, top: 122, width: 463, height: 463)
		@legend = stack(left: 600, top: 110, width: 350, height: 480)
		flow left: 30, top: 35, height: 50, width:920 do
			background bisque
			para "Input dir", left: 20, top: 10
			dir_in = edit_line("#{source}", left: 105, top: 10, height: 30, width: 550, tooltip: "Directory to inspect files from", state: 'disabled') { |t| source = t.text }
			button("Browse", left: 670, top: 10, width: 100, tooltip: "Browse directory") { dir_in.text = fix_string(ask_open_folder) }
			button("Build", left: 790, top: 10, width: 100, tooltip: "Analyze data and build indexes") do
				@H5MapObjects = {}
				get_tree(source, &method(:get_ObjectData_to_lua))
				@f_wr1 = File.open(Dir.pwd + '/code.lua', "w")
				@f_wr1.write("MapObject = {}\n")	
				@f_wr1.write("print(\"Initializing Adventure Map objects...\")\n\n")	
				printXML("MapObjects", @H5MapObjects, @f_wr1, 0, 1)
				@f_wr1.write("print(\"Objects initialized!\");")
				@f_wr1.close
				@legend.clear do
					background bisque
					para "Choose Adventure map object type:", left: 0, top: 10
					@legend1 = stack(left: 0, top: 90, width: 350, height: 180)
					list_box left: 40, top: 35, width: 300, :items => @AdvMapShared do |o|
						selection = []
						@H5MapObjects.keys.each_with_index do |k, i| 
							selection << k if @H5MapObjects[:"#{k}"][:"sharedType"] == o.text
						end
						@legend1.clear do
							para "Object list:", left: 0, top: 0
							@legend2 = stack(left: 0, top: 75, width: 350, height: 60)
							list_box left: 40, top: 30, width: 300, items: selection do |m|
								entries = Array( 0..@H5MapObjects[:"#{m.text}"][:"entries"]) ## AdvMap object variations
								@legend2.clear do
									para "Variants", left: 220, top: 0
									list_box left: 250, top: 30, width: 50, height: 15, items: entries, choose: entries[0] do |e|
										debug("ID: #{m.text}, variation is #{e.text}")
										@arrayMap = Array.new(21) { Array.new(21, 1) }
										fill_matrix(@arrayMap, @H5MapObjects[:"#{m.text}"][:"blockedTiles"][:"#{e.text}"], median, 0 )
										fill_matrix(@arrayMap, @H5MapObjects[:"#{m.text}"][:"activeTiles"][:"#{e.text}"] , median, 2 )
										@arrayMap = @arrayMap.reverse   ## make array vectors aligned with Heroes 5 map array
										@matrixGrid.clear { border green }
										draw_matrix(@arrayMap, @matrixGrid, median)
									end
									
									button "Rotate 90º", left: 40, top: 30, height: 34 do
										@arrayMap = @arrayMap.transpose.reverse
										@matrixGrid.clear { border green }
										draw_matrix(@arrayMap, @matrixGrid, median)
									end
								end
							end	
						end
					end

					flow left: 50, top: 245, width: 250, height: 250 do
						tagline "Legend", align: "center"
						strokewidth = 4
						line(20,40,230,40)
						left, top = 70, 20
						stroke gray
						fill white
						rect(10, top + 40, 24, 24)
						para "Empty square", left: left, top: top + 40
						fill red
						rect(10, top + 80, 24, 24)
						para "Blocked square", left: left, top: top + 80
						fill orange
						rect(10, top + 120, 24, 24)
						para "Active square", left: left, top: top + 120
						strokewidth 2
						stroke black
						nofill
						rect(10, top + 160, 24, 24)
						#para "Possession square", left: left, top: top + 160
						para "Central square (0:0)", left: left, top: top + 160
					end
				end
			end
		end
	end
end


Shoes.app(width: 1000, height: 700, resizable: false) do
	
	@var_debug = 0;
	## define statics
	@AdvMapShared = [ "AdvMapBuildingShared", "AdvMapDwellingShared", "AdvMapTownShared", "AdvMapMineShared", "AdvMapGarrisonShared", "AdvMapTentShared", "AdvMapCartographerShared" ]
	## AdvMapSeerHutShared, AdvMapSignShared, AdvMapShipyardShared, AdvMapPrisonShared, AdvMapShrineShared, AdvMapDwarvenWarrenShared
	@MapObjects = {}
	@hp_gain = 0.25
	
	title "M&M5 editor framework", align: "center"
	@canvas = flow left: 20, top: 60, width: 960, height: 600 do
		border red
	end	
	mainmenu	
end	