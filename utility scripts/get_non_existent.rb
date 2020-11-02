Shoes.app do
	NCF_dirs = Dir.entries("NCF_separated/").reject {|fn| fn.include?('.')}
	#debug(NCF_dirs)
end