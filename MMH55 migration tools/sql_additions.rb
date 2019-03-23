require 'fileutils'
require 'sqlite3'
require 'code/readskills'
require 'code/methods'
require 'nokogiri'


def popupate_skill_perks hero_id, new_skill, template_klass, db
	source_perks = 'Rc11\MMH55-Index\GameMechanics\RefTables\Skills.xdb'
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
						db.execute "insert into #{hero_id} values ( ?, ?, ?, ?);",s_id, req_skills.join(','), type, '99'
						make_text "en/skills/#{s_id}", ["name"], "#{SOURCE_TXT}/#{txt_name[0]}", 'skill'
						make_text "en/skills/#{s_id}", ["desc", "additional" ], "#{SOURCE_TXT}/#{txt_desc[0]}", 'skill'
					end
				end
			end
		end
	end
end

Shoes.app do

	DB_NAME = 'skillwheel.db'
	SOURCE_ADD = 'additions_ru'
	SOURCE_TXT = 'Rc11/MMH55-Texts-RU'
	db = SQLite3::Database.new DB_NAME
	source_phoenix_stats = 'Rc11/MMH55-Index/GameMechanics/RPGStats/ConjuredPhoenix.xdb'

	###########add Haven Renegade class
	id = 'HERO_CLASS_KNIGHT_RENEGADE'
	get_klas = db.execute "select * from HERO_CLASS_KNIGHT"
	db.execute "delete from classes WHERE id='#{id}';"
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_KNIGHT'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]	
	make_text "en/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	get_klas.each do |n|
		n[0] == 'HERO_SKILL_SHATTER_DARK_MAGIC' ? n[0] = 'HERO_SKILL_DARK_MAGIC' : nil
		db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n
	end
	popupate_skill_perks id, "HERO_SKILL_DARK_MAGIC", "HERO_CLASS_KNIGHT", db
	
	##add heroes to Knight Renegade class
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='RedHeavenHero01';"
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Mardigo';"
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='RedHeavenHero05';"
	
	###########add Stronghold Khan class
	id = 'HERO_CLASS_BARBARIAN_KHAN'
	get_klas = db.execute "select * from HERO_CLASS_BARBARIAN"
	db.execute "delete from classes WHERE id='#{id}';"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_BARBARIAN'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
	get_klas.each { |n| db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n }
	db.execute "INSERT into #{id} VALUES ( 'HERO_SKILL_VOICE', 12, 'SKILLTYPE_SKILL', 12);"
	popupate_skill_perks id, "HERO_SKILL_VOICE", "HERO_CLASS_BARBARIAN", db
	make_text "en/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	
	##add heroes to Khan class
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Gottai';"
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Quroq';"
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Kunyak';"
	
	###########add Stronghold Veteran class
	id = 'HERO_CLASS_BARBARIAN_VET'
	get_klas = db.execute "select * from HERO_CLASS_BARBARIAN"
	db.execute "delete from classes WHERE id='#{id}';"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_BARBARIAN'")[0]
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
	get_klas.each { |n| db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n }
	db.execute "INSERT into #{id} VALUES ( 'HERO_SKILL_BARBARIAN_LEARNING', 12, 'SKILLTYPE_SKILL', 12);"
	popupate_skill_perks id, "HERO_SKILL_BARBARIAN_LEARNING", "HERO_CLASS_BARBARIAN", db
	make_text "en/classes/#{id}", ["name"], "#{SOURCE_ADD}/classes/#{id}.txt"
	
	##add heroes to Veteran class 
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Azar';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Crag';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Hero6';"

	###ARTIFACTS
		sets = db.execute "select name from artifact_filter WHERE filter='by_set'"
		sets = sets[0][0] + ",CORNUCOPIA,LEGION"
		db.execute "UPDATE artifact_filter SET name='#{sets}' WHERE filter='by_set';"
		
	###SPELLS
	make_text "en/spells/SPELL_PHANTOM", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_PHANTOM/pred.txt", 'pred'
	make_text "en/spells/SPELL_DISPEL", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_DISPEL/pred.txt", 'pred'
	make_text "en/spells/SPELL_BLESS", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_BLESS/pred.txt", 'pred'
	make_text "en/spells/SPELL_CURSE", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_CURSE/pred.txt", 'pred'
	make_text "en/spells/SPELL_BERSERK", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_BERSERK/pred.txt", 'pred'
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
	make_text "en/spells/SPELL_CONJURE_PHOENIX", [ "additional" ], "#{SOURCE_ADD}/spells/SPELL_CONJURE_PHOENIX/additional.txt", 'skill'
	make_text "en/spells/SPELL_CONJURE_PHOENIX", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_CONJURE_PHOENIX/pred.txt", 'pred'
	make_text "en/spells/SPELL_DIVINE_VENGEANCE", [ "pred" ], "#{SOURCE_ADD}/spells/SPELL_DIVINE_VENGEANCE/pred.txt", 'pred'
	["SPELL_RUNE_OF_CHARGE", "SPELL_RUNE_OF_BERSERKING", "SPELL_RUNE_OF_MAGIC_CONTROL",
	"SPELL_RUNE_OF_EXORCISM", "SPELL_RUNE_OF_ELEMENTAL_IMMUNITY", "SPELL_RUNE_OF_STUNNING",
	"SPELL_RUNE_OF_BATTLERAGE",	"SPELL_RUNE_OF_ETHEREALNESS","SPELL_RUNE_OF_REVIVE", "SPELL_RUNE_OF_DRAGONFORM",
	"SPELL_EFFECT_FINE_RUNE", "SPELL_EFFECT_STRONG_RUNE"].each_with_index do |r, i| 
		make_text "en/spells/#{r}", [ "pred" ], "#{SOURCE_ADD}/spells/runes/pred.txt", 'pred'
	end
	["SPELL_WARCRY_RALLING_CRY", "SPELL_WARCRY_CALL_OF_BLOOD", "SPELL_WARCRY_WORD_OF_THE_CHIEF", "SPELL_WARCRY_FEAR_MY_ROAR",
"SPELL_WARCRY_BATTLECRY", "SPELL_WARCRY_SHOUT_OF_MANY"].each_with_index do |r, i| 
		make_text "en/spells/#{r}", [ "pred" ], "#{SOURCE_ADD}/spells/#{r}/pred.txt", 'pred'
	end
	
	###CREATURE ARTIFACTS
	[ "MAE_ARMOR_CRUSHING", "MAE_DEFENCE", "MAE_HASTE", "MAE_HEALTH", "MAE_LUCK", "MAE_MAGIC_PROTECTION", "MAE_MORALE", "MAE_PIERCING", "MAE_SPEED" ].each do |micro|
		make_text "en/micro_artifacts/#{micro}", [ "effect" ], "#{SOURCE_ADD}/micro_artifacts/#{micro}/effect.txt", 'pred'
	end

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

	para "GOOD!"

end