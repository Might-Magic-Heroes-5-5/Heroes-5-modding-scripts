require 'fileutils'
require 'sqlite3'
require 'code/readskills'
require 'code/statics'
require 'code/methods'
require 'nokogiri'


def popupate_skill_perks hero_id, new_skill, template_klass, db
	source_perks = 'source\data\GameMechanics\RefTables\Skills.xdb'
	doc = File.open(source_perks) { |f| Nokogiri::XML(f) }
	doc.xpath("//objects/Item").each_with_index do |n, i|
		txt_name, txt_desc = [], []
		(n.xpath("obj/NameFileRef/Item/@href").each { |s| txt_name << s.text })
		(n.xpath("obj/DescriptionFileRef/Item/@href").each { |d| txt_desc << d.text })
		s_id = n.xpath("ID").text
		type = n.xpath("obj/SkillType").text
		base = n.xpath("obj/BasicSkillID").text
		if type == 'SKILLTYPE_SPECIAL_PERK' and base == "#{new_skill}" then
			req_item = n.xpath("obj/SkillPrerequisites/Item")
			req_item.each do |t|
				req_skills = []
				klas = t.xpath("Class").text
				t.xpath("dependenciesIDs/Item").each { |p| req_skills << p.text }
				if klas == "#{template_klass}" then
					unless req_skills.empty? then
						db.execute "insert into #{hero_id} values ( ?, ?, ?, ?);",s_id, req_skills.join(','), type, '99' if @db_flag != 0
						make_text "#{OUTPUT}/skills/#{s_id}", ["name"], "#{SOURCE_TXT}/#{txt_name[0]}", 'skill'
						make_text "#{OUTPUT}/skills/#{s_id}", ["desc", "additional" ], "#{SOURCE_TXT}/#{txt_desc[0]}", 'skill'
					end
				end
			end
		end
	end
end

Shoes.app do

	
	source_phoenix_stats = 'source/data/GameMechanics/RPGStats/ConjuredPhoenix.xdb'
	@db_flag = 0
	db = SQLite3::Database.new "#{DB_NAME}"
	###########add Haven Renegade class
	id = 'HERO_CLASS_KNIGHT_RENEGADE'
	get_klas = db.execute "select * from HERO_CLASS_KNIGHT"
	db.execute "delete from classes WHERE id='#{id}';" if @db_flag != 0
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );" if @db_flag != 0
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_KNIGHT'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1] if @db_flag != 0 
	make_text "#{OUTPUT}/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	get_klas.each do |n|
		n[0] = 'HERO_SKILL_DARK_MAGIC' if n[0] == 'HERO_SKILL_SHATTER_DARK_MAGIC'
		db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n if @db_flag != 0
	end
	popupate_skill_perks id, "HERO_SKILL_DARK_MAGIC", "HERO_CLASS_KNIGHT", db
	
	##add heroes to Knight Renegade class
	if @db_flag != 0 then
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='RedHeavenHero01';" 
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Mardigo';"
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='RedHeavenHero05';"
	end
	
	###########add Stronghold Khan class
	id = 'HERO_CLASS_BARBARIAN_KHAN'
	get_klas = db.execute "select * from HERO_CLASS_BARBARIAN"
	if @db_flag != 0 then
		db.execute "delete from classes WHERE id='#{id}';" if 
		klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_BARBARIAN'")[0]
		db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
		#db.execute "DROP TABLE #{id};"
		db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
		get_klas.each { |n| db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n  }
		db.execute "INSERT into #{id} VALUES ( 'HERO_SKILL_VOICE', 12, 'SKILLTYPE_SKILL', 12);" 
	end
	
	popupate_skill_perks id, "HERO_SKILL_VOICE", "HERO_CLASS_BARBARIAN", db
	make_text "#{OUTPUT}/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	
	##add heroes to Khan class
	if @db_flag != 0 then
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Gottai';"
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Quroq';"
		db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Kunyak';"
	end
	###########add Stronghold Veteran class
	id = 'HERO_CLASS_BARBARIAN_VET'
	get_klas = db.execute "select * from HERO_CLASS_BARBARIAN"
	if @db_flag != 0 then
		db.execute "delete from classes WHERE id='#{id}';"
		klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_BARBARIAN'")[0]
		db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
		db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
		get_klas.each { |n| db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n }
		db.execute "INSERT into #{id} VALUES ( 'HERO_SKILL_BARBARIAN_LEARNING', 12, 'SKILLTYPE_SKILL', 12);"
		popupate_skill_perks id, "HERO_SKILL_BARBARIAN_LEARNING", "HERO_CLASS_BARBARIAN", db
	end
	make_text "#{OUTPUT}/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	
	##add heroes to Veteran class 
	if @db_flag != 0 then
		db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Azar';"
		db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Crag';"
		db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Hero6';"
	end
	###ARTIFACTS
	sets = db.execute "select name from artifact_filter WHERE filter='by_set'"
	sets = sets[0][0] + ",CORNUCOPIA,LEGION"
	if @db_flag != 0 then
		db.execute "UPDATE artifact_filter SET name='#{sets}' WHERE filter='by_set';"
		cornucopia = [ "RES_CRYSTAL", "RES_GEM", "RES_MERCURY", "RES_ORE", "RES_SULPHUR", "RES_WOOD" ]
		cornucopia.each { |c| db.execute "UPDATE artifacts SET art_set='CORNUCOPIA' WHERE id='#{c}';" } 
		legion = [ "ENDLESS_BAG_OF_GOLD", "LEGION_T1", "LEGION_T2", "LEGION_T3", "LEGION_T4", "LEGION_T5", "LEGION_T6", "LEGION_T7" ]
		legion.each { |l| db.execute "UPDATE artifacts SET art_set='LEGION' WHERE id='#{l}';" } 
	end
	###SPELLS
	make_text "#{OUTPUT}/spells/SPELL_PHANTOM", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_PHANTOM/pred.txt", 'pred'
	make_text "#{OUTPUT}/spells/SPELL_DISPEL", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_DISPEL/pred.txt", 'pred'
	make_text "#{OUTPUT}/spells/SPELL_BLESS", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_BLESS/pred.txt", 'pred'
	make_text "#{OUTPUT}/spells/SPELL_CURSE", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_CURSE/pred.txt", 'pred'
	make_text "#{OUTPUT}/spells/SPELL_BERSERK", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_BERSERK/pred.txt", 'pred'
	phoenix_stats = File.open(source_phoenix_stats) { |f| Nokogiri::XML(f) }
	hp_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Health").text
	hp_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Health_PerPower").text
	hp_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Health_PerLevel").text
	hp_kn = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Health_PerKnowledge").text
	d_min_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMin").text
	d_min_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMin_PerPower").text
	d_min_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMin_PerLevel").text
	d_max_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMax").text
	d_max_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMax_PerPower").text
	d_max_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/DamageMax_PerLevel").text
	offence_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Offence").text
	offence_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Offence_PerPower").text
	offence_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Offence_PerLevel").text
	defence_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Defence").text
	defence_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Defence_PerPower").text
	defence_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Defence_PerLevel").text
	init_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Initiative").text
	init_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Initiative_PerPower").text
	init_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Initiative_PerLevel").text
	speed_flat = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Speed").text
	speed_sp = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Speed_PerPower").text
	speed_lvl = phoenix_stats.xpath("/RPGCombatUniqueCreatureStats/Speed_PerLevel").text
	ph_stats = "Health = #{hp_flat} + #{hp_sp}*SP + #{hp_lvl}*HERO_LVL + #{hp_kn}*KN
Min damage = #{d_min_flat} + #{d_min_sp}*SP + #{d_min_lvl}*HERO_LVL
Max damage = #{d_max_flat} + #{d_max_sp}*SP + #{d_max_lvl}*HERO_LVL
Attack = #{offence_flat} + #{offence_sp}*SP + #{offence_lvl}*HERO_LVL
Defense = #{defence_flat} + #{defence_sp}*SP + #{defence_lvl}*HERO_LVL
Initiative = #{init_flat} + #{init_sp}*SP + #{init_lvl}*HERO_LVL
Speed = #{speed_flat} + #{speed_sp}*SP + #{speed_lvl}*HERO_LVL"
	File.open("#{SOURCE_ADD}/spells/SPELL_CONJURE_PHOENIX/additional.txt", 'w') { |file| file.write(ph_stats) }
	make_text "#{OUTPUT}/spells/SPELL_CONJURE_PHOENIX", [ "additional" ], "#{SOURCE_ADD}/spells/SPELL_CONJURE_PHOENIX/additional.txt", 'skill'
	make_text "#{OUTPUT}/spells/SPELL_CONJURE_PHOENIX", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_CONJURE_PHOENIX/pred.txt", 'pred'
	make_text "#{OUTPUT}/spells/SPELL_DIVINE_VENGEANCE", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_DIVINE_VENGEANCE/pred.txt", 'pred'
	
	RUNES.each_with_index { |r, i| make_text "#{OUTPUT}/spells/#{r}", [ "pred" ], "#{SOURCE_ADD}/spells/runes/pred.txt", 'pred' }
	WARCRIES.each_with_index { |r, i| make_text "#{OUTPUT}/spells/#{r}", [ "pred" ], "#{SOURCE_ADD}/spells/#{r}/pred.txt", 'pred' }
	
	if @db_flag != 0 then
		db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", "SPELL_MANAGE_TOWN", "", "", "0", "0", "MAGIC_SCHOOL_ADVENTURE", "0,0,0,0,0,0" 
		db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", "SPELL_MANAGE_TOWN_GOVERNOR", "", "", "0", "0", "MAGIC_SCHOOL_ADVENTURE", "0,0,0,0,0,0"
		db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", "SPELL_MANAGE_TOWN_GATE", "", "", "25", "0", "MAGIC_SCHOOL_ADVENTURE", "0,0,0,0,0,0"
		db.execute "insert into spells values ( ?, ?, ?, ?, ?, ?, ? );", "SPELL_MANAGE_TOWN_CONVERSION", "", "", "0", "0", "MAGIC_SCHOOL_ADVENTURE", "0,0,0,0,0,0"
	end
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN", [ "name" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN/name.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN", [ "desc" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN/desc.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN/pred.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GOVERNOR", [ "name" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GOVERNOR/name.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GOVERNOR", [ "desc" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GOVERNOR/desc.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GOVERNOR", [ "additional" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GOVERNOR/additional.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GOVERNOR", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GOVERNOR/pred.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GATE", [ "name" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GATE/name.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GATE", [ "desc" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GATE/desc.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GATE", [ "additional" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GATE/additional.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_GATE", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_GATE/pred.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_CONVERSION", [ "name" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_CONVERSION/name.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_CONVERSION", [ "desc" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_CONVERSION/desc.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_CONVERSION", [ "additional" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_CONVERSION/additional.txt"
	make_text "#{OUTPUT}/spells/SPELL_MANAGE_TOWN_CONVERSION", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_MANAGE_TOWN_CONVERSION/pred.txt"
	make_text "#{OUTPUT}/spells", [ "empowered_prediction" ], "#{SOURCE_ADD}/spells/empowered_prediction.txt"
	make_text "#{OUTPUT}/spells", [ "summon_formula" ], "#{SOURCE_ADD}/spells/summon_formula.txt"
	
	###GUILDS
	make_text "#{OUTPUT}/guilds/MAGIC_SCHOOL_RUNIC", [ "name" ], "#{SOURCE_ADD}/guilds/MAGIC_SCHOOL_RUNIC/name.txt"
	make_text "#{OUTPUT}/guilds/MAGIC_SCHOOL_SPECIAL", [ "name" ], "#{SOURCE_ADD}/guilds/MAGIC_SCHOOL_SPECIAL/name.txt"
	

	###CREATURE ARTIFACTS
	MICROARTIFACTS.each do |micro|
		make_text "#{OUTPUT}/micro_artifacts/#{micro}", [ "effect" ], "#{SOURCE_ADD}/micro_artifacts/#{micro}/effect.txt", 'pred'
	end

	if @db_flag != 0 then
		db.execute "CREATE TABLE micro_protection ( id int )"
		db.execute "INSERT into micro_protection VALUES ('0.073'), ('0.146'), ('0.219'), ('0.292'), ('0.347'), ('0.402'), ('0.457'), ('0.497'), ('0.537'), ('0.577'),
	('0.607'), ('0.637'), ('0.657'), ('0.677'), ('0.697'), ('0.717'), ('0.737'), ('0.757'), ('0.777'), ('0.787'), ('0.797'), ('0.807'), ('0.817'),
	('0.827'), ('0.837'), ('0.847'), ('0.857'), ('0.867'), ('0.877'), ('0.882'), ('0.887'), ('0.892'), ('0.897'), ('0.902'), ('0.907'), ('0.912'),
	('0.917'), ('0.922'), ('0.927'), ('0.932'), ('0.937'), ('0.942'), ('0.947'), ('0.952'), ('0.957'), ('0.962'), ('0.967'), ('0.971'), ('0.975'),
	('0.979'), ('0.982'), ('0.985'), ('0.988'), ('0.991'), ('0.993'), ('0.995'), ('0.997'), ('0.998'), ('0.999'), ('1');"

		db.execute "UPDATE micro_artifact_effect SET effect='0' WHERE id='MAE_NONE';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.25' WHERE id='MAE_PIERCING';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.0666667' WHERE id='MAE_ARMOR_CRUSHING';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.2' WHERE id='MAE_HEALTH';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.25' WHERE id='MAE_DEFENCE';"
		db.execute "UPDATE micro_artifact_effect SET effect='55' WHERE id='MAE_MAGIC_PROTECTION';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.0833333333333333' WHERE id='MAE_LUCK';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.0833333333333333' WHERE id='MAE_MORALE';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.0666667' WHERE id='MAE_SPEED';"
		db.execute "UPDATE micro_artifact_effect SET effect='0.75' WHERE id='MAE_HASTE';"
	end
	FileUtils.copy_entry "#{SOURCE_ADD}/panes", "#{OUTPUT}/panes"
	FileUtils.copy_entry "#{SOURCE_ADD}/properties", "#{OUTPUT}/properties"
	
	para "GOOD!"

end