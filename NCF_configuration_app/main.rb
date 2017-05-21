Shoes.app(title: " v1.0", width: 500, height: 600, resizable: false ) do

    def main_page
		@main.clear do
			rect(left: 90, top: 25, curve: 10,  width: 270, height: 250, fill: rgb(245,245,220))
			caption "Select NCF package to install", align: "center", top: 30
			(Dir.entries("NCF_repository").reject {|fn| fn.include?('.')}).each_with_index do | f, i |
				button("#{f}", left: 0.4, top: 0.25 + 0.1*i, width: 0.2) { list_creatures f }
			end
			inscription "Note: Packages are not compatible.", top: 290
		end
	end
	
	def list_creatures folder
		@main.clear fill: rgb(100,244,40) do
			rect(left: 0, top: 0, curve: 10,  width: @main.width-18, height: @main.scroll_height-2, fill: rgb(245,245,220))
			@from = 0
			name_file = File.readlines("\NCF_lists\\legacy_list.txt")
			tagline "Legacy pack list", align: "center"
			line 20, 35, 420, 35
			button "Next" do
				
			end
			check(left: 130, top: 40, checked: false) { |c| @main.contents[6].contents.each { |f| f.contents[0].checked = c.checked? ? true : false} }
			caption "Select All", left: 150, top: 39
			line 20, 70, 420, 70
			@q = stack left: 20, top: 75, width: 400, height: 400, scroll: true do
				#border orange
				(Dir.entries("NCF_repository\\Legacy pack").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
					num = ncf[/NCF_(.*?).pak/m, 1]
					name_file[@from..-1].each do |line|
						@from+=1
						if line.include?(num) then
							flow left: 60, top: 10 + 30*i, width: 0.8 do
								#border black
								check checked: false
								para "#{num}. #{line.split(" ")[1..-1].join(" ")}"
							end
							break;
						end
					end
				end
			end
		end
		start { @q.scroll_top = 1 }
		#inscription "Caution: NCF creatures in DATA folder are purged during package install."
	end
		
	background tan
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.1, width: 0.9, height: 0.8
	main_page		
end

