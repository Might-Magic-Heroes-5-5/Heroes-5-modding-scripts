Shoes.app do
	asd=flow left: 50, top: 50 do
		check checked: false
		para "Broke the shoes :("
	end
	start {debug(asd.contents[0].checked?)}
end
