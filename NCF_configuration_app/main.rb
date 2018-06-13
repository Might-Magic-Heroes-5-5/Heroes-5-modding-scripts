require 'fileutils'
require 'net/https'
require 'uri'
require 'zip'

Shoes.app(title: " New Creature Framework: Configuration utility", width: 500, height: 600, resizable: false ) do

	style Shoes::Para, font: "Bell MT", size: 10, align: "center"	

	####################### Defining menu colouring ###############################
	colour_app = forestgreen..yellowgreen	## this is the frame colour
	@colour_menu_default = white 			## Default colour for all subwindows
	@colour_menu_applied = yellow  			## Alternative colour for all subwindows when a package is applied.
	@colour_menu1 = silver					## submenu1 colour
	@colour_menu2 = rgb(160,160,160) 		## submenu2 colour
	@colour_menu3 = rgb(180,180,180) 		## submenu3 colour
	
	####################### Defining global variables ###########################
	@server_url = "https://raw.githubusercontent.com/dredknight/NCF_Utility__production/master/package_list.txt" ###Packages store server
	@package_list = "NCF_repository/package_list.txt"
	@core_deployed = 0						## 0 - core is not deployed; 1 core is deployed
	File.file?("NCF_repository/packs")? nil : ( mkdir_p 'NCF_repository/packs' )
	
	
	def messages m, text=nil		        ####All alerts that pop in the application
		alert(case m
				when 0 then "Wait until download completes"
				when 1 then "Installation complete"
				when 2 then "Core modules and creature packs removed successfully!"
				when 3 then "No connection to server"
				when 99 then text 
			  end, title: nil)
	end

	def filter_files path				## returns all files found in a specific path
		return Dir.entries(path).reject { |rj| ['.','..'].include?(rj) }
	end

	def letters?(string)				## makes all chars downcase
		string.chars.any? { |char| ('a'..'z').include? char.downcase }
	end

	def check_dl flag = 0				## Checks if any download is currently in progress
		@pack_contain.nil? ? nil : ( @pack_contain.contents.each { |n| n.contents.count > 3 ? (flag = 1; break): nil } )
		return flag
	end

	def dl_button slot, text, url, name, ver, state = nil
		q = button(text, left: 310, top: 0, width: 100, state: state) do
			real_url = get_url url
			if real_url.nil? then
				messages 3
			else
				q.state = "disabled"
				File.file?("NCF_repository/downloads/#{name}_#{ver}.zip")? ( FileUtils.rm "NCF_repository/downloads/#{name}_#{ver}.zip") : nil
				File.file?("NCF_repository/downloads")? nil : ( mkdir_p 'NCF_repository/downloads' )
				slot.append { progress left: 313, top: 33, width: 92, height: 3 }
				download real_url, save: "NCF_repository/downloads/#{name}_#{ver}.zip", progress: proc { |dl| slot.contents[3].fraction = dl.percent*0.9 } do
					File.directory?("NCF_repository/packs/#{name}")? ( FileUtils.rm_r "NCF_repository/packs/#{name}" ) : nil
					extract_zip( "NCF_repository/downloads/#{name}_#{ver}.zip","NCF_repository/packs/#{name}")
					slot.contents[3].fraction = 1.0
					slot.contents[3].remove
					slot.contents[2].remove
					slot.append { dl_button slot, "Done!", nil, nil, nil, "disabled" }
				end
			end
		end
	end

	def get_url url
		uri = URI(url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		req = Net::HTTP::Get.new(uri.request_uri)
		begin
			case uri.host
				when /.moddb./ then
					res = http.request(req)
					loc = res.body[/a href="(.*?)">/, 1]
					real_url="https://"+"#{uri.host}#{loc}"
				when /.dropbox./ then real_url = http.request(req)['location']
				when /.github./ then real_url = http.request(req).body
				else real_url = http.request(req).body
			end
		rescue
			return nil
		end
		return real_url
	end

	def extract_zip(file, destination)
	  FileUtils.mkdir_p(destination)
	  Zip::File.open(file) do |zip_file|
		zip_file.each do |f|
		  fpath = File.join(destination, f.name)
		  zip_file.extract(f, fpath) unless File.exist?(fpath)
		end
	  end
	end

	def deploy_core folder
		if [ "yes", "y", "Y", "YES" ].include?(ask("Are you sure you want to deploy NCF core for #{folder}(Y/N)?\n")) then
			FileUtils.copy_entry "NCF_repository/core/#{folder}/", ".."
			FileUtils.mkdir_p '../Complete/Icons'
			show_core
		end
	end
	
	def show_core
		@core.clear do
			(filter_files "NCF_repository/core").each_with_index do | f, i |
				if ((filter_files "NCF_repository/core/#{f}/data") & (File.directory?("../data") ? (filter_files "../data") : [] )).empty? then
					rect(left: 0, top: 0, curve: 10,  width: 435, height: 85, fill: @colour_menu_default)
					caption "Install a core package", align: "center", top: 4
					line 30,35,400,35
					button("#{f}", left: 35 + 120*i, top: 46, width: 100) { deploy_core f; }
					@core_deployed = 0
				else
					@core.clear;
					rect(left: 0, top: 0, curve: 10,  width: 435, height: 85, fill: @colour_menu_applied)
					caption "#{f} core installed", align: "center", top: 4
					line 30,35,400,35
					button("Uninstall", left: 170, top: 46, width: 100 ) { [ "yes", "y", "Y", "YES" ].include?(ask("This will purge previous NCF installations. Are you sure(Y/N)?")) ? purge_core : nil }
					@core_deployed = 1
					break
				end
			end
			show_pack
		end
	end

	def purge_core
		Dir.glob("NCF_repository/core/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
			file_name = fn.split("/")[3..-1].join("/")
			File.delete("../#{file_name}") if File.exist?("../#{file_name}")
		end
		@core_deployed = 0
		show_core
	end

	def list_all_creatures list
		list.each_with_index do |line, i|
			p = line.split(" ")
			@creature_table.append do
				flow left: 0, top: 5 + 30*i, width: 0.8 do
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push(p[0]) : @custom_ncf_package.delete(p[0]) }			
					para "#{p[0]}. #{p[1]}", align: "left", size: 13
				end
			end
		end
	end

	def list_filtered_creatures list, state
		base_arr, upg_arr, old_upgr, new_upgr = [], [], [], []
		list.each do |line|
			p = line.split(",")
			p[2] == "none" ? base_arr << p : upg_arr << p
		end
		upg_arr.each { |ncf| letters?(ncf[2]) ? old_upgr << ncf : new_upgr << ncf }
		state == "new" ? new_upgr.each { |n| base_arr.insert((base_arr.flatten.index(n[2])/4)+1,n) } : base_arr = old_upgr
		base_arr.each do |ncf|
			@creature_table.append do
				flow displace_left: (ncf[2] == "none" or letters?(ncf[2])) ? 60 : 90, width: 0.8 do
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push("NCF_#{ncf[0]}.pak") : @custom_ncf_package.delete("NCF_#{ncf[0]}.pak") }
					para "#{ncf[0]}. #{ncf[1]}", align: "left", size: 13
				end
			end
		end
	end

	def deploy_pack folder
		@custom_ncf_package = []
		@main.hide;
		@main2.clear fill: rgb(100,244,40) do
			rect(left: 5, top: 15, curve: 10,  width: 435, height: 470, fill: @colour_menu_default)
			name_file = File.readlines("NCF_repository/packs/#{folder}/list/creature_list.txt")
			caption "#{folder} creatures", align: "center", top: 20
			line 20, 55, 420, 55, strokewidth: 2
			line 150, 75, 150, 465, strokewidth: 1
			check_global = check(left: 25, top: 74, checked: false) { |c| @creature_table.contents.each { |f| f.contents[0].checked = c.checked? ? true : false}; }
			para "Select All", left: -90, top: 74, size: 14
			@bar = progress left: 20, top: 60, width: 400, height: 2
			@creature_table = stack left: 158, top: 75, width: 280, height: 390, scroll: true;
			#help = "'All creatures' - list all creatures from the pack \n 'New creatures...' - list only new cratures with their upgrades (bottom right) \n 'Alternative upgrades...' - Only new upgrades of faction creatures, not available for purchase"
			list_all_creatures name_file[2..-1]		
			#list_box :items => ["All creatures", "New creatures and their upgrades", "Alternative upgrades of vanilla creatures" ], left: 150,  top: 38, width: 270, choose: "All creatures", tooltip: help do |n|
			#	@creature_table.clear
			#	case n.text
			#	when n.items[0] then list_all_creatures name_file[2..-1]
			#	when n.items[1] then list_filtered_creatures name_file[2..-1], "new"
			#	when n.items[2] then list_filtered_creatures name_file[2..-1], "old"
			#	end
			#end
			back = button( "Back", left: 8, top: 490, width: 100 ) { @main.show; @main2.hide }
			deploy = button( "Deploy", left: 340, top: 490, width: 100 ) do                                											####### pressing the button installs checked creatures
				if [ "yes", "y", "Y", "YES" ].include?( ask("Any previously installed NCF creatures will be removed. Are you sure(Y/N)?")) then
					purge_pack																														####### clean currently installed creatures
					back.state = "disabled"
					deploy.state = "disabled"
					check_global.state = "disabled"																									####### Disable "Select all" check box during installation
					@creature_table.contents.each { |f| f.contents[0].state = "disabled" }															####### Disable Creatures check boxes during installation
					Thread.new do
						@custom_ncf_package.each_with_index do |ncf, i|																				####### Iterate over all currentely chosen creatures and install them
							FileUtils.copy_file "NCF_repository/packs/#{folder}/NCF_#{ncf}.pak", "../data/NCF_#{ncf}.pak"
							FileUtils.copy_file "NCF_repository/packs/#{folder}/Icons/Creature_#{ncf}.dds", "../Complete/icons/Creature_#{ncf}.dds"
							@bar.fraction = ((i+1).to_f/@custom_ncf_package.count).round(2)
						end
						start { messages 1 }
					end
				end
			end
		end
		@main2.show
		start { @creature_table.scroll_top = 1 } ### this is a workaround for a scroll bug that comes with shoes
	end

	def check_packs
		@existing_packs = Array.new(0) { Array.new(2) }
		installed_packs = (filter_files "NCF_repository/packs")
		installed_packs.each_with_index do | f, i |
			if File.file?("NCF_repository/packs/#{f}/list/creature_list.txt") then
				@existing_packs.push( [ f, File.open("NCF_repository/packs/#{f}/list/creature_list.txt", &:readline).split(',')[1] ] )
			else
				@existing_packs.push( [ f, "is broken" ] )
			end
		end
	end

	def show_pack
		@packs.clear do
			stat = @core_deployed == 1 ? nil : "disabled"
			if @existing_packs.empty? then 
				para "No creature packs available. Download one from the \"Online Store\" tab", size: 15, align: "center"
			else
				@existing_packs.each_with_index do | f, i |
					flow left: 15, top: 10 + i*40, width: 430, height: 40 do
						para "#{i+1}. #{f[0]} #{f[1]}", size: 15, align: "left" 
						button("Install",tooltip: "If this is greyed out deploy core first, if broken deploy package again", left: 300, top: 0, state: stat) { deploy_pack f[0] }
					end
				end
			end
		end
	end

	def purge_pack   															### cleans currently installed NCF creatures, editor icons, and editor icon cache.
		Dir.glob('../data/NCF_*.pak').each { |file| File.delete(file)} 			###  NCF creatures
		Dir.glob('../Editor/IconCache/AdvMapObjectLink/MapObjects/_(AdvMapObjectLink)/Monsters/NCF/Creature*').each { |file| File.delete(file)} ###  Cleaning editor Icon cache
		Dir.glob('../Complete/Icons/*.dds').each { |file| File.delete(file)}	###  Editor Icons
	end
	
	def show_store
		store_packs = []
		@pack_contain.clear do
			if File.file?(@package_list) then
				File.readlines(@package_list).each_with_index do |pack, i |
					store_packs[i] = flow left: 15, top: i*40, width: 430, height: 40 do
						package = pack.split(',')
						para "#{i+1}. #{package[0]} #{package[2]}", size: 15, align: "left" 
						button("info", left: 240, top: 0) { messages 99, package[3] }
						if @existing_packs.collect {|name| name[0]}.include?(package[0]) then 
							@existing_packs.each_with_index do |p, i|
								if p[0] == package[0] then
									package[2] <= p[1] ? ( dl_button contents[0].parent, "Up to date", package[1], "#{package[0]}", "#{package[2]}", "disabled" ) : (  dl_button contents[0].parent, "Update", package[1], "#{package[0]}", "#{package[2]}" ); 
									break;
								end
							end
						else
							dl_button contents[0].parent, "Download", package[1], "#{package[0]}", "#{package[2]}"
						end
					end
				end
			end
		end
	end
	
	background colour_app
	subtitle "NCF Configuration Utility", stroke: white, align: "center"
	check_packs
	
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.85 do
		@core = stack left: 5, top: 15, width: 440, height: 100;
		stack left: 5, top: 130, width: 440, height: 355 do
			rect(left: 0, top: 0, curve: 10,  width: 435, height: 355, fill: @colour_menu_default)
			caption "NCF packages", align: "center"
			ofline = flow left: 0, top: 30, width: 144, height: 30 do
				rect(left: 0, top: 0, curve: 10, width: 143, height: 320, fill: @colour_menu1)
				@off_text = para "Local Repository", align: "center"
				click { @menu_offline.show; @menu_online.hide; @menu_about.hide; check_packs; show_pack }
			end
			online = flow left: 145, top: 30, width: 144, height: 30 do
				rect(left: 0, top: 0, curve: 10, width: 143, height: 320, fill: @colour_menu2)
				para "Online store", align: "center"
				click { @menu_offline.hide; @menu_online.show; @menu_about.hide; check_packs }
			end
			about = flow left: 290, top: 30, width: 146, height: 30 do
				rect(left: 0, top: 0, curve: 10, width: 145, height: 320, fill: @colour_menu3)
				para "About", align: "center"
				click { @menu_offline.hide; @menu_online.hide; @menu_about.show }
			end
			
			@menu_offline = flow left: 0, top: 60, width: 435, height: 300 do
				rect(left: 0, top: -10, curve: 10, width: 435, height: 305, fill: @colour_menu1)
				@packs = flow;
				button "Purify", left: 175, top: 260, tooltip: "Removes any NCF installations", width: 100, height: 25 do
					if [ "yes", "y", "Y", "YES" ].include?(ask("WARNING! This will remove any installed NCF creature packs along with installed NCF cores. Are you sure(Y/N)?")) then
						purge_core; purge_pack;
						messages 2
					end
				end
			end

			@menu_online = flow left: 0, top: 60, width: 435, height: 300, hidden: true do 
				rect(left: 0, top: -10, curve: 10, width: 435, height: 305, fill: @colour_menu2)
				button("Update package list", left: 30, top: 10, width: 360, height: 20) do
					check_dl == 0? nil : (messages 0; next)
					@pack_contain.clear { spinner left: 113, top: 90, start: true, tooltip: "Waiting for something?" }
					Thread.new do
						repo_data = get_url @server_url
						start do
							repo_data.nil? ? ( messages 3 ) : ( File.open(@package_list, "w") { |f| f.write repo_data } )
							show_store
						end
					end
				end
				@pack_contain = flow left: 0, top: 35, width: 431, height: 220;
				show_store
			end
			
			@menu_about = flow left: 0, top: 60, width: 435, height: 300, hidden: true do
				rect(left: 0, top: -10, curve: 10, width: 435, height: 305, fill: @colour_menu3)
				caption "Useful links", align: "center", top: 10
				button("The NCF project on GitHub.", left: 30, top: 50, width: 360, height: 25) { system("start https://github.com/dredknight/Heroes-5-modding-scripts/tree/master/NCF_configuration_app") } 
				button("Ask for help or provide feedback.", left: 30, top: 80, width: 360, height: 25) { system("start http://heroescommunity.com/viewthread.php3?TID=44287") } 
				button("Might and Magic 5.5 official page", left: 30, top: 110, width: 360, height: 25) { system("start https://www.moddb.com/mods/might-magic-heroes-55") } 
				button("Subscribe and rate us on Moddb!", left: 30, top: 140, width: 360, height: 25) { system("start https://www.moddb.com/mods/heroes-v-new-creature-framework/reviews") }
				para "Created by Dredknight", allign: "right", top: 260
			end
		end
	end
	
	show_core
	@main2 = stack left: 0.05, top: 0.1, width: 0.9, height: 0.9
end