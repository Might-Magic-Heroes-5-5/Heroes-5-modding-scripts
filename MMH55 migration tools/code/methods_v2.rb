def check_dir file, origin; return file.start_with?("/")? file : ((origin.split('data')[1].split('/'))[0...-1].join('/') + '/' + file ) end

def calc num
  result = num.to_f*100
  result % 1 == 0 ? result = result.to_i : nil
  return result
end

def sort_line line, first, second
	if (line.chop[/#{first}(.*?)#{second}/m, 1]).nil? == false then
		return (line)[/#{first}(.*?)#{second}/m, 1];
	end
end

def make_text dirr, target, source, mode=0, type='f',
	script = $0
	FileUtils.mkpath dirr
	
	case type
	when 't' then data_to_copy = source
	when 'f' then
		input = File.open(source)
		data_to_copy = []
		data_to_copy << input.read()
		input.close()
	end
	
	case mode
	when "hero" then
		data_to_copy[0].gsub!(/<br><br>/, "\n")
		data_to_copy[0].gsub!(/<br>/, "\n")
		data_to_copy[0].gsub!(/<body_bright>/, '')
		data_to_copy[0].gsub!(/<color=.*?>/, '')
		data_to_copy = data_to_copy[0].split('<color_default>', target.count).each { |m| m.gsub!(/<color_default>/, '') }
	when "artifact" then
		data_to_copy[0].gsub!(/<color=.*?>/, '')
		data_to_copy = data_to_copy[0].split('<br><br>', target.count).each { |m| m.gsub!(/<br>/, "\n") }
	when "spell" then
		data_to_copy[0].gsub!(/<br>/,'')
		data_to_copy[0].gsub!(/<body_bright>/, '')
		data_to_copy = data_to_copy[0].split('<color_default>', target.count).each { |m| m.gsub!(/<color_default>/, '') }
	when "skill" then
		if data_to_copy[0].include?('<color=orange>') then
			data_to_copy[0].gsub!(/<br><br>/, "")
			data_to_copy[0].gsub!(/<br>/, "\n")
			data_to_copy[0].gsub!(/<color_default>/, "")
			data_to_copy = data_to_copy[0].split('<color=orange>', target.count ).each { |m| m.gsub!(/<color=orange>/, '') }
		else
			data_to_copy[0].gsub!(/<br>/, "\n")
			data_to_copy = data_to_copy[0].split('<color_default>', target.count ).each { |m| m.gsub!(/<color_default>/, '') }
		end
	when "pred"
		data_to_copy[0].gsub!(/<br>/, "\n")
	end
	#debug("#{dirr},#{target},#{mode}")
	data_to_copy.each_with_index do |t, i|
		@OUTPUT = File.open("#{dirr + '/' + target[i]}.txt", 'w');
		@OUTPUT.write("#{t.strip}")
		@OUTPUT.close()
	end
end


class Town

	def initialize( t_id, t_txt )
		@town_id = t_id		  			## Get vars
		@text = t_txt					## Get txt
	end
	
	def town_id; return @town_id end
	def text; return @text end
	
end	

class Klass < Town
		
	def initialize( c_id, at, df, sp, kn, t_id, text )
		super( t_id, text )														## Get inherited vars
		@class_id, @at, @df, @sp, @kn = c_id, at, df, sp, kn					## Get klas vars
	end

	def get_skills(source, filter)
		@secondary_skills, @secondary_chance = [], []
		source.xpath(filter).each_with_index do |s, i|		
			(i.even? ? @secondary_skills : @secondary_chance) << s.text
		end
	end
	
	def get_hero(h_id, h_obj )
		@class_heroes_id << h_id
		@class_heroes_obj << h_obj
	end
	
	def class_id; return @class_id end
	def stats; return@class_id, @at, @df, @sp, @kn, @town_id end
	def skills; return @secondary_skills, @secondary_chance end
	def text; return @text end
	
end

class Hero < Klass
	
	def initialize( h_id, at, df, sp, kn, skill, mastery, perk, spell, c_id, t_id, text, text_spec)
		super(c_id, at, df, sp, kn, t_id, text)												## Get inherited vars
		@hero_id, @skill, @mastery, @perk, @spell = h_id, skill, mastery, perk, spell 		## Get hero vars
		@text_spec = text_spec 					 					   					    ## Get text vars
	end
	
	def hero_id; return @hero_id end
	def stats; return @hero_id, @at, @df, @sp, @kn, @skill, @mastery, @perk, @spell, @class_id, @town_id end
	def text; return @text, @text_spec end	
end	

class Skill
	
	def initialize( p_id, type, skill_base, skill_req, txt_name, text_spec)
		@perk_id, @type, @skill_base, @skill_req = p_id, type, skill_base, skill_req	 ## Get perk vars
		@txt_name, @txt_desc = txt_name, text_spec 	 			 						 ## Get text vars
	end

	def stats; return @perk_id, @type, @skill_base end
	def req; return @skill_req end
	def texts; return @txt_name, @txt_desc end
end
	
class Creature
	
	def initialize(id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability, gold, wood, ore, mercury, crystal, sufur, gem, txt_name)
		@id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability = id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability  ###Get creature vars
		@gold, @wood, @ore, @mercury, @crystal, @sufur, @gem = gold, wood, ore, mercury, crystal, sufur, gem
		@txt_name = txt_name 				 																																																		###Get text vars
	end

	def id; return @id end
	def stats; return @id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability end
	def price; return @gold, @wood, @ore, @mercury, @crystal, @sufur, @gem end
	def texts; return @txt_name end
end

class Ability

	def initialize(id, name, desc)
		@id = id
		@name, @desc = name, desc
	end
	
	def id; return @id end
	def name; return @name end
	def desc; return @desc end
	
end

class Spell
	
	def initialize(id, spell_effect, spell_increase, mana, tier, guild, resource_cost, txt_name, txt_desc, txt_pred)
		@id, @spell_effect, @spell_increase, @mana, @tier, @guild, @resource_cost = id, spell_effect, spell_increase, mana, tier, guild, resource_cost  ###Get spell vars
		@txt_name, @txt_desc, @txt_pred = txt_name, txt_desc, txt_pred		 																			###Get text vars
	end
	
	def id; return @id end
	def stats; return @id, @spell_effect, @spell_increase, @mana, @tier, @guild, @resource_cost end
	def texts; return @txt_name, @txt_desc, @txt_pred end
end

class Artifact
	
	def initialize(id, slot, cost, type, at, df, sp, kn, moral, luck, set, sell, txt_name, txt_desc)
		@id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set, @sell = id, slot, cost, type, at, df, sp, kn, moral, luck, set, sell  ###Get artifact vars
		@txt_name, @txt_desc = txt_name, txt_desc			 																			  ###Get text vars
	end

	def stats; return @id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set, @sell end
	def texts; return @txt_name, @txt_desc end
end

class Micro_artifact
	
	def initialize(id, effect, gold, wood, ore, mercury, crystal, sufur, gem, txt_name, txt_suffix, txt_desc )
		@id, @effect = id, effect  ###Get artifact vars
		@gold, @wood, @ore, @mercury, @crystal, @sufur, @gem = gold, wood, ore, mercury, crystal, sufur, gem
		@txt_name, @txt_suffix, @txt_desc = txt_name, txt_suffix, txt_desc			 																		###Get text vars
	end

	def stats; return @id, @effect end
	def price; return @gold, @wood, @ore, @mercury, @crystal, @sufur, @gem end
	def texts; return @txt_name, @txt_suffix, @txt_desc end
end

class Micro_shell
	
	def initialize(id, txt_name, txt_desc )
		@id = id  ###Get artifact vars
		@txt_name, @txt_desc = txt_name, txt_desc			 																		###Get text vars
	end

	def stats; return @id end
	def texts; return @txt_name, @txt_desc end
end

class Manage_db
	
	def initialize(db, flag=1)
		@flag = flag
		if @flag == 1 then
			@db = SQLite3::Database.new "#{db}"
			@db.execute "create table factions ( name string );"
			@db.execute "create table heroes ( id string, atk int, def int, spp int, knw int, skills string, masteries string, perks string, spells string, classes string, faction string, sequence int );"
			@db.execute "create table classes ( id string, atk_c int, def_c int, spp_c int, knw_c int, faction string, sequence int );"
			@db.execute "create table skills (name string, type string, tree string, sequence int);"
			@db.execute "create table creatures ( id string, at int, df int, shots int, min_d int, max_d int, spd int, init int, fly int, hp int,
	spells string, spell_mastery string, mana int, tier int, faction string, growth int, ability string,
	gold int, wood int, ore int, mercury int, crystal int, Sulfur int, gem int, sequence int );"
			@db.execute "create table guilds ( id string, sequence int );"
			@db.execute "create table spells ( id string, spell_effect string, spell_increase string, mana int, tier int, guild string, resource_cost string );"
			@db.execute "create table spells_specials ( id string, base string, perpower string );"
		end
	end
	
	def town_update(towns)
		towns.each { |t| @db.execute("INSERT INTO factions ( name ) VALUES ( '#{t.town_id}' )") } if @flag == 1
	end
	
	def hero_update(heroes)
		heroes.each { |h| @db.execute("insert into heroes values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )", h.stats, 0) } if @flag == 1
	end
	
	def class_update(classes, skills)
		if @flag == 1 then
			classes.each do |c|
				@db.execute "insert into classes values ( ?, ?, ?, ?, ?, ?, ? )", c.stats, 1
				@db.execute "create table #{c.class_id} (skill string, chance int, type string, sequence int);"
				skills_name, skills_chance = c.skills
				skills_name.each_with_index do |_,i|
					@db.execute "insert into #{c.class_id} values ( ?, ?, ?, ? );", skills_name[i], skills_chance[i], 'SKILLTYPE_SKILL', i
				end
				skills.each do |s|
					s.req.each do |r|
						next if c.class_id != r.xpath("Class").text
						req_skills = []
						r.xpath("dependenciesIDs/Item").each { |p| req_skills << p.text }
						#if (@db.execute "select skill from #{c.class_id} where type='SKILLTYPE_SKILL'").join(",").include?(s.stats[2] ) then
						if skills_name.include?(s.stats[2])
							@db.execute "insert into #{c.class_id} values ( ?, ?, ?, ?);",s.stats[0], req_skills.join(','), s.stats[1], '99' if not req_skills.empty?
						end
						break
					end
				end
			end
		end
	end
	
	def skill_update(skills)
		if @flag == 1 then
			skills.each do |s| 
				if s.stats[1] == "SKILLTYPE_SKILL" or s.stats[1] == "SKILLTYPE_STANDART_PERK" then
					@db.execute "insert into skills values ( ?, ?, ?, ? );", s.stats, 1
				else
					s.stats[3]
				end
			end
		end
	end
	
	def unit_update(units)
		if @flag == 1 then
			units.each do |u|
				@db.execute "insert into creatures values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?, ?, ?, ?, ? );", u.stats, u.price, 0
			end
		end
	end
	
	def spell_update(spells); spells.each { |s|	@db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", s.stats } if @flag == 1 end
	
	def spells_spec(spells_spec); spells_spec.each { |s| @db.execute "insert into spells_specials values ( ?, ?, ? );", s[0], s[1], s[2] } if @flag == 1 end
	
	def guild_update(guilds); guilds.each_with_index { |g,i| @db.execute "insert into guilds values (?, ?)", g, i } if @flag == 1 end
	
end

class Manage_texts

	def initialize(var, flag=1); @flag = flag end
	
	def town_update(towns);	towns.each { |t| make_text "#{OUTPUT}/factions/#{t.town_id}", ["name"], [ t.text ], 0, 't' } if @flag == 1 end
	
	def hero_update(heroes)
		if @flag == 1 then
			heroes.each do |h| 
				make_text "#{OUTPUT}/heroes/#{h.stats[0]}", [ "name" ], "#{SOURCE_TXT}#{h.text[0]}"
				make_text "#{OUTPUT}/heroes/#{h.stats[0]}", ["spec", "additional" ], "#{SOURCE_TXT}#{h.text[1]}", 'hero'
			end
		end
	end
	
	def class_update(classes); classes.each { |c| make_text "#{OUTPUT}/classes/#{c.stats[0]}", ["name"], "#{SOURCE_TXT}/GameMechanics/RefTables/#{c.text}" } if @flag == 1 end
	
	def skill_update(skills)
		if @flag == 1 then
			skills.each do |s|
				if s.stats[1] == "SKILLTYPE_SKILL" then
					s.texts[0].each_with_index do |_, q|
						make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["name#{q+1}"], "#{SOURCE_TXT}/#{s.texts[0][q]}"
						make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["desc#{q+1}", "additional#{q+1}"], "#{SOURCE_TXT}/#{s.texts[1][q]}", 'skill'
					end
				else
					make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["name"], "#{SOURCE_TXT}/#{s.texts[0][0]}"
					make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["desc", "additional" ], "#{SOURCE_TXT}/#{s.texts[1][0]}", 'skill'
				end
			end
		end
	end

	def unit_update(units); units.each { |u| make_text "#{OUTPUT}/creatures/#{u.id}", [ "name" ], "#{SOURCE_TXT}#{u.texts}" } if @flag == 1 end
	
	def ability_update(abilities)
		if @flag == 1 then
			abilities.each do |a|
				make_text "#{OUTPUT}/abilities/#{a.id}", [ "name" ], "#{SOURCE_TXT}#{a.name}"
				make_text "#{OUTPUT}/abilities/#{a.id}", [ "desc" ], "#{SOURCE_TXT}#{a.desc}"
			end
		end
	end
	
	def spell_update(spells)
		if @flag == 1 then
			spells.each do |s|
				make_text "#{OUTPUT}/spells/#{s.id}", [ "name" ], "#{SOURCE_TXT}/#{s.texts[0]}" 
				make_text "#{OUTPUT}/spells/#{s.id}", [ "desc", "additional" ], "#{SOURCE_TXT}/#{s.texts[1]}", 'spell';
				s.texts[2].each do |p|
					#p = check_dir p, dr_source
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('SpellBookPrediction.txt')
				    ( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred_expert" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('SpellBookPrediction_Expert')
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('HealHPReduce.txt')
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_ADD}/none.txt", 'pred' ) if s.stats[5] == 'MAGIC_SCHOOL_ADVENTURE'
				end
			end
			make_text "#{OUTPUT}/spells", [ "universal_prediction" ], "#{SOURCE_TXT}/Text/Game/Spells/SpellBookPredictions/DirectDamage.txt", 'pred'
		end
	end
	
	def guild_update(guilds); guilds.each { |g| make_text "en/guilds/#{g}", [ "name" ], "#{SOURCE_TXT}/Text/Tooltips/SpellBook/#{GUILD_TEXT[:"#{g}"]}.txt" } if @flag == 1 end
end