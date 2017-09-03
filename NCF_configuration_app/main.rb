require 'fileutils'
require 'net/https'
require 'uri'
require 'zip'

Shoes.app(title: " New Creature Framework: Configuration utility", width: 500, height: 600, resizable: false ) do

	style Shoes::Para, font: "Bell MT", size: 10, align: "center"
	@server_url = "https://raw.githubusercontent.com/dredknight/NCF_Utility__production/master/package_list.txt"
	#colour_app = tan..green 				## this is the frame colour
	#@colour_menu_default = rgb(245,245,220) ## Default colour for all subwindows
	#@colour_menu_applied = yellow..orange   ## Alnternative colour for all subwindows when a package is applied.
	#@colour_menu_local = rgb(225,225,220)
	#@colour_menu_online = chocolate
	
	colour_app = forestgreen..yellowgreen	## this is the frame colour
	@colour_menu_default = white ## Default colour for all subwindows
	@colour_menu_applied = yellow  ## Alnternative colour for all subwindows when a package is applied.
	@colour_menu_local = silver
	@colour_menu_online = gray

	def filter_files path
		return Dir.entries(path).reject { |rj| ['.','..'].include?(rj) }
	end
	
	def letters?(string)
		string.chars.any? { |char| ('a'..'z').include? char.downcase }
	end
	
    def main_page
		@main.clear do
			@core = stack left: 5, top: 15, width: 440, height: 100
			@pack = stack left: 5, top: 130, width: 440, height: 350
			main_core_block
			button "Purify", left: 175, top: 500, tooltip: "Removes any NCF installations", width: 100 do
				if [ "yes", "y", "Y", "YES" ].include?(ask("WARNING! This will remove any installed NCF creature packs along with installed NCF cores. Are you sure(Y/N)?")) then
					purge_core; purge_pack;
					alert "Core modules and creature packs removed successfully!", title: nil
				end
			end
		end
	end
	
	def main_core_block
		@core.clear do
			rect(left: 0, top: 0, curve: 10,  width: 435, height: 85, fill: @colour_menu_default)
			caption "Install a core package", align: "center", top: 4
			line 30,35,400,35
			main_pack_block "disabled"
			(filter_files "NCF_repository/core").each_with_index do | f, i |
				if ((filter_files "NCF_repository/core/#{f}/data") & (File.directory?("../data") ? (filter_files "../data") : [] )).empty? then
					button("#{f}", left: 35 + 120*i, top: 46, width: 100) { deploy_core f; }
				else
					@core.clear do
						rect(left: 0, top: 0, curve: 10,  width: 435, height: 85, fill: @colour_menu_applied)
						caption "#{f} core installed", align: "center", top: 4
						line 30,35,400,35
						button("Uninstall", left: 170, top: 46, width: 100 ) { [ "yes", "y", "Y", "YES" ].include?(ask("This will purge previous NCF installations. Are you sure(Y/N)?")) ? purge_core : nil }
					end;
					main_pack_block
					break;
				end
			end
		end
	end

	def main_pack_block stat=nil
		@pack.clear do
			rect(left: 0, top: 0, curve: 10,  width: 435, height: 345, fill: @colour_menu_default)
			caption "NCF packages", align: "center"
			ofline = flow left: 0, top: 30, width: 217, height: 30 do
				rect(left: 0, top: 0, curve: 10,  width: 215, height: 320, fill: @colour_menu_local)
				@off_text = para "Local Repository", align: "center"
			end
			online = flow left: 218, top: 30, width: 217, height: 30 do
				rect(left: 0, top: 0, curve: 10,  width: 217, height: 320, fill: @colour_menu_online)
				para "Online store", align: "center"
			end
			ofline.click { main_pack_block_offline stat }
			online.click { main_pack_block_online }
			@show_packs = flow left: 0, top: 60, width: 435, height: 300;
			main_pack_block_offline stat
		end
	end
	
	def main_pack_block_offline stat
		@existing_packs = Array.new(10) { Array.new(2) }
		@show_packs.clear do
			rect(left: 0, top: -10, curve: 10, width: 435, height: 305, fill: @colour_menu_local)
			(filter_files "NCF_repository/packs").each_with_index do | f, i |
				@existing_packs[i][0] = f
				@existing_packs[i][1] = File.open("NCF_repository/packs/#{f}/list/creature_list.txt", &:readline).split(',')[1]
				flow left: 15, top: 10 + i*40, width: 430, height: 40 do
					para "#{i+1}. #{f} #{@existing_packs[i][1]}", size: 15, align: "left" 
					button("Install",tooltip: "If this is greyed out deploy core first", left: 300, top: 0, state: stat) { deploy_pack f }
				end
			end
		end
	end

	def main_pack_block_online
		packs = []
		@show_packs.clear do
			rect(left: 0, top: -10, curve: 10, width: 435, height: 305, fill: @colour_menu_online)
			button("Update package list", left: 30, top: 10, width: 360, height: 20) do
				@pack_contain.clear { spinner left: 113, top: 90, start: true, tooltip: "waiting for something?" }
				Thread.new do
					repo_data = get_url @server_url
					File.open('NCF_repository/package_list.txt', "w") { |f| f.write repo_data }
					main_pack_block_online
				end
			end
			@pack_contain = flow left: 0, top: 35, width: 431, height: 220 do
				File.readlines("NCF_repository/package_list.txt").each_with_index do |pack, i |
					packs[i] = flow left: 15, top: i*40, width: 430, height: 40 do
						package = pack.split(',')
						para "#{i+1}. #{package[0]} #{package[2]}", size: 15, align: "left" 
						button("info", left: 240, top: 0) { alert("#{package[3]}") }
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
	
	def dl_button slot, text, url, name, ver, state = nil
		q = button(text, left: 310, top: 0, width: 100, state: state) do
			slot.append { progress left: 313, top: 33, width: 92, height: 3 }
			real_url = get_url url
			File.file?("NCF_repository/downloads/#{name}_#{ver}.zip")? ( FileUtils.rm "NCF_repository/downloads/#{name}_#{ver}.zip") : nil
			download real_url, save: "NCF_repository/downloads/#{name}_#{ver}.zip", progress: proc { |dl| slot.contents[3].fraction = dl.percent*0.9 } do
				File.directory?("NCF_repository/packs/#{name}")? ( FileUtils.rm_r "NCF_repository/packs/#{name}" ) : nil
				extract_zip( "NCF_repository/downloads/#{name}_#{ver}.zip","NCF_repository/packs/#{name}")
				slot.contents[3].fraction = 1.0
				q.remove
				slot.append { dl_button slot, "Done!", nil, nil, nil, "disabled" }
			end
		end
	end
	
	def get_url url
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		case uri.host
			when /.moddb./ then
				request = Net::HTTP.get(uri.host,uri.request_uri)
				url_redirect = request[/a href="(.*?)">/, 1]
				real_url = "#{uri.scheme}://#{uri.host}#{url_redirect}"
			when /.dropbox./ then
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE	
				request = Net::HTTP::Get.new(uri.request_uri)	
				real_url = http.request(request)['location']
			when /.github./
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				request = Net::HTTP::Get.new(uri.request_uri)
				real_url = http.request(request).body
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
			main_core_block
		end
	end
	
	def purge_core
		Dir.glob("NCF_repository/core/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
			file_name = fn.split("/")[3..-1].join("/")
			File.delete("../#{file_name}") if File.exist?("../#{file_name}")
		end
		main_core_block
	end
	
	def list_all_creatures list
		list.each_with_index do |line, i|
			p = line.split(" ")
			@creature_table.append do
				flow left: 0, top: 5 + 30*i, width: 0.8 do
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push("NCF_#{p[0]}.pak") : @custom_ncf_package.delete("NCF_#{p[0]}.pak") }			
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
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push("NCF_#{ncf[0]}.pak") : @custom_ncf_package.delete("NCF_#{ncf[0]}.pak"); debug("#{p[0]}, #{@custom_ncf_package.count}") }
					para "#{ncf[0]}. #{ncf[1]}", align: "left", size: 13
				end
			end
		end
	end
	
	def deploy_pack folder
		@custom_ncf_package = []
		@main.clear fill: rgb(100,244,40) do
			rect(left: 5, top: 15, curve: 10,  width: 435, height: 470, fill: @colour_menu_default)
			name_file = File.readlines("NCF_repository/packs/#{folder}/list/creature_list.txt")
			caption "Legacy pack creatures", align: "center", top: 20
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
			button( "Back", left: 5, top: 490, width: 100 ) { main_page }
			button( "Deploy", left: 340, top: 490, width: 100 ) do                                													####### pressing the button installs checked creatures
				if [ "yes", "y", "Y", "YES" ].include?( ask("Any previously installed NCF creatures will be removed. Are you sure(Y/N)?")) then
					purge_pack																														####### clean currently installed creatures
					check_global.state = "disabled"																									####### Disable "Select all" check box during installation
					@creature_table.contents.each { |f| f.contents[0].state = "disabled" }															####### Disable Creatures check boxes during installation
					@read = 0
					Thread.new do
						@custom_ncf_package.each_with_index do |ncf, i|																				####### Iterate over all currentely chosen creatures and install them
							FileUtils.copy_file "NCF_repository/packs/#{folder}/#{ncf}", "../data/#{ncf}"
							FileUtils.copy_file "NCF_repository/packs/#{folder}/Icons/#{ncf.split(".")[0]}.dds", "../Complete/icons/#{ncf.split(".")[0]}.dds"
							@bar.fraction = ((i+1).to_f/@custom_ncf_package.count).round(2)
						end
					@read = 1
					end	
					#Thread.new do
						sleep(0.1) until @read==1
							debug("shit #{@read}")
							alert "#{folder} installed!", title: nil 
					#end
					
				end
			end
		end
		start { @creature_table.scroll_top = 1 } ### this is a workaround for a scroll bug that comes with shoes
	end
	
	def purge_pack
		Dir.glob('../data/NCF_*.pak').each { |file| File.delete(file)} ###  NCF creatures
		Dir.glob('../Editor/IconCache/AdvMapObjectLink/MapObjects/_(AdvMapObjectLink)/Monsters/NCF/Creature*').each { |file| File.delete(file)} ###  Cleaning editor Icon cache
		Dir.glob('../Complete/Icons/*.dds').each { |file| File.delete(file)} ###  Editor Icons
	end
	
	background colour_app
	subtitle "NCF Configuration Utility", stroke: white, align: "center"
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.9
	main_page		
end