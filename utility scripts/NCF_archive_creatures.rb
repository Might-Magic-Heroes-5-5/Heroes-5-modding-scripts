require 'zip'

Shoes.app do
	NCF_dirs = Dir.entries("NCF_separated/").reject {|fn| fn.include?('.')}
	#NCF_dirs = [ "650" ]
	NCF_dirs.each do |dr|
		files = Dir["NCF_separated/#{dr}/**/*"].reject {|fn| File.directory?(fn) or fn == 'list' or fn == 'Icons' }
		Zip::File.open("NCF_archived/NCF_#{dr}.pak", Zip::File::CREATE) do |zzip|
			files.each do |f|
				file_to_zip = f.split("#{dr}/",2)
				debug(file_to_zip)
				zzip.add(file_to_zip[1],f)
			end
		end
	end
	para "COMPLETE!"
end