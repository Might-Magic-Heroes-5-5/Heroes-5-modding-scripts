require 'fileutils'
require 'sqlite3'
require 'code/readskills'
require 'code/methods'
require 'nokogiri'


def popupate_skill_perks hero_id, new_skill, template_klass, db
	source_perks = 'Rc10\data\MMH55-Index\GameMechanics\RefTables\Skills.xdb'
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
						make_text "en/skills/#{s_id}", ["name"], "Rc10/data/MMH55-Texts-EN/#{txt_name[0]}", 'skill'
						make_text "en/skills/#{s_id}", ["desc", "additional" ], "Rc10/data/MMH55-Texts-EN/#{txt_desc[0]}", 'skill'
					end
				end
			end
		end
	end
end

Shoes.app do

	DB_NAME = 'skillwheel.db'
	db = SQLite3::Database.new DB_NAME
	
	
	###########add Haven Renegade class
	id = 'HERO_CLASS_KNIGHT_RENEGADE'
	get_klas = db.execute "select * from HERO_CLASS_KNIGHT"
	db.execute "delete from classes WHERE id='#{id}';"
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, sequence int );"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_KNIGHT'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]	
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	get_klas.each do |n|
		n[0] == 'HERO_SKILL_SHATTER_DARK_MAGIC' ? n[0] = 'HERO_SKILL_DARK_MAGIC' : nil
		db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n
	end
	popupate_skill_perks id, "HERO_SKILL_DARK_MAGIC", "HERO_CLASS_KNIGHT", db
	
	##add heroes to Knight Renegade class
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='RedHeavenHero01';"
	db.execute "UPDATE heroes SET classes='#{id}' WHERE id='Mardigo';"
	
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
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	
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
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	
	##add heroes to Veteran class 
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Azar';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Crag';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Hero6';"
	
	###SPELLS
	make_text "en/spells/SPELL_PHANTOM", [ "pred" ], "additions/spells/SPELL_PHANTOM/pred.txt", 'pred'
	make_text "en/spells/SPELL_DISPEL", [ "pred" ], "additions/spells/SPELL_DISPEL/pred.txt", 'pred'
	make_text "en/spells/SPELL_CONJURE_PHOENIX", [ "pred" ], "additions/spells/SPELL_CONJURE_PHOENIX/pred.txt", 'pred'
	["SPELL_RUNE_OF_CHARGE", "SPELL_RUNE_OF_BERSERKING", "SPELL_RUNE_OF_MAGIC_CONTROL",
	"SPELL_RUNE_OF_EXORCISM", "SPELL_RUNE_OF_ELEMENTAL_IMMUNITY", "SPELL_RUNE_OF_STUNNING",
	"SPELL_RUNE_OF_BATTLERAGE",	"SPELL_RUNE_OF_ETHEREALNESS","SPELL_RUNE_OF_REVIVE", "SPELL_RUNE_OF_DRAGONFORM",
	"SPELL_EFFECT_FINE_RUNE", "SPELL_EFFECT_STRONG_RUNE"].each_with_index do |r, i| 
		make_text "en/spells/#{r}", [ "pred" ], "additions/spells/runes/pred.txt", 'pred'
	end
	["SPELL_WARCRY_RALLING_CRY", "SPELL_WARCRY_CALL_OF_BLOOD", "SPELL_WARCRY_WORD_OF_THE_CHIEF", "SPELL_WARCRY_FEAR_MY_ROAR",
"SPELL_WARCRY_BATTLECRY", "SPELL_WARCRY_SHOUT_OF_MANY"].each_with_index do |r, i| 
		make_text "en/spells/#{r}", [ "pred" ], "additions/spells/#{r}/pred.txt", 'pred'
	end
	para "GOOD!"



end