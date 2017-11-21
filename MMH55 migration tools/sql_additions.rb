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
	when "hero" then
		data_to_copy[0].gsub!(/<br><br>/, "\n")
		data_to_copy[0].gsub!(/<br>/, "\n")
		data_to_copy[0].gsub!(/<body_bright>/, '')
		data_to_copy = data_to_copy[0].split('<color_default>').each { |m| m.gsub!(/<color_default>/, '') }
	when "artifact" then
		data_to_copy[0].gsub!(/<color=.*?>/, '')
		data_to_copy = data_to_copy[0].split('<br><br>').each { |m| m.gsub!(/<br>/, "\n") }
	when "spell" then
		data_to_copy[0].gsub!(/<br>/,'')
		data_to_copy[0].gsub!(/<body_bright>/, '')
		data_to_copy = data_to_copy[0].split('<color_default>').each { |m| m.gsub!(/<color_default>/, '') }
	when "skill" then
		if data_to_copy[0].include?('<color=orange>') then
			data_to_copy[0].gsub!(/<br><br>/, "")
			data_to_copy[0].gsub!(/<br>/, "\n")
			data_to_copy[0].gsub!(/<color_default>/, "")
			data_to_copy = data_to_copy[0].split('<color=orange>').each { |m| m.gsub!(/<color=orange>/, '') }
		else
			data_to_copy[0].gsub!(/<br>/, "\n")
			data_to_copy = data_to_copy[0].split('<color_default>' ).each { |m| m.gsub!(/<color_default>/, '') }
		end
	end
	debug("#{dirr},#{target},#{mode},")
	data_to_copy.each_with_index do |t, i|
		@output = File.open("#{dirr + '/' + target[i]}.txt", 'w');
		@output.write("#{t.strip}")
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
	
	def initialize(id,at,df,sp,kn,clas,faction,txt_name,txt_s_name)
		@id,@at,@df,@sp,@kn,@clas,@faction = id,at,df,sp,kn,clas,faction ###Get hero vars
		@txt_name,@txt_s_name = txt_name,txt_s_name 					 ###Get text vars
	end
	
	def stats; return @id, @at, @df, @sp, @kn, @clas, @faction end
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
		@txt_name, @txt_desc, @txt_pred = txt_name, txt_desc, txt_pred		 																			###Get text vars																						###Get text vars
	end

	def stats; return @id, @spell_effect, @spell_increase, @mana, @tier, @guild, @resource_cost end
	def texts; return @txt_name, @txt_desc, @txt_pred end
end

class Artifact
	
	def initialize(id, slot, cost, type, at, df, sp, kn, moral, luck, set, txt_name, txt_desc)
		@id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set = id, slot, cost, type, at, df, sp, kn, moral, luck, set  ###Get artifact vars
		@txt_name, @txt_desc = txt_name, txt_desc			 																		###Get text vars																						###Get text vars
	end

	def stats; return @id, @slot, @cost, @type, @at, @df, @sp, @kn, @moral, @luck, @set end
	def texts; return @txt_name, @txt_desc end
end

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
	
	############ create table with all artifact filters
	db.execute "create table artifact_filter ( name string, filter string );"
	
	Dir.glob("design/artifacts/filters/**/*").reject{ |rj| File.directory?(rj) }.each do |fl|
		filter_name = fl.split("/")[-1].split('.')[0]
		filter = filter_name == 'by_set' ? @sets.keys : (read_skills fl)
		db.execute "insert into artifact_filter values ( ?, ?)", filter.join(",").upcase, filter_name
	end	
	###########add Haven Renegade class
	id = 'HERO_CLASS_KNIGHT_RENEGADE'
	get_klas = db.execute "select * from HERO_CLASS_KNIGHT"
	db.execute "delete from classes WHERE id='#{id}';"
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, app_order int );"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_KNIGHT'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]		
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
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, app_order int );"
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
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, app_order int );"
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
	get_klas.each { |n| db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n }
	db.execute "INSERT into #{id} VALUES ( 'HERO_SKILL_BARBARIAN_LEARNING', 12, 'SKILLTYPE_SKILL', 12);"
	popupate_skill_perks id, "HERO_SKILL_BARBARIAN_LEARNING", "HERO_CLASS_BARBARIAN", db
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	
	##add heroes to Veteran class 
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Azar';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Crag';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Hero6';"
	
	
	
	para "GOOD!"



end