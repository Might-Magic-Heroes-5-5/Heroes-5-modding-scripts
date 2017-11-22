def check_dir file, origin; return file.start_with?("/")? file : ((origin.split('MMH55-Index')[1].split('/'))[0...-1].join('/') + '/' + file ) end

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
	
	def initialize(id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability, gold, wood, ore, mercury, crystal, sufur, gem, txt_name)
		@id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability = id, at, df, shots, min_d, max_d, spd, init, fly, hp, spell, masteries, mana, tier, faction, growth, ability  ###Get creature vars
		@gold, @wood, @ore, @mercury, @crystal, @sufur, @gem = gold, wood, ore, mercury, crystal, sufur, gem
		@txt_name = txt_name 				 																																																		###Get text vars
	end

	def stats; return @id, @at, @df, @shots, @min_d, @max_d, @spd, @init, @fly, @hp, @spell, @masteries, @mana, @tier, @faction, @growth, @ability end
	def price; return @gold, @wood, @ore, @mercury, @crystal, @sufur, @gem end
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