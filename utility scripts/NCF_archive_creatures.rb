require 'zip'

Shoes.app do
	NCF_dirs = Dir.entries("Boulder_test_ncf/").reject {|fn| fn.include?('.')}
	#NCF_dirs = [ "650" ]
	NCF_dirs.each do |dr|
		files = Dir["Boulder_test_ncf/#{dr}/**/*"].reject {|fn| File.directory?(fn) }
		Zip::File.open("boulder_pack/NCF_#{dr}.pak", Zip::File::CREATE) do |zzip|
			files.each do |f|
				file_to_zip = f.split("#{dr}/",2)
				debug(file_to_zip)
				zzip.add(file_to_zip[1],f)
			end
		end
	end
	para "COMPLETE!"
end