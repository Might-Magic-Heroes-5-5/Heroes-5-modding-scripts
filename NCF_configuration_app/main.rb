Shoes.app(title: " v1.0", width: 500, height: 500, resizable: true ) do

    def main_page
		@main.clear do
			background beige
			(Dir.entries("NCF_repository").reject {|fn| fn.include?('.')}).each_with_index do | f, i |
				button "#{f}", left: 0.4, top: 0.15 + 0.1*i, width: 0.2 do 
					list_creatures f
				end
			end
		end
	end
	
	def list_creatures folder
		@main.clear fill: rgb(100,244,40) do
			background beige#, width: @main.width, height: 2000
			@from = 0
			name_file = File.readlines("\NCF_lists\\legacy_list.txt")
			#debug (File.readlines("\NCF_lists\\legacy_list.txt")[1..5])
			(Dir.entries("NCF_repository\\Legacy pack").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
				num = ncf[/NCF_(.*?).pak/m, 1]
				name_file[@from..-1].each do |line|
					@from+=1
					line.include?(num)? (para "#{num}. #{line.split(" ")[1]}";break;) : nil
				end
			end
		end
		debug("#{@main.width}, #{@main.height}")
		#@main.contents[0].style width: @main.width, height: @main.height
	end
		
	background tan
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.15, width: 0.9, height: 0.8, scroll: true
	main_page
		
end

