require 'zip'


Shoes.app do
	NCF_dirs = Dir.entries("../All_NCF_creatures/").reject {|fn| fn.include?('.')}
	#NCF_dirs = [ "180" ]
	NCF_dirs.each do |dr|
		files = Dir["../All_NCF_creatures/#{dr}/**/*"].reject {|fn| File.directory?(fn) }
		Zip::File.open("pack repository/NCF_#{dr}.pak", Zip::File::CREATE) do |zzip|
			files.each do |f|
				zzip.add(f.split('/')[3..-1].join('/'),f)
			end
		end
	end
	para "COMPLETE!"

end