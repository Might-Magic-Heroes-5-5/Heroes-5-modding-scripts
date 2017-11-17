require 'fileutils'
require 'sqlite3'
require 'code/readskills'
require 'nokogiri'


def check_dir file, origin; return file.start_with?("/")? file : ((origin.split('MMH55-Index')[1].split('/'))[0...-1].join('/') + '/' + file ) end

def sort_line line, first, second
	if (line.chop[/#{first}(.*?)#{second}/m, 1]).nil? == false then
		return (line)[/#{first}(.*?)#{second}/m, 1];
	end
end

def make_text dirr, target, source, mode=0
	script = $0
	FileUtils.mkpath dirr
	input = File.open(source)
	data_to_copy = []
	data_to_copy << input.read()
	input.close()
	case mode
	when 1 then
		data_to_copy[0].gsub!(/<br>/, "\n")
		data_to_copy[0].gsub!(/<body_bright>/, '')
		data_to_copy = data_to_copy[0].split('<color_default>').each { |m| m.gsub!(/<color_default>/, '') }
	when 2 then
		data_to_copy[0].gsub!(/<br>/, "\n")
		data_to_copy[0].gsub!(/<color=.*?>/, '')
	end 
	data_to_copy.each_with_index do |t, i|
		@output = File.open("#{dirr + '/' + target[i]}.txt", 'w');
		@output.write("#{t}")
		@output.close()
	end
end

class Klass

	def initialize( id, at, df, sp, kn, fac, txt_name )
		@id,@at,@df,@sp,@kn,@faction = id, at, df, sp, kn, fac, txt_name ##Get klas vars
		@txt_name = txt_name											 ##Get text vars
	end

	def get_skills(source, filter)
		@secondary_skills, @secondary_chance = [], []
		source.xpath(filter).each_with_index do |s, i|		
			(i.even? ? @secondary_skills : @secondary_chance) << s.text
		end
	end
	
	def stats; return @id,@at,@df,@sp,@kn,@faction end
	def skills; return @secondary_skills, @secondary_chance end
	def texts; return @txt_name end
end

class Hero
	
	def initialize(id,at,df,sp,kn,skill,mastery,perk,spell,clas,faction,txt_name,txt_s_name)
		@id,@at,@df,@sp,@kn,@skill,@mastery,@perk,@spell,@clas,@faction = id,at,df,sp,kn,skill,mastery,perk,spell,clas,faction ###Get hero vars
		@txt_name,@txt_s_name = txt_name,txt_s_name 					 					   					 			   ###Get text vars
	end
	
	def stats; return @id, @at, @df, @sp, @kn, @skill ,@mastery ,@perk, @spell, @clas, @faction end
	def texts; return @txt_name,@txt_s_name end	
end

class Perk
	
	def initialize(id,type,skill_tree,txt_name,txt_s_name)
		@id,@type,@skill_tree = id,type,skill_tree	 ###Get perk vars
		@txt_name,@txt_desc = txt_name,txt_s_name 	 ###Get text vars
	end

	def stats; return @id,@type,@skill_tree end
	def texts; return @txt_name,@txt_desc end
end

class Creature
	
	def initialize(id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability, txt_name)
		@id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability = id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability  ###Get creature vars
		@txt_name = txt_name 				 																																																		###Get text vars
	end

	def stats; return @id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability end
	def texts; return @txt_name end
end

class Spell
	
	def initialize(id, spell_effect, spell_increase, mana, tier, guild, resource_cost, txt_name, txt_desc, txt_pred)
		@id, @spell_effect, @spell_increase, @mana, @tier, @guild, @resource_cost = id, spell_effect, spell_increase, mana, tier, guild, resource_cost  ###Get spell vars
		@txt_name, @txt_desc, @txt_pred = txt_name, txt_desc, txt_pred		 																			###Get text vars
	end

	def stats; return @id, @spell_effect, @spell_increase, @mana, @tier, @guild, @resource_cost end
	def texts; return @txt_name, @txt_desc, @txt_pred end
end

class Artifact
	
	def initialize(id, slot, cost, type, at, df, sp, kn, moral, luck, set, txt_name, txt_desc)
		@id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set = id, slot, cost, type, at, df, sp, kn, moral, luck, set  ###Get artifact vars
		@txt_name, @txt_desc = txt_name, txt_desc			 																		###Get text vars
	end

	def stats; return @id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set end
	def texts; return @txt_name, @txt_desc end
end

Shoes.app do
	
	source_defaultstats = 'Rc10/data/MMH55-Index/GameMechanics/RPGStats/DefaultStats.xdb'
	DB_NAME = 'skillwheel.db'
	db = SQLite3::Database.new 'skillwheel.db'

	############ create table with faction list and native spells
	soruce_town = 'Rc10/data/MMH55-Index/GameMechanics/RefTables/TownTypesInfo.xdb'
	doc = File.open(soruce_town) { |f| Nokogiri::XML(f) }
	db.execute "create table factions ( name string );"
	
	texts = doc.xpath("//obj/textType/@href")
	doc.xpath("//ID").each_with_index do |n,i|
		if texts[i].text != '' then
			db.execute("INSERT INTO factions ( name ) VALUES ( '#{n.text}' )") 
			make_text "en/factions/#{n.text}", ["name"], "Rc10/data/MMH55-Texts-EN/#{texts[i].text}"
		end
	end
#=end
	############ create table with all in-game heroes and their starting primary and secondary stats
	source_hero = 'RC10/data/MMH55-Index/MapObjects'
	db.execute "create table heroes ( id string, atk int, def int, spp int, knw int, skills string, masteries string, perks string, spells string, classes string, faction string );"
	heroes, klas_2_faction = [], {}
	
	Dir.glob("#{source_hero}/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
		doc = File.open(fn) { |f| Nokogiri::XML(f) }
		id = doc.xpath("//InternalName").text
		(doc.xpath("//ScenarioHero").text == 'true' or id == '') ? next : nil
		town = doc.xpath("//TownType").text
		klas = doc.xpath("//Class").text
		starting_skills, starting_masteries, starting_perks, starting_spells = [],[],[], []
		doc.xpath("//PrimarySkill | //Editable/skills/Item").each do |n|
			starting_skills << n.xpath("SkillID").text
			starting_masteries << n.xpath("Mastery").text
		end		
		doc.xpath("//Editable/perkIDs/Item").each { |n|	starting_perks << n.text }
		doc.xpath("//Editable/spellIDs/Item").each { |n| starting_spells << n.text }
		heroes << Hero.new(id,
			doc.xpath("//Editable/Offence").text,
			doc.xpath("//Editable/Defence").text,
			doc.xpath("//Editable/Spellpower").text,
			doc.xpath("//Editable/Knowledge").text,
			starting_skills.join(','),
			starting_masteries.join(','),
			starting_perks.join(','),
			starting_spells.join(','),
			klas,
			town,
			(check_dir doc.xpath("//NameFileRef/@href").text, fn),
			(check_dir doc.xpath("//SpecializationNameFileRef/@href").text, fn))
		doc.xpath("//NameFileRef/@href").text == '' ? nil : (db.execute "insert into heroes values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )", heroes.last.stats)
		klas_2_faction[:"#{town}"].nil? ? klas_2_faction[:"#{town}"] = [] : nil
		klas_2_faction[:"#{town}"].include?(klas) ? nil : klas_2_faction[:"#{town}"] += [klas]
		make_text "en/heroes/#{id}", [ "name" ], "Rc10/data/MMH55-Texts-EN#{heroes.last.texts[0]}"
		make_text "en/heroes/#{id}", ["spec", "additional" ], "Rc10/data/MMH55-Texts-EN#{heroes.last.texts[1]}", 1
	end


	############ create table with classes list, primary stats chances and secondary skills; match classes to factions
	source_class = 'Rc10/data/MMH55-Index/GameMechanics/RefTables/HeroClass.xdb'
	db.execute "create table classes ( id string, atk_c int, def_c int, spp_c int, knw_c int, faction string );"
	doc = File.open(source_class) { |f| Nokogiri::XML(f) }
	classes = []
	
	doc.xpath("/Table_HeroClassDesc_HeroClass/objects/Item" ).each do |n|
		id = n.xpath("ID").text
		classes << Klass.new(id,
			n.xpath("obj/AttributeProbs/OffenceProb").text,
			n.xpath("obj/AttributeProbs/DefenceProb").text,
			n.xpath("obj/AttributeProbs/SpellpowerProb").text,
			n.xpath("obj/AttributeProbs/KnowledgeProb").text,
			(klas_2_faction.select do |key, value| 
				value.include?("#{id}")
			end.keys.first.to_s),
			n.xpath("obj/NameFileRef/@href").text)
			
		db.execute "insert into classes values ( ?, ?, ?, ?, ?, ? )", classes.last.stats
		classes.last.get_skills n, "obj/SkillsProbs/Item/SkillID | obj/SkillsProbs/Item/Prob"
		db.execute "create table #{id} (skill string, chance int, type string, app_order int);"
		skills_name, skills_chance = classes.last.skills
		skills_name.each_with_index do |_,i|
			db.execute "insert into #{id} values ( ?, ?, ?, ? );", skills_name[i], skills_chance[i], 'SKILLTYPE_SKILL', i
		end
		make_text "en/classes/#{id}", ["name"], "Rc10/data/MMH55-Texts-EN/GameMechanics/RefTables/#{classes.last.texts}"
	end

	############ create perk-to-skill match table, includes ordering required for the skillwheel
	source_perks = 'Rc10\data\MMH55-Index\GameMechanics\RefTables\Skills.xdb'
	db.execute "create table skills (name string, type string, tree string, app_order int);"
	doc = File.open(source_perks) { |f| Nokogiri::XML(f) }
	perks = []

	doc.xpath("//objects/Item").each_with_index do |n, i|
		txt_name, txt_desc = [], []
		(n.xpath("obj/NameFileRef/Item/@href").each { |s| txt_name << s.text })
		(n.xpath("obj/DescriptionFileRef/Item/@href").each { |d| txt_desc << d.text })
		id = n.xpath("ID").text
		type = n.xpath("obj/SkillType").text
		base = n.xpath("obj/BasicSkillID").text
		perks << Perk.new( id,
			type,
			base,
			txt_name,
			txt_desc)
		
		req_item = n.xpath("obj/SkillPrerequisites/Item")
		
		
		case type
		when "SKILLTYPE_SKILL" then
			db.execute "insert into skills values ( ?, ?, ?, ? );", perks.last.stats, i
			txt_name.each_with_index do |_, q|
				make_text "en/skills/#{id}", ["name#{q+1}"], "Rc10/data/MMH55-Texts-EN/#{txt_name[q]}"
				make_text "en/skills/#{id}", ["desc#{q+1}"], "Rc10/data/MMH55-Texts-EN/#{txt_desc[q]}"
			end
		when "SKILLTYPE_STANDART_PERK" then
			db.execute "insert into skills values ( ?, ?, ?, ? );", perks.last.stats, i
			make_text "en/skills/#{id}", ["name"], "Rc10/data/MMH55-Texts-EN/#{txt_name[0]}"
			make_text "en/skills/#{id}", ["desc"], "Rc10/data/MMH55-Texts-EN/#{txt_desc[0]}"
		else
			req_item.each do |t|
				req_skills = []
				klas = t.xpath("Class").text
				t.xpath("dependenciesIDs/Item").each { |p| req_skills << p.text }
				if (db.execute "select skill from #{klas} where type='SKILLTYPE_SKILL'").join(",").include?(base) then
					unless req_skills.empty? then
						db.execute "insert into #{klas} values ( ?, ?, ?, ?);",id, req_skills.join(','), type, '99'
						make_text "en/skills/#{id}", ["name"], "Rc10/data/MMH55-Texts-EN/#{txt_name[0]}"
						make_text "en/skills/#{id}", ["desc"], "Rc10/data/MMH55-Texts-EN/#{txt_desc[0]}"
					end
				end
			end
		end
	end

	############ create creature table 
	source_creatures = 'RC10/data/MMH55-Index/GameMechanics/creature/creatures'
	db.execute "create table creatures ( id string, at int, df int, shots int, min_d int, max_d int, spd int, init int, fly int, hp int, spells string, spell_mastery string, mana int, tier int, faction string, growth int, ability string );"
	creatures = []
	
	Dir.glob("#{source_creatures}/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
		doc = File.open(fn) { |f| Nokogiri::XML(f) }
		spells, masteries, abilities = [], [], []
		id = fn.split("/")[-1].split('.')[0]
		(doc.xpath("//AttackSkill").text == '' or id == 'None') ? next : nil
		
		header = fn.split("GameMechanics")[0]
		visuals = File.open("#{header.chop}#{doc.xpath("//Visual/@href").text.split('#xpointer')[0]}") { |f| Nokogiri::XML(f) }
		doc.xpath("//KnownSpells/Item/Spell | //KnownSpells/Item/Mastery").each_with_index { |s, i|	( i.even? ? spells : masteries ) << s.text }
		doc.xpath("//Abilities").each { |a| abilities << a.text }
		creatures << Creature.new(id,
			doc.xpath("//AttackSkill").text,
			doc.xpath("//DefenceSkill").text,
			doc.xpath("//Shots").text,
			doc.xpath("//MinDamage").text,
			doc.xpath("//MaxDamage").text,
			doc.xpath("//Speed").text,
			doc.xpath("//Initiative").text,
			doc.xpath("//Flying").text,
			doc.xpath("//Health").text,
			spells.join(','),
			masteries.join(','),
			doc.xpath("//SpellPoints").text,
			doc.xpath("//CreatureTier").text,
			doc.xpath("//CreatureTown").text,
			doc.xpath("//WeeklyGrowth").text,
			abilities,
			visuals.xpath("/CreatureVisual/CreatureNameFileRef/@href")
		)
		make_text "en/creatures/#{id}", [ "name" ], "Rc10/data/MMH55-Texts-EN#{creatures.last.texts}";
		db.execute "insert into creatures values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );", creatures.last.stats
	end

	############ create text files for creature abilities ##########
	source_abilities = 'Rc10\data\MMH55-Index\GameMechanics\RefTables\CombatAbilities.xdb'
	doc = File.open(source_abilities) { |f| Nokogiri::XML(f) }
	doc.xpath("//objects/Item").each do |n|
		id = n.xpath("ID").text
		(txt_name = n.xpath("obj/NameFileRef/@href").text) == '' ? next : nil
		txt_desc = n.xpath("obj/DescriptionFileRef/@href").text
		make_text "en/abilities/#{id}", [ "name" ], "Rc10/data/MMH55-Texts-EN#{txt_name}"
		make_text "en/abilities/#{id}", [ "desc" ], "Rc10/data/MMH55-Texts-EN#{txt_desc}"
	end

	############ create table with all spells and guilds
	#source_spells = 'Rc10/data/MMH55-Index/GameMechanics/Spell'
	source_spells = 'Rc10/data/MMH55-Index/GameMechanics/RefTables/UndividedSpells.xdb'
    db.execute "create table spells ( id string, spell_effect string, spell_increase string, mana int, tier int, guild string, resource_cost string );"
	db.execute "create table guilds ( id string, app_order int );"
	source = File.open(source_spells)  { |f| Nokogiri::XML(f) }
	spell_dirs, guilds, spells = ["Combat_Spells", "Hero_Abilities/Barbarian", "Adventure_Spells" ], [], []
	source.xpath("/Table_Spell_SpellID/objects/Item").each do |sp|
		id = sp.xpath("ID").text
		dr = sp.xpath("Obj/@href").text
		dr.nil? ? next : nil
		dr_source = "Rc10/data/MMH55-Index#{dr.split('#xpointer')[0]}"
		if spell_dirs.any? { |x| dr.include?(x) } then
			doc = File.open(dr_source) { |f| Nokogiri::XML(f) }
			( ['SpellVisual','Mass_','Empowered'].any? { |word| dr.include?(word) } or doc.xpath("//NameFileRef/@href").text == '' ) ? next : nil
			base, power, resource, predict = [], [], [], []
			school = doc.xpath("//MagicSchool").text
			doc.xpath("//Base | //PerPower").each_with_index { |x, i| ( i.even? ? base : power ) << x.text }
			[ "Wood", "Ore", "Mercury", "Crystal", "Sulfur", "Gem" ].each do |r|
				doc.css("//#{r}").each { |t| t.text > '0' ? resource << "#{r} #{t.text}" : nil }	
			end
			doc.xpath("//SpellBookPredictions/Item/@href").each { |p| predict << (check_dir p.text,dr_source) }
			spells << Spell.new(id,
				base.join(','),
				power.join(','),
				doc.xpath("//TrainedCost").text,
				doc.xpath("//Level").text,
				school,
				resource.join(','),
				(check_dir doc.xpath("//NameFileRef/@href").text, dr_source),
				(check_dir doc.xpath("//LongDescriptionFileRef/@href").text, dr_source),
				predict )
			db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", spells.last.stats
			(guilds.include?(school) or school == '') ? nil : (guilds << school)
			txt = spells.last.texts
			make_text "en/spells/#{id}", [ "name" ], "Rc10/data/MMH55-Texts-EN/#{txt[0]}" 
			make_text "en/spells/#{id}", [ "desc", "additional" ], "Rc10/data/MMH55-Texts-EN/#{txt[1]}", 1;
			txt[2].each do |p|
				p = check_dir p, dr_source
				p.include?('SpellBookPrediction.txt') ? ( make_text "en/spells/#{id}", [ "pred" ], "Rc10/data/MMH55-Texts-EN#{p}", 1 ) : nil
				p.include?('SpellBookPrediction_Expert') ? ( make_text "en/spells/#{id}", [ "pred_expert" ], "Rc10/data/MMH55-Texts-EN#{p}", 1 ) : nil
				p.include?('HealHPReduce.txt') ? ( make_text "en/spells/#{id}", [ "pred" ], "Rc10/data/MMH55-Texts-EN#{p}", 1 ) : nil
			end
		end		
	end
	txt_guilds =  { MAGIC_SCHOOL_DARK: 'SchoolDark',
					MAGIC_SCHOOL_SUMMONING: 'SchoolSummoning',
					MAGIC_SCHOOL_DESTRUCTIVE: 'SchoolDestructive',
					MAGIC_SCHOOL_SPECIAL: 'SchoolSpecial',
					MAGIC_SCHOOL_LIGHT: 'SchoolLight', 
					MAGIC_SCHOOL_RUNIC: 'SchoolSpecial', 
					MAGIC_SCHOOL_WARCRIES: 'Warcries', 
					MAGIC_SCHOOL_ADVENTURE: 'AdventureSpells' }
					
	guilds.each_with_index do |g, i|
		db.execute "insert into guilds values (?, ?)", g, i
		(make_text "en/guilds/#{g}", [ "name" ], "Rc10/data/MMH55-Texts-EN/Text/Tooltips/SpellBook/#{txt_guilds[:"#{g}"]}.txt")
	end

	############ make a list of all sets
	source_sets = 'RC10\data\MMH55-Index\scripts\advmap-startup.lua'
	flag, artif_set, artif = 0, {}, {}
	
	File.read(source_sets).each_line do |line|
		case flag
		when 0 then line.include?('	ARTIFACT_SET_') ? ( artif_set[:"#{sort_line line, 'ARTIFACT_SET_', ' ='}"] = line.split(" = ")[1].to_i ) : nil
					line.include?('Artifact type IDs') ? flag = 1 : nil
		when 1 then line.include?('	ARTIFACT_') ? ( artif[:"#{sort_line line, 'ARTIFACT_', ' ='}"] = line.split(" = ")[1].to_i ) : nil				
		end
	end
	
	############ make matches between artifacts and sets	
	source_matches = 'RC10\data\MMH55-Index\scripts\H55-Core.lua'
	@sets, @curr_set, flag = {}, "", 0
	
	File.read(source_matches).each_line do |line|
		case flag
		when 0 then if line.include?('SetCount(hero)') && line.include?('function') then
						@curr_set = sort_line line, 'H55_Get', 'SetCount[(]hero[)]'; 
						@sets[:"#{@curr_set}"] = []
						flag, i = 1, 0
					end
		when 1 then line.include?('HasArtefact(hero,') ? ( @sets[:"#{@curr_set}"] += [(sort_line line, 'HasArtefact[(]hero[,]', '[,]')] ) : nil
					line.include?('return') ? flag = 0 : nil
		end
	end

	############ create table with all artifacts and their set matches
	source_artifacts = 'RC10\data\MMH55-Index\GameMechanics\RefTables\Artifacts.xdb'
	doc = File.open(source_artifacts) { |f| Nokogiri::XML(f) }
	db.execute "create table artifacts ( id string, slot string, cost int, type string, at int, df int, sp int, kn int, morale int, luck int, set_name string );"
	is_set, artifacts = '', []
	
	doc.xpath("//objects/Item").each do |n|
		( id = n.xpath("ID").text ) == ('ARTIFACT_NONE') ? next : nil
		id.slice! 'ARTIFACT_'
		@sets.each { |key, array| array.include?("#{artif[:"#{id}"]}") ? (  is_set = "#{key}".upcase; break; ) : is_set = 'NONE' }

		artifacts << Artifact.new(id,
			n.xpath("obj/Slot").text,
			n.xpath("obj/CostOfGold").text,
			n.xpath("obj/Type").text,
			n.xpath("obj/HeroStatsModif/Attack").text,
			n.xpath("obj/HeroStatsModif/Defence").text,
			n.xpath("obj/HeroStatsModif/SpellPower").text,
			n.xpath("obj/HeroStatsModif/Knowledge").text,
			n.xpath("obj/HeroStatsModif/Morale").text,
			n.xpath("obj/HeroStatsModif/Luck").text,
			is_set,
			n.xpath("obj/NameFileRef/@href").text,
			n.xpath("obj/DescriptionFileRef/@href").text)
		db.execute "insert into artifacts values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );", artifacts.last.stats
		make_text "en/artifacts/#{id}", [ "name" ], "Rc10/data/MMH55-Texts-EN#{artifacts.last.texts[0]}";
		make_text "en/artifacts/#{id}", [ "desc" ], "Rc10/data/MMH55-Texts-EN#{artifacts.last.texts[1]}", 2;
	end

	######## SKILLWHEEL MANUALLY CREATED TABLES START HERE #############################	

	############ create table with all artifact filters
	db.execute "create table artifact_filter ( name string, filter string );"
	
	Dir.glob("design/artifacts/filters/**/*").reject{ |rj| File.directory?(rj) }.each do |fl|
		filter_name = fl.split("/")[-1].split('.')[0]
		filter = (read_skills fl)
		db.execute "insert into artifact_filter values ( ?, ?)", filter.join(","), filter_name
	end	

	para "Success"
end

=begin
Shoes.app do
	source_defaultstats = 'Rc10/data/MMH55-Index/GameMechanics/RPGStats/DefaultStats.xdb'
	doc = File.open(source_defaultstats) { |f| Nokogiri::XML(f) }
	doc.xpath("//BladeBarrier//Base").each do |n|
		debug(n.text)
	end
=end