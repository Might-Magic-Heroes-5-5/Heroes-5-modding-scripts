second.clear do
			#image 'pics/themes/Untitled.png', width: 795, top: 5
			#border green, strokewidth: 5
			fill rgb(135, 206, 250, 0.3)
			oval left: 400, top: 400, width: 780, height: 780, center: true;
			#fill rgb(220, 255, 70, 0.5)..rgb(50, 50, 50, 0.5)
			fill rgb(170, 205, 50, 0.3)
			oval left: 400, top: 400, width: 662, height: 662, center: true;
			fill rgb(218, 165, 32, 0.3)
			oval left: 396, top: 396, width: 546, height: 546, center: true;
			fill rgb(248, 84, 34, 0.3)
			oval left: 394, top: 397, width: 435, height: 435, center: true;
			c_width, c_height, step, start_rad = 749, 750, Math::PI/6, 0  ########### using math formula to define the circular postion of the skill nests
			#oval left: 400, top: 400, width: 70, height: 70, center: true;	
				line 398, 20, 398, 250, strokewidth: 2
				line 584, 68, 507, 203
				line 726, 205, 588, 284
				line 780, 400, 617, 400
				line 727, 593, 530, 472, strokewidth: 2
				line 590, 733, 505, 590
				line 398, 780, 398, 619
				line 202, 728, 281, 589
				line 70, 590, 267, 469, strokewidth: 2
				line 20, 400, 172, 400
				line 70, 205, 204, 282
				line 208, 68, 285, 203
			for q in 0..11
				angle = -1.46 + (Math::PI/21)*(q%3)
				q>1 ? ( ( ( q+1 )%3 ) == 1 ? start_rad += 60 : nil ) : nil
				radius = 362 - start_rad
				for w in 0..11
					x, y = (c_width/2 + radius * Math.cos(angle)).round(0), (c_height/2 + radius * Math.sin(angle)).round(0)
					angle += step
					@box[w][q] = flow left: x, top: y, width: @icon_size2 + 6, height: @icon_size2 + 6
				end
			end	
			@wheel_left = image "pics/buttons/wheel_arrow.png", left: 350, top: 280 do end.hide.rotate 180
			@wheel_right = image "pics/buttons/wheel_arrow.png", left: 420, top: 280 do end.hide
			@box_hero = flow left: 360, top: 355, width: 80, height: 100
			@left_button = image "pics/buttons/normal.png", left: 330, top: 357, width: 25, height: 80 do end.hide.rotate 180
			@right_button = image "pics/buttons/normal.png", left: 445, top: 357, width: 25, height: 80 do end.hide
			@wheel_left.click { @wheel_left.style[:hidden] == true ? nil : @wheel_turn-=1; set_skillwheel }
			@wheel_right.click { @wheel_right.style[:hidden] == true ? nil : @wheel_turn+=1; set_skillwheel }
		end