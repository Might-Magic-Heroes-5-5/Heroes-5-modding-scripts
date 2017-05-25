require 'fileutils'

Shoes.app(title: " New Creature Framework: Configuration utility", width: 500, height: 600, resizable: false ) do

	def filter_files path
		return Dir.entries(path).reject { |rj| ['.','..'].include?(rj) }
	end
	
    def main_page
		@main.clear do
			stack left: 5, top: 15, width: 440, height: 100 do
				rect(left: 0, top: 0, curve: 10,  width: 435, height: 98, fill: rgb(245,245,220))
				@info = caption "", align: "center"
			end
			@core = stack left: 40, top: 130, width: 152, height: 252;
			@pack = stack left: 250, top: 130, width: 152, height: 252;
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
			rect(left: 0, top: 0, curve: 10,  width: 150, height: 250, fill: rgb(245,245,220))
			caption "Core", align: "center"
			main_pack_block "disabled"
			(filter_files "NCF_repository/core").each_with_index do | f, i |
				if ((filter_files "NCF_repository/core/#{f}/data") & (File.directory?("data") ? (filter_files "data") : [] )).empty? then
					button("#{f}", left: 25, top: 35 + 40*i, width: 100) { deploy_core f; }
					@info.replace "Please install NCF core for the required game."
				else
					@info.replace "Deploy a NCF package."
					@core.clear do
						rect(left: 0, top: 0, curve: 10,  width: 150, height: 250, fill: rgb(240,240,20))
						caption "Core", align: "center" 
						caption "#{f}\nis deployed", align: "center", displace_top: 40
						button("Uninstall", left: 25, top: 200, width: 100 ) { [ "yes", "y", "Y", "YES" ].include?(ask("This will purge previous NCF installations. Are you sure(Y/N)?")) ? purge_core : nil }
					end;
					main_pack_block "enabled"
					break;
				end
			end
		end
	end

	def main_pack_block stat #"disabled"
		@pack.clear do
			rect(left: 0, top: 0, curve: 10,  width: 150, height: 250, fill: rgb(245,245,220))
			caption "NCF package", align: "center"
			(filter_files "NCF_repository/packs").each_with_index { | f, i | button("#{f}", left: 25, top: 35 + 40*i, width: 100, state: stat ) { deploy_pack f } }
		end
	end
	
	def deploy_core folder
		if [ "yes", "y", "Y", "YES" ].include?(ask("Are you sure you want to deploy NCF core for #{folder}(Y/N)?\n")) then
			FileUtils.copy_entry "NCF_repository/core/#{folder}/", "."
			main_core_block
		end
	end
	
	def purge_core
		Dir.glob("NCF_repository/core/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
			file_name = fn.split("/")[3..-1].join("/")
			File.delete(file_name) if File.exist?(file_name)
		end
		main_core_block
	end
			
	def deploy_pack folder
		@custom_ncf_package = []
		@main.clear fill: rgb(100,244,40) do
			rect(left: 0, top: 0, curve: 10,  width: @main.width-3, height: @main.scroll_height-60, fill: rgb(245,245,220))
			@from = 0
			name_file = File.readlines("NCF_repository/lists/legacy_list.txt")
			tagline "Legacy pack list", align: "center"
			line 20, 35, 420, 35
			check(left: 30, top: 40, checked: false) { |c| @main.contents[7].contents.each { |f| f.contents[0].checked = c.checked? ? true : false} }
			caption "Select All", left: 50, top: 39
			@bar = progress left: 155, top: 39, width: 250
			line 20, 70, 420, 70
			@q = stack left: 20, top: 75, width: 420, height: 400, scroll: true do
				(filter_files "NCF_repository/packs/#{folder}").each_with_index do |ncf, i|
					num = ncf[/NCF_(.*?).pak/m, 1]
					name_file[@from..-1].each do |line|
						@from+=1
						if line.include?(num) then
							flow left: 60, top: 10 + 30*i, width: 0.8 do
								check(checked: false) { |cc| cc.checked? ? @custom_ncf_package.push(ncf) : @custom_ncf_package.delete(ncf) }
								para "#{num}. #{line.split(" ")[1..-1].join(" ")}"
							end
							break;
						end
					end
				end
			end
			button( "Back", left: 5, top: 490, width: 100 ) { main_page }
			button( "Deploy", left: 340, top: 490, width: 100 ) do
				if [ "yes", "y", "Y", "YES" ].include?( ask("Any previously installed NCF creatures will be removed. Are you sure(Y/N)?")) then
					purge_pack
					@custom_ncf_package.each_with_index do |ncf, i|	
						FileUtils.copy_file "NCF_repository/packs/#{folder}/#{ncf}", "data/#{ncf}"
						@bar.fraction = (i*100)/@custom_ncf_package.count
					end
					alert "#{folder} installed!", title: nil
				end
			end
		end
		start { @q.scroll_top = 1 }
	end
	
	def purge_pack
		Dir.glob('data/NCF_*.pak').each { |file| File.delete(file)}
	end
	
	background tan
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.9
	main_page		
end

