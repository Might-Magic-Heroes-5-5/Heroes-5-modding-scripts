Shoes.app do
	(Dir.entries("All_NCF_creatures").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
		#debug("All_NCF_creatures\\#{ncf}\\Text\\Game\\Creatures")
		Dir.glob("All_NCF_creatures/#{ncf}/Text/Game/Creatures/**/*").reject {|fn| fn.include?('Desc') or fn.include?('desc') or File.directory?(fn)}.each do |name|
			debug("#{ncf} #{File.read(name)}")
			#debug(name)
		end
	end
end