Shoes.app do

	def read_skills text, int = 0, first = nil, second = nil
		skills = []
		if File.file?(text) == true 
			File.read(text).each_line do |line|
				is=line#.chop
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
	
	def sanitize_path path, curr_path
		path.start_with?('/') ? (return path) : (return curr_path + '/' + path)
	end
	
	stack do
		NCF_dirs = Dir.entries("NCF_separated/").reject {|fn| fn.include?('.')}
		File.open("list.txt", "w") do |file|
			NCF_dirs.each do |dr|
				file_name = "NCF_separated/#{dr}/GameMechanics/Creature/Creatures/Neutrals/Creature_#{dr}.xdb"
				if File.file?(file_name) then
					visuals = read_skills file_name, 0, "<Visual href=\"", "#xpointer"
					creature_name = read_skills "NCF_separated/#{dr}#{visuals[0]}", 0, "CreatureNameFileRef href=\"", "\"/>"
					creature_name = sanitize_path creature_name[0], visuals[0].split('/')[0..-2].join('/')
					name = read_skills "NCF_separated/#{dr}#{creature_name}"
					file.puts "#{dr} #{name[0]}"
				else
					para "#{dr}. #{file_name}"
				end
			end
		end
		para "Finished"
	end
end