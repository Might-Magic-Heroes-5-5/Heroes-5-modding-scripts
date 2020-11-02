require "securerandom"
require 'code/map_spec'

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
		File.open("map.xdb", "w") do |file|
			file.puts VARS.header
			NCF_dirs.each_with_index do |dr, i|
				i < 179 ? next : nil
				file_name = "NCF_separated/#{dr}/MapObjects/_(AdvMapObjectLink)/Monsters/NCF/Creature_#{dr}.xdb"
				if File.file?(file_name) then
					map_object = read_skills file_name, 0, "<Link href=\"", "\"/>"
					uuid = "item_#{SecureRandom.uuid.upcase}"
					file.puts VARS.creature % [uuid, map_object[0], 5 + (dr.to_i / 50)*5, 20 + (dr.to_i % 50) * 2 ]
				else
					para "#{dr}. #{file_name}"
				end
				#i == 300 ? break : nil
			end
			file.puts VARS.tail
		end
		para "Finished"
	end
end