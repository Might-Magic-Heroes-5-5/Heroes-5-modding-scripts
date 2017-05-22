Shoes.app(title: " v1.0", width: 500, height: 600, resizable: false ) do

    def main_page
		@main.clear do
			stack left: 5, top: 15, width: 440, height: 100 do
				rect(left: 0, top: 0, curve: 10,  width: 435, height: 98, fill: rgb(245,245,220))
				caption "Select NCF package to install", align: "center"
			end
			stack left: 40, top: 130, width: 152, height: 252 do
				rect(left: 0, top: 0, curve: 10,  width: 150, height: 250, fill: rgb(245,245,220))
				caption "Core", align: "center"
				Dir.entries("NCF_core").reject {|fn| fn.include?('.')}.each_with_index { | f, i | button("#{f}", left: 25, top: 35 + 40*i, width: 100) { list_core f } }
			end
			stack left: 250, top: 130, width: 152, height: 252 do
				rect(left: 0, top: 0, curve: 10,  width: 150, height: 250, fill: rgb(245,245,220))
				caption "NCF package", align: "center"
				Dir.entries("NCF_repository").reject {|fn| fn.include?('.')}.each_with_index { | f, i | button("#{f}", left: 25, top: 35 + 40*i, width: 100) { list_creatures f } }
			end
			#inscription "Note: Packages are not compatible.", top: 400
		end
	end
	
	def list_core folder
	 
	
	end
	
	def list_creatures folder
		@custom_ncf_package = []
		@main.clear fill: rgb(100,244,40) do
			rect(left: 0, top: 0, curve: 10,  width: @main.width-3, height: @main.scroll_height-60, fill: rgb(245,245,220))
			@from = 0
			name_file = File.readlines("\NCF_lists\\legacy_list.txt")
			tagline "Legacy pack list", align: "center"
			line 20, 35, 420, 35
			check(left: 30, top: 40, checked: false) { |c| @main.contents[6].contents.each { |f| f.contents[0].checked = c.checked? ? true : false} }
			caption "Select All", left: 50, top: 39
			line 20, 70, 420, 70
			@q = stack left: 20, top: 75, width: 420, height: 400, scroll: true do
				(Dir.entries("NCF_repository\\Legacy pack").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
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
			button( "Back", left: 5, top: 490 ) { main_page }
			button( "Next", left: 380, top: 490 ) { pre_deployment }
			#inscription "Caution: All NCF creatures in DATA folder are purged before package install.", top: 500
		end
		start { @q.scroll_top = 1 }
	end
	
	def pre_deployment
		@main.clear fill: rgb(100,244,40) do
			rect(left: 90, top: 25, curve: 10,  width: 270, height: 250, fill: rgb(245,245,220))
			caption "Deploy NCF for:", top: 30, align: "center"
			[ "Tribes of the East 3.1", "MMH5.5" ].each_with_index { |ver, i| radio( left: 135, top: 70+i*30 );  para ver, left: 155, top: 73+i*25 }
			inscription "Note: Packages are not compatible.", top: 290
		end
	end
		
	background tan
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.9
	main_page		
end

