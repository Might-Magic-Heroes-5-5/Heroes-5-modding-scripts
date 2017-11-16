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


Shoes.app do
	DB_NAME = 'skillwheel.db'
	db = SQLite3::Database.new DB_NAME
	
	###########add Haven Renegade class
	id = 'HERO_CLASS_KNIGHT_RENEGADE'
	get_klas = db.execute "select * from HERO_CLASS_KNIGHT"
	db.execute "delete from classes WHERE id='#{id}';"
	#db.execute "DROP TABLE #{id};"
	db.execute "CREATE TABLE #{id} ( skill string, chance int, type string, app_order int );"
	klas_entry = (db.execute "select * from classes WHERE id='HERO_CLASS_KNIGHT'")[0]
	db.execute "INSERT into classes VALUES ( ?, ?, ?, ?, ?, ?);", id, klas_entry[1..-1]
	get_klas.each do |n|
		n[0] == 'HERO_SKILL_LIGHT_MAGIC' ? n[0] = 'HERO_SKILL_SHATTER_LIGHT_MAGIC' : nil
		db.execute "INSERT into #{id} VALUES ( ?, ?, ?, ?);",n
	end
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	##add heroes to Khan class
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
	make_text "en/classes/#{id}", ["name"], "additions/classes/#{id}.txt"
	
	##add heroes to Veteran class 
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Azar';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Crag';"
	db.execute "UPDATE heroes SET  classes='#{id}' WHERE id='Hero6';"
	
	
	
	para "GOOD!"



end