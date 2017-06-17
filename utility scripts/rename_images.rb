

Shoes.app do
	filenames = Dir.glob("Legacy pack/icons/*.dds") 
	filenames.each do |fn|
		File.rename(fn, "NCF_#{fn.split("/")[-1][/Creature_(.*?).dds/m, 1]}.dds")
	end
	para "DONE"
end
