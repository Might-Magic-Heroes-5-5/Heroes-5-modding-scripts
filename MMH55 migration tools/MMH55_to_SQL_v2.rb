require 'fileutils'
require 'sqlite3'
require 'code/readskills'
require 'code/methods'
require 'nokogiri'
require 'code/statics'

Shoes.app do
	
	debug(DB_FLAG)
	dfstats = File.open("#{SOURCE_DFSTATS}") { |f| Nokogiri::XML(f) }
	db = Manage_db.new("#{DB_NAME}", DB_FLAG)
	create_text = Manage_texts.new(nil, TXT_FLAG)

	############ create table with faction list
	towns = []
	town_doc = File.open(SOURCE_TOWNS) { |f| Nokogiri::XML(f) }
	town_txt_f = town_doc.xpath("//obj/textType/@href")
	town_doc.xpath("//ID").each_with_index do |n,i|
		next if town_txt_f[i].text == ''
		town_id = n.text
		town_txt = File.read("#{Dir.pwd}/#{SOURCE_TXT}#{town_txt_f[i].text}") 
		towns << Town.new(town_id, town_txt)
	end
	db.town(towns)
	create_text.town(towns)

	############ create skills table
	skills = []	
	skill_doc = File.open(SOURCE_SKILLS) { |f| Nokogiri::XML(f) }
	skill_doc.xpath("//objects/Item").each_with_index do |n, i|
		skill_name, skill_desc = [], []
		(n.xpath("obj/NameFileRef/Item/@href").each { |s| skill_name << s.text })
		(n.xpath("obj/DescriptionFileRef/Item/@href").each { |d| skill_desc << d.text })
		skill_id = n.xpath("ID").text
		skill_type = n.xpath("obj/SkillType").text
		skill_base = n.xpath("obj/BasicSkillID").text
		skill_req = n.xpath("obj/SkillPrerequisites/Item")
		skills << Skill.new( skill_id,
			skill_type,
			skill_base,
			skill_req,
			skill_name,
			skill_desc )
	end	

	db.skill(skills)
	create_text.skill(skills)

	############ create table with all in-game heroes and their starting primary and secondary stats
	heroes, output_table, class_to_town = [], [], {}
	q = 0
	Dir.glob("#{SOURCE_HEROES}/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
		doc = File.open(fn) { |f| Nokogiri::XML(f) }
		hero_id = doc.xpath("//InternalName").text
		hero_name = (check_dir doc.xpath("//NameFileRef/@href").text, fn)
		hero_campaign = doc.xpath("//ScenarioHero").text
		next if hero_id == '' or hero_campaign == 'true' or hero_name == ''
		hero_attack = doc.xpath("//Editable/Offence").text
		hero_defense = doc.xpath("//Editable/Defence").text
		hero_spellpower = doc.xpath("//Editable/Spellpower").text
		hero_knowledge = doc.xpath("//Editable/Knowledge").text
		hero_skills, hero_masteries, hero_perks, hero_spells = [], [], [], []
		doc.xpath("//PrimarySkill | //Editable/skills/Item").each do |n|
			hero_skills << n.xpath("SkillID").text
			hero_masteries << n.xpath("Mastery").text
		end
		doc.xpath("//Editable/perkIDs/Item").each { |n|	hero_perks << n.text }
		doc.xpath("//Editable/spellIDs/Item").each { |n| hero_spells << n.text }
		hero_class = doc.xpath("//Class").text
		hero_town = doc.xpath("//TownType").text
		hero_spec = (check_dir doc.xpath("//SpecializationNameFileRef/@href").text, fn)
		heroes << Hero.new(hero_id,
			hero_attack,
			hero_defense,
			hero_spellpower,
			hero_knowledge,
			hero_skills.join(','),
			hero_masteries.join(','),
			hero_perks.join(','),
			hero_spells.join(','),
			hero_class,
			hero_town,
			hero_name,
			hero_spec,
			fn)
		
		towns.each do |t|
			next if t.town_id != hero_town
			class_to_town[:"#{hero_class}"] = t.town_id
		end

		### creating a test file for Magno
		#output_table << [id, hero_name]
		#File.open('test.txt', 'w' ) do |f|
		#	f.puts "H55_HeroNames = {"
		#	output_table.each do |a|
		#		f.puts " [\"#{a[0]}\"]=\"#{a[1]}\","
		#	end
		#	f.puts "};"
		#end
	end	
	db.hero(heroes)
	create_text.hero(heroes)
	create_AdvMapSharedGroup(heroes)
	############ create table with classes list, primary stats chances and secondary skills
	classes = []
	class_doc = File.open(SOURCE_CLASSES) { |f| Nokogiri::XML(f) }
	class_doc.xpath("/Table_HeroClassDesc_HeroClass/objects/Item" ).each do |n|
		class_id = n.xpath("ID").text
		next if class_id == 'HERO_CLASS_NONE'
		class_ak_pb = n.xpath("obj/AttributeProbs/OffenceProb").text
		class_df_pb = n.xpath("obj/AttributeProbs/DefenceProb").text
		class_sp_pb = n.xpath("obj/AttributeProbs/SpellpowerProb").text
		class_kn_pb = n.xpath("obj/AttributeProbs/KnowledgeProb").text
		class_name = n.xpath("obj/NameFileRef/@href").text
		classes << Klass.new(class_id, class_ak_pb, class_df_pb, class_sp_pb, class_kn_pb, class_to_town[:"#{class_id}"], class_name )
		classes.last.get_skills n, "obj/SkillsProbs/Item/SkillID | obj/SkillsProbs/Item/Prob"	
	end
	
	db.klass(classes, skills)
	create_text.klass(classes)
	create_AdvMapObjectLink(classes)

	############ create creature table 
	units = []
	Dir.glob("#{SOURCE_CREATURES}/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
		unit_doc = File.open(fn) { |f| Nokogiri::XML(f) }
		spells, masteries, abilities = [], [], []
		unit_id = fn.split("/")[-1].split('.')[0]
		next if unit_doc.xpath("//AttackSkill").text == '' or unit_id == 'None' or unit_id == 'Black_Knight'
		header = fn.split("GameMechanics")[0]
		visuals = File.open("#{header.chop}#{unit_doc.xpath("//Visual/@href").text.split('#xpointer')[0]}") { |f| Nokogiri::XML(f) }
		unit_doc.xpath("//KnownSpells/Item/Spell | //KnownSpells/Item/Mastery").each_with_index { |s, i| ( i.even? ? spells : masteries ) << s.text }
		unit_doc.xpath("//CombatSize").text == '2' ? ( abilities << "ABILITY_LARGE_CREATURE" ) : nil
		unit_doc.xpath("//Range").text != '0' ? ( abilities << "ABILITY_SHOOTER" ) : nil
		unit_doc.xpath("//Abilities/Item").each { |a| abilities << a.text }
		units << Creature.new( unit_id,
			unit_doc.xpath("//AttackSkill").text,
			unit_doc.xpath("//DefenceSkill").text,
			unit_doc.xpath("//Shots").text,
			unit_doc.xpath("//MinDamage").text,
			unit_doc.xpath("//MaxDamage").text,
			unit_doc.xpath("//Speed").text,
			unit_doc.xpath("//Initiative").text,
			unit_doc.xpath("//Flying").text,
			unit_doc.xpath("//Health").text,
			spells.join(','),
			masteries.join(','),
			unit_doc.xpath("//SpellPoints").text,
			unit_doc.xpath("//CreatureTier").text,
			unit_doc.xpath("//CreatureTown").text,
			unit_doc.xpath("//WeeklyGrowth").text,
			abilities.join(','),
			unit_doc.xpath("//Cost/Wood").text,
			unit_doc.xpath("//Cost/Ore").text,
			unit_doc.xpath("//Cost/Mercury").text,
			unit_doc.xpath("//Cost/Crystal").text,
			unit_doc.xpath("//Cost/Sulfur").text,
			unit_doc.xpath("//Cost/Gem").text,
			unit_doc.xpath("//Cost/Gold").text,
			visuals.xpath("/CreatureVisual/CreatureNameFileRef/@href") )
	end
	db.unit(units)
	create_text.unit(units)

	############ create text files for creature abilities ##########
	ability_doc = File.open(SOURCE_ABILITIES) { |f| Nokogiri::XML(f) }
	abilities = []
	ability_doc.xpath("//objects/Item").each do |n|
		ability_id = n.xpath("ID").text
		(ability_name = n.xpath("obj/NameFileRef/@href").text) == '' ? next : nil
		ability_desc = n.xpath("obj/DescriptionFileRef/@href").text
		abilities << Ability.new(ability_id, ability_name, ability_desc)
	end
	create_text.ability(abilities)

	############ create table with all spells 
	spell_src = File.open(SOURCE_SPELLS)  { |f| Nokogiri::XML(f) }
	spell_dirs = ["Combat_Spells", "Hero_Abilities/Barbarian", "Adventure_Spells" ]
	spells, spells_spec = [], []
	spell_src.xpath("/Table_Spell_SpellID/objects/Item").each do |sp|
		spell_id = sp.xpath("ID").text
		spell_xdb = "#{sp.xpath("Obj/@href").text}"
		next if %w(SpellVisual Mass_ Empowered).any? { |word| spell_xdb.include?(word) } or spell_xdb.empty?
		next if %w(ABILITY).any? { |word| spell_id.include?(word) } or spell_id.empty?
		spell_xdb = "#{SOURCE_IDX}#{spell_xdb.split("#xpointer")[0]}"
		base, power, resource, predict, b_effect, p_effect = [], [], [], [], [], []
		doc = File.open(spell_xdb) { |f| Nokogiri::XML(f) }
		school_id = doc.xpath("//MagicSchool").text
		next if doc.xpath("//NameFileRef/@href").text == '' or school_id == 'MAGIC_SCHOOL_SPECIAL'
		doc.xpath("//Base | //PerPower").each_with_index { |x, i| ( i.even? ? base : power ) << x.text }
		case spell_id
		when "SPELL_BLADE_BARRIER" then
			dfstats.xpath("/RPGStats/combat/Spells/BladeBarrier/Health/Item").each_with_index do |d, i|
				b_effect << d.xpath("Base").text
				p_effect << d.xpath("PerPower").text
			end
			spells_spec << [ spell_id, b_effect.join(','), p_effect.join(',') ]
		when "SPELL_ARCANE_CRYSTAL" then
			b_effect << dfstats.xpath("/RPGStats/combat/Spells/ArcaneCrystal/Health").text
			p_effect << dfstats.xpath("/RPGStats/combat/Spells/ArcaneCrystal/Defence").text
			spells_spec << [ spell_id, b_effect.join(','), p_effect.join(',') ]
		when "SPELL_DEEP_FREEZE" then
			dfstats.xpath("/RPGStats/combat/Spells/DeepFreeze/DamageMultiplier/Item").each_with_index do |d, i|
				b_effect << d.xpath("Base").text
				p_effect << d.xpath("PerPower").text
			end
			spells_spec << [ spell_id, b_effect.join(','), p_effect.join(',') ]
		when "SPELL_SUMMON_HIVE" then
			
			dfstats.xpath("/RPGStats/combat/Spells/SummonHive/Initiative/Item | /RPGStats/combat/Spells/SummonHive/Health/Item").each_with_index do |d, i|
				b_effect << d.xpath("Base").text
				p_effect << d.xpath("PerPower").text
			end
			b_effect << dfstats.xpath("/RPGStats/combat/Spells/SummonHive/DefenseBase").text
			p_effect << dfstats.xpath("/RPGStats/combat/Spells/SummonHive/DefensePerCasterLevel").text
			spells_spec << [ spell_id, b_effect.join(','), p_effect.join(',') ]
		when "SPELL_WARCRY_WORD_OF_THE_CHIEF" then
			stun = calc dfstats.xpath("/RPGStats/combat/Spells/Warcries/WordOfTheChief_ATBBonusBase").text
			stun_per = calc dfstats.xpath("/RPGStats/combat/Spells/Warcries/WordOfTheChief_ATBBonusPerCasterLevel").text
			bonus_rp = dfstats.xpath("/RPGStats/combat/Spells/Warcries/WordOfTheChief_RPBonus").text.to_i
			base = Array.new(4, stun)
			power = Array.new(4, stun_per)
			base.fill(bonus_rp, base.size, 4)
			power.fill(0, power.size, 4)
		when "SPELL_CURSE", "SPELL_SLOW", "SPELL_FORGETFULNESS", "SPELL_BERSERK", "SPELL_HYPNOTIZE", "SPELL_BLESS", "SPELL_HASTE", "SPELL_DISPEL", "SPELL_DEFLECT_ARROWS", "SPELL_CELESTIAL_SHIELD" then
			base[0..3] = base[0..3].map { |x| calc(x) }
			power[0..3] = power[0..3].map { |x| calc(x) }
		when "SPELL_ANIMATE_DEAD", "SPELL_RESURRECT" then
			base[4..7] = base[4..7].map { |x| calc(x) }
			power[4..7] = power[4..7].map { |x| calc(x) }
		end
		
		RESOURCES.each { |r| doc.css("//#{r}").each { |t| resource << "#{t.text}" } }
		doc.xpath("//SpellBookPredictions/Item/@href").each { |p| predict << (check_dir p.text,spell_xdb) }
		spells << Spell.new(spell_id,
			base.join(','),
			power.join(','),
			doc.xpath("//TrainedCost").text,
			doc.xpath("//Level").text,
			school_id,
			resource.join(','),
			(check_dir doc.xpath("//NameFileRef/@href").text, spell_xdb),
			(check_dir doc.xpath("//LongDescriptionFileRef/@href").text, spell_xdb),
			predict )	
	end
	db.spell(spells)
	create_text.spell(spells)
	db.spell_spec(spells_spec)

	############ Create magic guild table
	guilds = ["MAGIC_SCHOOL_DESTRUCTIVE", "MAGIC_SCHOOL_DARK", "MAGIC_SCHOOL_LIGHT", "MAGIC_SCHOOL_SUMMONING", "MAGIC_SCHOOL_ADVENTURE", "MAGIC_SCHOOL_RUNIC", "MAGIC_SCHOOL_WARCRIES", "MAGIC_SCHOOL_SPECIAL" ]
	flag, current_set = 0, ""
	db.guild(guilds)
	create_text.guild(guilds)

	############ Create hash of creatures number to text ID
	num_2_creature = {}
	File.read(SOURCE_COMMON).each_line do |line|
		case flag
		when 0 then flag=1 if line.include?('	-- Creatures IDs')
		when 1 then ( num_2_creature[:"#{line.split(' = ')[1].to_i.to_s}"] = (sort_line line, 'CREATURE_', ' = ') )if line.include?('CREATURE_')
					break if line.include?('War machines')
		end
	end

	############ add shatter summoning to spell database, gather artifact sets
	town_2_elmnt, num_2_faction, dblood_const, artifact_sets,flag = {}, {}, {}, {}, 0
	File.read(SOURCE_55CORE).each_line do |line|
		case flag
		when 0 then flag=1 if line.include?('function H55_GetTownRaceID') # flag 0-1 -  Match Tote Town ID with MMH55 town id; start at 1882 line as of RC14B4
		when 1 then if line.include?('townid') and line.include?('num') then
						id = ""
						line.split('townid = ')[1].chars.each do |c|
							break if [ " ", "\n" ].any? { |d| c == d }
							id << c
						end
						num_2_faction[:"#{sort_line line, 'num == ', ' then'}"] = id
					end
					flag=2 if line.include?('return')
		when 2 then flag=3 if line.include?('function H55_GetRaceElementalTypeID') # flag - 2-4 Get town to summoning unit ID; start at 1934 line as of RC14B4
		when 3 then if line.include?('cityrace') then
						town, element = nil, nil
						if line.include?('H55_BKnightSwitch') then
							town = "#{sort_line line, 'cityrace == ', ' and H5'}#{sort_line line, 'player] == ', ' then'}"
							element = line.split('elemtype = ')[1]
						elsif line.include?("[player]") then next;
						elsif line.include?('end') then
							town = "#{sort_line line, 'cityrace == ', ' then'}"
							element = "#{sort_line line, 'elemtype = ', ' end'}"
						elsif line.include?('cityrace') then
							town = "#{sort_line line, 'cityrace == ', ' then'}"
							element = line.split('elemtype = ')[1]
						end
						element = element.chars.map {|x| x[/\d+/]}.join('')
						town_2_elmnt[:"#{town}"] = element
					end
					flag=4 if line.include?('return')
		when 4 then if line.include?('SetCount(hero)') && line.include?('function') then # Match Artefacts to artefact sets; start at 2325
						@current_set = sort_line line, 'H55_Get', 'SetCount[(]hero[)]'
						artifact_sets[:"#{@current_set}"] = []
						flag=5
					end
					flag=6 if line.include?('function H55_InfoElementals') 
		when 5 then ( artifact_sets[:"#{@current_set}"] += [(sort_line line, 'HasArtefact[(]hero[,]', '[,]')] ) if line.include?('HasArtefact(hero,')
					flag = 4 if line.include?('return')
					# Get blood crystal coef for guild summoning; start at 3034
		when 6 then (flag=7; dblood_const[:"0"] = line.split(' = ')[1].to_i.to_s) if line.include?('local bloodcoef'); 
		when 7 then if line.include?('bloodcoef') then
						key = sort_line line, 'townrace == ', ' then'
						key = 41 if key == nil
						dblood_const[:"#{key}"] = sort_line line, 'bloodcoef = ', ' end'
					end
					break if line.include?('townrace == 8')
		end
	end
		 
	flag=0
	spells_new = []
	town_2_elmnt.each do |key, val|
		unit_name = ''
		desc_vars = []
		file_source = val=='90' ? "creature_summoning_xerxon.txt" : "creature_summoning.txt"
		guild_desc = File.read("#{SOURCE_ADD}/spells/#{file_source}")
		guild_desc.scan(Regexp.union(/<.*?>/,/<.*?>/)).each { |match| desc_vars << match }
		this_town = num_2_faction[:"#{key[0]}"]
		id = "#{num_2_creature[:"#{val}"]}"
		id = "SNOWAPE" if id == "SNOW_APE"
		this_dblood = dblood_const[:"#{dblood_const[:"#{key}"] == nil ? "0" : key}"]
		Dir.glob("#{SOURCE_CREATURES}/**/*#{id}.xdb").reject{ |rj| File.directory?(rj) }.each do |fn|
			doc = File.open(fn) { |f| Nokogiri::XML(f) }
			header = fn.split("GameMechanics")[0]
			path = doc.xpath("//Visual/@href").text.split('#xpointer')[0]
			next if path.nil? or path.include?('None.xdb')
			@visuals = File.open("#{header.chop}#{path}") { |f| Nokogiri::XML(f) }
			unit_name = File.read("#{SOURCE_TXT}#{@visuals.xpath("/CreatureVisual/CreatureNameFileRef/@href")}")
		end
		town_id = nil
		towns.each { |t| town_id = t.text if t.town_id == this_town }
		subs = [ town_id, town_id, unit_name, this_dblood ]
		desc_vars.each_with_index { |var, i| guild_desc.sub! var, "#{subs[i]}" }
		spells_new << Spell.new("GUILD_SUMMONING_#{id}",
				this_dblood,
				nil, #power.join
				nil,
				0,
				"MAGIC_SCHOOL_SPECIAL",
				"0,0,0,0,0,0",
				unit_name.strip,
				guild_desc.strip,
				nil )
	end			
	db.spell(spells_new)
	create_text.guild_summoning(spells_new)
	db.artifact_filter(FILTERS)


	############ make a list of all sets
	flag, artif_set, artif = 0, {}, {}
	File.read(SOURCE_ADVENTUREMAP).each_line do |line|
		case flag
		when 0 then ( artif_set[:"#{sort_line line, 'ARTIFACT_SET_', ' ='}"] = line.split(" = ")[1].to_i ) if line.include?('	ARTIFACT_SET_') 
					flag = 1 if line.include?('Artifact type IDs')
		when 1 then ( artif[:"#{sort_line line, 'ARTIFACT_', ' ='}"] = line.split(" = ")[1].to_i ) if line.include?('	ARTIFACT_') 				
		end
	end

	############ create table with all artifacts and their set matches
	is_set, artifacts = '', []
	doc = File.open(SOURCE_ARTIFACTS) { |f| Nokogiri::XML(f) }
	doc.xpath("//objects/Item").each do |n|
		( id = n.xpath("ID").text ) == ('ARTIFACT_NONE') ? next : nil
		[ 'ARTIFACT_NONE', 'ARTIFACT_FREIDA', 'ARTIFACT_PRINCESS' ].any? { |a| id == a } ? next : nil
		id.slice! 'ARTIFACT_'
		artifact_sets.each { |key, array| array.include?("#{artif[:"#{id}"]}") ? (  is_set = "#{key}".upcase; break; ) : is_set = 'NONE' }
		artifacts << Artifact.new(id,
			n.xpath("obj/Slot").text,
			n.xpath("obj/CostOfGold").text,
			(n.xpath("obj/CanBeGeneratedToSell").text == 'false' ? ( id == 'MASK_OF_DOPPELGANGER' ? 'ARTF_CLASS_RELIC' : 'ARTF_CLASS_GRAIL' ) : n.xpath("obj/Type").text),
			n.xpath("obj/HeroStatsModif/Attack").text,
			n.xpath("obj/HeroStatsModif/Defence").text,
			n.xpath("obj/HeroStatsModif/SpellPower").text,
			n.xpath("obj/HeroStatsModif/Knowledge").text,
			n.xpath("obj/HeroStatsModif/Morale").text,
			n.xpath("obj/HeroStatsModif/Luck").text,
			is_set,
			n.xpath("obj/CanBeGeneratedToSell").text,
			n.xpath("obj/NameFileRef/@href").text,
			n.xpath("obj/DescriptionFileRef/@href").text)
	end
	db.artifact(artifacts)
	create_text.artifact(artifacts)
	
	########## create table with all creature artifacts and effects
	m_effects = []
	doc_effect = File.open(SOURCE_MICRO_ARTIFACTS) { |f| Nokogiri::XML(f) }
	doc_effect.xpath("//objects/Item").each do |n|
		id = n.xpath("ID").text
		id == 'MAE_WOUNDING' ? next : nil
		m_effects << Micro_artifact.new(id,
		0,
		n.xpath("Obj/MicroArtifactEffect/Cost/Gold").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Wood").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Ore").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Mercury").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Crystal").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Sulfur").text,
		n.xpath("Obj/MicroArtifactEffect/Cost/Gem").text,
		n.xpath("Obj/MicroArtifactEffect/Name/@href").text,
		n.xpath("Obj/MicroArtifactEffect/OfName/@href").text,
		n.xpath("Obj/MicroArtifactEffect/Description/@href").text)
	end
	db.micro_effect(m_effects)
	create_text.micro_effect(m_effects)

	########## get flavour prefixes
	m_prefix = []
	doc = File.open(SOURCE_MICRO_ARTIFACT_PREFIX) { |f| Nokogiri::XML(f) }
	id = doc.xpath("//objects/Item/ID").text
	doc.xpath("//objects/Item/Obj/MicroArtifactPrefixes/Prefixes/Item").each_with_index do |n,i|
		m_prefix << "#{n.xpath("@href").text}"
	end
	create_text.micro_prefix(m_prefix, id);

	########## create table with all creature artifacts shells
	micro_shells = []
	doc_shell = File.open(SOURCE_MICRO_ARITFACT_SHELLS) { |f| Nokogiri::XML(f) }
	doc_shell.xpath("//objects/Item").each do |n|
		id = n.xpath("ID").text
		desc = n.xpath("Obj/MicroArtifactShell/Description/@href").text
		micro_shells << Micro_shell.new(id,
		n.xpath("Obj/MicroArtifactShell/Name/@href").text,
		desc)
	end
	db.micro_shell(micro_shells)
	create_text.micro_shell(micro_shells)

	para "Success"
end