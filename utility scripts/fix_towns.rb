Shoes.app do
	NCF_dirs = Dir.entries("NCF_separated/").reject {|fn| fn.include?('.')}
	count = 0
	
	### change all creatures .xdb files town affiliation to no_town
	
	#NCF_dirs.each do |dr|
	#	file_name = "NCF_separated/#{dr}/GameMechanics/Creature/Creatures/Neutrals/Creature_#{dr}.xdb"
		#if File.file?(file_name) then
		#	text = File.read(file_name)
			#new_text = text.gsub(/<CreatureTown>.*<\/CreatureTown>/, "<CreatureTown>TOWN_NO_TYPE</CreatureTown>")
			#File.open(file_name, "w") { |file| file.puts new_text }
		#else
	#		debug("Could not find creature xdb for #{dr}")
		#end
	#end
	
	### check all files consistency
	
	NCF_dirs.each do |dr|
		file_name = "NCF_separated/#{dr}/GameMechanics/Creature/Creatures/Neutrals/Creature_#{dr}.xdb"
		if File.file?(file_name) then
			text = File.read(file_name)
			if text.include?("<CreatureTown>TOWN_NO_TYPE</CreatureTown>") then
				count+=1
			else
				debug(dr)
			end
		else
			debug(dr)
		end
	end
	para "COMPLETE! #{count}"
end