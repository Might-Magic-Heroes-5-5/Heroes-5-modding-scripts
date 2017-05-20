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
		@main.clear do
			background beige
			(Dir.entries("NCF_repository\\Legacy pack").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
				para "#{i+1}. #{ncf}"
			end
		end
	end
		
	background tan
	subtitle "NCF Configuration Utility", align: "center"
	@main = stack left: 0.05, top: 0.15, width: 0.9, height: 0.8
	main_page
		
end

