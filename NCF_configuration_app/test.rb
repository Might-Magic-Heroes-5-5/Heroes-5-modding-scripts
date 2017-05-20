Shoes.app(title: " v1.0", width: 500, height: 500, resizable: true ) do
	background green
	@main = stack left: 0.05, top: 0.15, width: 0.9, height: 0.8, scroll: true do
		background beige
		100.times do |i|
			para "#{i} times"
		end
	end
end