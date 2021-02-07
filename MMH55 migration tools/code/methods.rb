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
		data_to_copy[0].gsub!(/<color_.*?>/, '')
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
	when "ability" then
		data_to_copy[0].gsub!(/<br>/, "")
		data_to_copy[0].gsub!(/<color_default>/, " ")
	when "pred"
		data_to_copy[0].gsub!(/<br>/, "\n")
	end
	#debug("#{dirr},#{target},#{mode}")
	data_to_copy.each_with_index do |t, i|
		file_out = File.open("#{dirr + '/' + target[i]}.txt", 'w');
		file_out.write("#{t.strip}")
		file_out.close()
	end
	return data_to_copy
end

def create_AdvMapSharedGroup(heroes)
	cStart = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<AdvMapSharedGroup>\n\t<links>\n"
	cEnd   = "\t</links>\n</AdvMapSharedGroup>"
	classGroup   = {}
	heroes.each do |h|
		fpath = h.hero_source
		fpath.slice!(SOURCE_HEROES)
		if not classGroup.key?(:"#{h.stats[9]}") then
			classGroup[:"#{h.stats[9]}"] = []
		end
		classGroup[:"#{h.stats[9]}"] = classGroup[:"#{h.stats[9]}"] + [ "/MapObjects" + fpath + "#xpointer(/AdvMapHeroShared)" ]
	end
	classGroup.keys.each do |k|
		cBase = ""
		FileUtils.mkpath "#{OUTPUTE}/AdvMapSharedGroup"
		file_out = File.open("#{OUTPUTE}/AdvMapSharedGroup/#{k}.xdb", 'w');
		classGroup[k].each do |v|
			cBase = cBase + "\t\t<Item href=\"#{v}\"/>\n"
		end
		file_out.write("#{cStart + cBase + cEnd}")
		file_out.close()
	end
end

def create_AdvMapObjectLink(classes)
	FileUtils.mkpath "#{OUTPUTE}/AdvMapObjectLink/GenericHeroes"
	lStart = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<AdvMapObjectLink>\n\t<Link/>\n"
	lEnd   = "\t<HideInEditor>false</HideInEditor>\n</AdvMapObjectLink>"
	classes.each do |k|
		input = File.open("#{SOURCE_TXT}/GameMechanics/RefTables/#{k.text}")
		name = input.read().gsub(/\s+/, "")
		input.close()
		lBase = "\t<RndGroup href=\"/MapObjects/_(AdvMapSharedGroup)/Heroes/#{k.class_id}.xdb#xpointer(/AdvMapSharedGroup)\"/>\n\t<IconFile>Icons\\HeroClasses\\MMH55_#{name}.dds</IconFile>\n"
		make_text "#{OUTPUTE}/AdvMapObjectLink/GenericHeroes", ["MMH55_#{name}"], [ "#{lStart + lBase + lEnd}" ], 0, 't'
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
	
	def initialize( h_id, at, df, sp, kn, skill, mastery, perk, spell, c_id, t_id, text, text_spec, srcFile)
		super(c_id, at, df, sp, kn, t_id, text)												## Get inherited vars
		@hero_id, @skill, @mastery, @perk, @spell = h_id, skill, mastery, perk, spell 		## Get hero vars
		@text_spec = text_spec 					 					   					    ## Get text vars
		@sourceF = srcFile
	end
	
	def hero_id; return @hero_id end
	def hero_source; return @sourceF end
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
		@id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability = id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability  				## Get creature vars
		@gold, @wood, @ore, @mercury, @crystal, @sufur, @gem = gold, wood, ore, mercury, crystal, sufur, gem
		@txt_name = txt_name 				 															   ## Get text vars
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
	
	def id; return @id end
	def stats; return @id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set, @sell end
	def texts; return @txt_name, @txt_desc end
end

class Micro_artifact
	
	def initialize(id, effect, gold, wood, ore, mercury, crystal, sufur, gem, txt_name, txt_suffix, txt_desc )
		@id, @effect = id, effect  ###Get artifact vars
		@gold, @wood, @ore, @mercury, @crystal, @sufur, @gem = gold, wood, ore, mercury, crystal, sufur, gem
		@txt_name, @txt_suffix, @txt_desc = txt_name, txt_suffix, txt_desc			 																		###Get text vars
	end

	def id; return @id end
	def stats; return @id, @effect end
	def price; return @gold, @wood, @ore, @mercury, @crystal, @sufur, @gem end
	def texts; return @txt_name, @txt_suffix, @txt_desc end
end

class Micro_shell
	
	def initialize(id, txt_name, txt_desc )
		@id = id  ###Get artifact vars
		@txt_name, @txt_desc = txt_name, txt_desc			 																		###Get text vars
	end

	def id; return @id end
	def texts; return @txt_name, @txt_desc end
end

class Manage_db
	
	def initialize(db, flag=1)
		debug(flag)
		@flag = flag
		if @flag != 0 then
			@db = SQLite3::Database.new "#{db}"
			@db.execute "create table factions ( name string );"
			@db.execute "create table heroes ( id string, atk int, def int, spp int, knw int, skills string, masteries string, perks string, spells string, classes string, faction string, sequence int );"
			@db.execute "create table classes ( id string, atk_c int, def_c int, spp_c int, knw_c int, faction string, sequence int );"
			@db.execute "create table skills (name string, type string, tree string, sequence int);"
			@db.execute "create table creatures ( id string, at int, df int, shots int, min_d int, max_d int, spd int, init int, fly int, hp int,
	spells string, spell_mastery string, mana int, tier int, faction string, growth int, ability string,
	wood int, ore int, mercury int, crystal int, Sulfur int, gem int, gold int, sequence int );"
			@db.execute "create table guilds ( id string, sequence int );"
			@db.execute "create table spells ( id string, spell_effect string, spell_increase string, mana int, tier int, guild string, resource_cost string );"
			@db.execute "create table spells_specials ( id string, base string, perpower string );"
			@db.execute "create table artifacts ( id string, slot string, cost int, type string, attack int, defence int, spellpower int, knowledge int, morale int, luck int, art_set string, sell string );"
			@db.execute "create table artifact_filter ( name string, filter string );"
			@db.execute "create table micro_artifact_effect ( id string, effect int, gold int, wood int, ore int, mercury int, crystal int, Sulfur int, gem int  );"
			@db.execute "create table micro_artifact_shell  ( id string );"
		end
	end
	
	def town(towns)
		towns.each { |t| @db.execute("INSERT INTO factions ( name ) VALUES ( '#{t.town_id}' )") } if @flag != 0
	end
	
	def hero(heroes)
		heroes.each { |h| @db.execute("insert into heroes values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )", h.stats, 0) } if @flag != 0
	end
	
	def klass(classes, skills)
		if @flag != 0 then
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
						if skills_name.include?(s.stats[2])
							@db.execute "insert into #{c.class_id} values ( ?, ?, ?, ?);",s.stats[0], req_skills.join(','), s.stats[1], '99' if not req_skills.empty?
						end
						break
					end
				end
			end
		end
	end
	
	def skill(skills)
		if @flag != 0 then
			skills.each do |s| 
				@db.execute "insert into skills values ( ?, ?, ?, ? );", s.stats, 1 if [ "SKILLTYPE_SKILL", "SKILLTYPE_STANDART_PERK" ].include?(s.stats[1])
			end
		end
	end
	
	def unit(units)
		if @flag != 0 then
			units.each do |u|
				@db.execute "insert into creatures values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?, ?, ?, ?, ? );", u.stats, u.price, 0
			end
		end
	end
	
	def spell(spells); spells.each { |s| @db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", s.stats } if @flag != 0 end
	
	def spell_spec(spells_spec); spells_spec.each { |s| @db.execute "insert into spells_specials values ( ?, ?, ? );", s[0], s[1], s[2] } if @flag != 0 end
	
	def guild(guilds); guilds.each_with_index { |g,i| @db.execute "insert into guilds values (?, ?)", g, i } if @flag != 0 end
	
	def artifact(artifacts); artifacts.each { |a| @db.execute "insert into artifacts values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );", a.stats } if @flag != 0 end
	
	def artifact_filter(filter); filter.each { |f| @db.execute "insert into artifact_filter values ( ?, ?)", f[0], f[1] } if @flag != 0 end
	
	def micro_effect(micro); micro.each { |m| @db.execute "insert into micro_artifact_effect values ( ?, ?, ?, ?, ?, ?, ?, ?, ? );", m.stats, m.price} if @flag != 0 end
	
	def micro_shell(shell); shell.each { |s| @db.execute "insert into micro_artifact_shell values ( ? );", s.id } if @flag != 0 end
	
end

class Manage_texts

	def initialize(var, flag=1); @flag = flag end
	
	def town(towns); towns.each { |t| make_text "#{OUTPUT}/factions/#{t.town_id}", ["name"], [ t.text ], 0, 't' } if @flag != 0 end
	
	def hero(heroes)
		if @flag != 0 then
			heroes.each do |h| 
				make_text "#{OUTPUT}/heroes/#{h.stats[0]}", [ "name" ], "#{SOURCE_TXT}#{h.text[0]}"
				make_text "#{OUTPUT}/heroes/#{h.stats[0]}", ["spec", "additional" ], "#{SOURCE_TXT}#{h.text[1]}", 'hero'
			end
		end
	end
	
	def klass(classes); classes.each { |c| make_text "#{OUTPUT}/classes/#{c.stats[0]}", ["name"], "#{SOURCE_TXT}/GameMechanics/RefTables/#{c.text}" } if @flag != 0 end
	
	def skill(skills)
		master = [ "NONE", "BASIC", "ADVANCED", "EXPERT", "ULTIMATE" ]
		if @flag != 0 then
			aFile = File.new("skills.csv", "w") if @flag == 2
			skills.each do |s|
				dscp = []
				if s.stats[1] == "SKILLTYPE_SKILL" then
					s.texts[0].each_with_index do |_, q|
						make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["name#{q+1}"], "#{SOURCE_TXT}/#{s.texts[0][q]}"
						dscp = (make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["desc#{q+1}", "additional#{q+1}"], "#{SOURCE_TXT}/#{s.texts[1][q]}", 'skill')
						aFile.write("#{master[q+1]}@ #{s.stats[0]}@, #{dscp}\n") if @flag == 2
					end
				else
					make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["name"], "#{SOURCE_TXT}/#{s.texts[0][0]}"
					dscp = make_text "#{OUTPUT}/skills/#{s.stats[0]}", ["desc", "additional" ], "#{SOURCE_TXT}/#{s.texts[1][0]}", 'skill'
					aFile.write("PERK@ #{s.stats[0]}@, #{dscp}\n") if @flag == 2
				end
			end
			aFile.close if @flag == 2
		end
	end

	def unit(units); units.each { |u| make_text "#{OUTPUT}/creatures/#{u.id}", [ "name" ], "#{SOURCE_TXT}#{u.texts}" } if @flag != 0 end
	
	def ability(abilities)
		if @flag != 0 then
			abilities.each do |a|
				make_text "#{OUTPUT}/abilities/#{a.id}", [ "name" ], "#{SOURCE_TXT}#{a.name}"
				make_text "#{OUTPUT}/abilities/#{a.id}", [ "desc" ], "#{SOURCE_TXT}#{a.desc}", 'ability'
			end
		end
	end
	
	def spell(spells)
		if @flag != 0 then
			spells.each do |s|
				make_text "#{OUTPUT}/spells/#{s.id}", [ "name" ], "#{SOURCE_TXT}/#{s.texts[0]}" 
				make_text "#{OUTPUT}/spells/#{s.id}", [ "desc", "additional" ], "#{SOURCE_TXT}/#{s.texts[1]}", 'spell';
				s.texts[2].each do |p|
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('SpellBookPrediction.txt')
				    ( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred_expert" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('SpellBookPrediction_Expert')
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_TXT}#{p}", 'pred' ) if p.include?('HealHPReduce.txt')
					( make_text "#{OUTPUT}/spells/#{s.id}", [ "pred" ], "#{SOURCE_ADD}/none.txt", 'pred' ) if s.stats[5] == 'MAGIC_SCHOOL_ADVENTURE'
				end
			end
			make_text "#{OUTPUT}/spells", [ "universal_prediction" ], "#{SOURCE_TXT}/Text/Game/Spells/SpellBookPredictions/DirectDamage.txt", 'pred'
		end
	end
	
	def guild(guilds); guilds.each { |g| make_text "#{OUTPUT}/guilds/#{g}", [ "name" ], "#{SOURCE_TXT}/Text/Tooltips/SpellBook/#{GUILD_TEXT[:"#{g}"]}.txt" } if @flag != 0 end
	
	def guild_summoning(summoning);
		if @flag != 0 then
			summoning.each do |s|
				FileUtils.mkpath "#{OUTPUT}/spells/#{s.id}"
				file1 = File.open("#{OUTPUT}/spells/#{s.id}/name.txt", 'w');
				file1.write("#{s.texts[0]}")
				file1.close()
				file2 = File.open("#{OUTPUT}/spells/#{s.id}/desc.txt", 'w');
				file2.write("#{s.texts[1]}")
				file2.close()
			end
		end
	end
	
	def artifact(artifacts)
		aFile = File.new("artifact.csv", "w") if @flag == 2
		if @flag != 0 then
			artifacts.each do |a| 
				make_text "#{OUTPUT}/artifacts/#{a.id}", [ "name" ], "#{SOURCE_TXT}#{a.texts[0]}"
				dscp = make_text "#{OUTPUT}/artifacts/#{a.id}", [ "desc", "additional" ], "#{SOURCE_TXT}#{a.texts[1]}", 'artifact'
				aFile.write("#{a.id}@, #{dscp}\n") if @flag == 2
			end
		end
		aFile.close if @flag == 2
	end
	
	def micro_effect(micro);
		if @flag != 0 then
			micro.each do |m|
				make_text "#{OUTPUT}/micro_artifacts/#{m.id}", [ "name" ], "#{SOURCE_TXT}#{m.texts[0]}";
				make_text "#{OUTPUT}/micro_artifacts/#{m.id}", [ "suffix" ], "#{SOURCE_TXT}#{m.texts[1]}";
				make_text "#{OUTPUT}/micro_artifacts/#{m.id}", [ "desc" ], "#{SOURCE_TXT}#{m.texts[2]}";
			end
		end
	end
	
	def micro_prefix(prefix, id)
		if @flag != 0 then
			prefix.each_with_index { |p,i| make_text "#{OUTPUT}/micro_artifacts/#{id}", [ "f_#{i+1}" ], "#{SOURCE_TXT}#{p}"; }
		end
	end
	
	def micro_shell(shell)
		if @flag != 0 then
			shell.each do |s|
				make_text "#{OUTPUT}/micro_artifacts/#{s.id}", [ "name" ], "#{SOURCE_TXT}#{s.texts[0]}";
				if s.texts[1] == "" then
					make_text "#{OUTPUT}/micro_artifacts/#{s.id}", [ "desc" ], "#{SOURCE_ADD}/none.txt";
				else
					make_text "#{OUTPUT}/micro_artifacts/#{s.id}", [ "desc" ], "#{SOURCE_TXT}#{s.texts[1]}";
				end
			end
		end
	end
end