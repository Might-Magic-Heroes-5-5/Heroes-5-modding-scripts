Shoes.app do


def read_skills text, int = 0, first = nil, second = nil
	skills = []
	if File.file?(text) == true 
		File.read(text).each_line do |line|
			is=line.chop
			if first.nil? or second.nil? then
				skills << is
			elsif (is[/#{first}(.*?)#{second}/m, 1]).nil? == false then
				skills << (is)[/#{first}(.*?)#{second}/m, 1];
			end
		end
		case int
		when 1 then skills.each_with_index { |n, i|	skills[i] = n.to_i } 
		when 2 then skills.each_with_index { |n, i|	skills[i] = n.to_f }
		end
	end
	return skills
end


	(Dir.entries("Raw").reject {|fn| fn == '.' or fn == '..'}).each_with_index do |ncf, i|
		#debug("All_NCF_creatures\\#{ncf}\\Text\\Game\\Creatures")
		#Dir.glob("All_NCF_creatures/#{ncf}/Text/Game/Creatures/**/*").reject {|fn| fn.include?('Desc') or fn.include?('desc') or File.directory?(fn)}.each do |name|
		Dir.glob("Raw/#{ncf}/GameMechanics/Creature/Creatures/**/*").reject {|fn| fn.include?('Desc') or fn.include?('desc') or File.directory?(fn)}.each do |name|
			debug("#{ncf} #{File.read(name)}")
			#debug(read_skills name, 0, "<BaseCreature>", "</BaseCreature>")
			#D:\mod workplace\NCF\Raw\180\GameMechanics\Creature\Creatures\Neutrals\thunderbird.xdb
			#debug(name)
		end
	end
end