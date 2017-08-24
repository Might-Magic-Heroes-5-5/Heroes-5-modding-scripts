require 'fileutils'
require 'net/https'
require 'uri'
require 'zip'

Shoes.app(title: " New Creature Framework: Configuration utility", width: 500, height: 600, resizable: false ) do

	style Shoes::Para, font: "Bell MT", size: 10, align: "center"
	
	def filter_files path
		return Dir.entries(path).reject { |rj| ['.','..'].include?(rj) }
	end
	
	def letters?(string)
		string.chars.any? { |char| ('a'..'z').include? char.downcase }
	end
	
    def main_page
		@main.clear do
			@core = stack left: 5, top: 15, width: 440, height: 100
			@pack = stack left: 5, top: 130, width: 440, height: 330
			main_core_block
			button "Purify", left: 175, top: 460, tooltip: "Removes any NCF installations", width: 100 do
				if [ "yes", "y", "Y", "YES" ].include?(ask("WARNING! This will remove any installed NCF creature packs along with installed NCF cores. Are you sure(Y/N)?")) then
					purge_core; purge_pack;
					alert "Core modules and creature packs removed successfully!", title: nil
				end
			end
		end
	end
	
	def main_core_block
		@core.clear do
			rect(left: 0, top: 0, curve: 10,  width: 435, height: 98, fill: rgb(245,245,220))
			caption "Core", align: "center"
			main_pack_block "disabled"
			(filter_files "NCF_repository/core").each_with_index do | f, i |
				if ((filter_files "NCF_repository/core/#{f}/data") & (File.directory?("../data") ? (filter_files "../data") : [] )).empty? then
					button("#{f}", left: 20 + 120*i, top: 50, width: 100) { deploy_core f; }
				else
					@core.clear do
						rect(left: 0, top: 0, curve: 10,  width: 435, height: 98, fill: yellow..orange)
						caption "Core", align: "center" 
						caption "#{f} is deployed", align: "center"
						button("Uninstall", left: 170, top: 65, width: 100 ) { [ "yes", "y", "Y", "YES" ].include?(ask("This will purge previous NCF installations. Are you sure(Y/N)?")) ? purge_core : nil }
					end;
					main_pack_block
					break;
				end
			end
		end
	end

	def main_pack_block stat=nil
		@pack.clear do
			rect(left: 0, top: 0, curve: 10,  width: 435, height: 320, fill: rgb(245,245,220))
			caption "NCF packages", align: "center"
			ofline = flow left: 0, top: 30, width: 217, height: 30 do
				rect(left: 0, top: 0, curve: 10,  width: 215, height: 320, fill: rgb(225,225,220))
				@off_text = para "Local Repository", align: "center"
			end
			online = flow left: 218, top: 30, width: 217, height: 30 do
				rect(left: 0, top: 0, curve: 10,  width: 217, height: 320, fill: chocolate)
				para "Online store", align: "center"
			end
			ofline.click { main_pack_block_offline stat }
			online.click { main_pack_block_online }
			@show_packs = flow left: 0, top: 60, width: 435, height: 260;
			main_pack_block_offline stat
		end
	end
	
	def main_pack_block_offline stat
		@existing_packs = Array.new(10) { Array.new(2) }
		@show_packs.clear do
			rect(left: 0, top: -10, curve: 10, width: 435, height: 270, fill: rgb(225,225,220))
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
			rect(left: 0, top: -10, curve: 10, width: 435, height: 270, fill: chocolate)
			button("Refresh list", left: 30, top: 10, width: 360, height: 20) do
				@pack_contain.clear do 
					spinner left: 113, top: 90, start: true, tooltip: "waiting for something?"
				end
			end
			@pack_contain = flow left: 0, top: 35, width: 431, height: 220 do
				border yellow
				File.readlines("NCF_repository/package_list.txt").each_with_index do |pack, i |
					packs[i] = flow left: 15, top: i*40, width: 430, height: 40 do
						package = pack.split(',')
						@wqe = para "#{i+1}. #{package[0]} #{package[2]}", size: 15, align: "left" 
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
			uri = URI.parse(url)
			http = Net::HTTP.new(uri.host, uri.port)
			case uri.scheme
				when 'http' then
					request = Net::HTTP.get(uri.host,uri.request_uri)
					url_redirect = request[/a href="(.*?)">/, 1]
					real_url = "#{uri.scheme}://#{uri.host}#{url_redirect}"
				when 'https' then
					http.use_ssl = true
					http.verify_mode = OpenSSL::SSL::VERIFY_NONE
					request = Net::HTTP::Get.new(uri.request_uri)
					real_url = http.request(request)['location']
			end
			debug("real_url is #{real_url}, #{name}_#{ver}.zip")
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
	
	def show_all list
		list.each do |line|
			p = line.split(",")
			@q.append do
				flow displace_left: 60, width: 0.8 do
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push("NCF_#{p[0]}.pak") : @custom_ncf_package.delete("NCF_#{p[0]}.pak") }
					para "#{p[0]}. #{p[1]}", align: "left", size: 13
				end
			end
		end
	end
	
	def new_creatures list, state
		base_arr, upg_arr, old_upgr, new_upgr = [], [], [], []
		list.each do |line|
			p = line.split(",")
			p[2] == "none" ? base_arr << p : upg_arr << p
		end
		upg_arr.each { |ncf| letters?(ncf[2]) ? old_upgr << ncf : new_upgr << ncf }
		state == "new" ? new_upgr.each { |n| base_arr.insert((base_arr.flatten.index(n[2])/4)+1,n) } : base_arr = old_upgr
		base_arr.each do |ncf|
			@q.append do
				flow displace_left: (ncf[2] == "none" or letters?(ncf[2])) ? 60 : 90, width: 0.8 do
					check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push("NCF_#{ncf[0]}.pak") : @custom_ncf_package.delete("NCF_#{ncf[0]}.pak") }
					para "#{ncf[0]}. #{ncf[1]}", align: "left", size: 13
				end
			end
		end
	end
	
	def deploy_pack folder
		@custom_ncf_package = []
		@main.clear fill: rgb(100,244,40) do
			rect(left: 0, top: 0, curve: 10,  width: @main.width-3, height: @main.scroll_height-60, fill: rgb(245,245,220))
			name_file = File.readlines("NCF_repository/packs/#{folder}/list/creature_list.txt")
			tagline "Legacy pack list", align: "center"
			line 20, 35, 420, 35
			check(left: 30, top: 40, checked: false) { |c| @q.contents.each { |f| f.contents[0].checked = c.checked? ? true : false} }
			caption "Select All", left: 50, top: 39
			#@bar = progress left: 155, top: 39, width: 250
			line 20, 70, 420, 70
			@q = stack left: 20, top: 75, width: 420, height: 400, scroll: true;
			help = "'All creatures' - list all creatures from the pack \n 'New creatures...' - list only new cratures with their upgrades (bottom right) \n 'Alternative upgrades...' - Only new upgrades of faction creatures, not available for purchase"
			list_box :items => ["All creatures", "New creatures and their upgrades", "Alternative upgrades of vanilla creatures" ], left: 150,  top: 38, width: 270, choose: "All creatures", tooltip: help do |n|
				@q.clear
				case n.text
				when n.items[0] then show_all name_file[2..-1]
				when n.items[1] then new_creatures name_file[2..-1], "new"
				when n.items[2] then new_creatures name_file[2..-1], "old"
				end
			end
			button( "Back", left: 5, top: 490, width: 100 ) { main_page }
			button( "Deploy", left: 340, top: 490, width: 100 ) do
				if [ "yes", "y", "Y", "YES" ].include?( ask("Any previously installed NCF creatures will be removed. Are you sure(Y/N)?")) then
					purge_pack
					@custom_ncf_package.each_with_index do |ncf, i|	
						FileUtils.copy_file "NCF_repository/packs/#{folder}/#{ncf}", "../data/#{ncf}"
						FileUtils.copy_file "NCF_repository/packs/#{folder}/Icons/#{ncf.split(".")[0]}.dds", "../Complete/icons/#{ncf.split(".")[0]}.dds"
						#@bar.fraction = (i*100)/@custom_ncf_package.count
					end
					alert "#{folder} installed!", title: nil
				end
			end
		end
		start { @q.scroll_top = 1 } ### this is a workaround for a scroll bug that comes with shoes
	end
	
	def purge_pack
		Dir.glob('../data/NCF_*.pak').each { |file| File.delete(file)} ###  NCF creatures
		Dir.glob('../Editor/IconCache/AdvMapObjectLink/MapObjects/_(AdvMapObjectLink)/Monsters/NCF/Creature*').each { |file| File.delete(file)} ###  Cleaning editor Icon cache
		Dir.glob('../Complete/Icons/*.dds').each { |file| File.delete(file)} ###  Editor Icons
	end
	
	background tan..green
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.9
	main_page		
end