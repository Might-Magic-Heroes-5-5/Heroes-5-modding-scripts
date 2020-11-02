require "FileUtils"

Shoes.app do
	para "START"
	NCF_dirs = Dir.entries("heroes/").reject {|fn| fn.include?('.')}
	#NCF_dirs = [ "650" ]
	stack do
		NCF_dirs.each_with_index do |dr,i|
			files = Dir["heroes/#{dr}/**/*"].reject {|fn| File.directory?(fn) }
			files.each do |f|
				if f.end_with?("spec.txt") then
					nil
				else
					para(f)
					#FileUtils.move f, "D:/google drive/H55_project/skillwheel90/design/heroes/"
					#File.delete(f)
				end
			end
			#if i == 0 then break end
		end
	end
	para "COMPLETE!"
end