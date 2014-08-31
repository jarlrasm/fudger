#    This file is part of Fudger.
#
#    Fudger is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Fudger is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Fudger.  If not, see <http://www.gnu.org/licenses/>.

#TODO Complete rewrite?? This is a mess..
require 'rexml/document'
class RuleSystem
  class RuleArray
    attr_accessor :name, :modify_keys, :keys
    def initialize(element)
      @name=element.attributes["id"]
      @keys=[]
      @modify_keys=element.attributes["modify_keys"]=="True"
      element.elements.each("default_key") do |elem|
        @keys+=[elem.attributes["id"]]
      end
    end
  end
  class RuleKey
    attr_accessor :name, :attributes
    def initialize(element)
      @name=element.attributes["id"]
      @attributes={}
      element.attributes.each do |key,value|
        @attributes[key]=value
      end
    end
  end
  class RuleKeyTable
    attr_accessor :name, :keys
    def initialize(element)
      @name=element.attributes["id"]
      @keys=[]
      element.elements.each("key") do |elem|
        @keys+=[RuleKey.new(elem)]
      end
    end
  end
  class TranslatorKeyRule
    def initialize(element)
      @subrules=[]
      element.elements.each do |elem|
        rule=TranslatorKeyRule.create(elem)
        @subrules+=[rule] unless rule==nil
      end
    end
    def calculate(character,table,hint)
      return 0
    end
    def formula(table,hint)
      return ""
    end
    def self.create(element)
      if element.name=="sum"
        return SumTranslatorKeyRule.new(element)
      end
      if element.name=="div"
        return DivTranslatorKeyRule.new(element)
      end
      if element.name=="mult"
        return MultTranslatorKeyRule.new(element)
      end
      if element.name=="sub"
        return SubTranslatorKeyRule.new(element)
      end
      if element.name=="rounddown"
        return RounddownTranslatorKeyRule.new(element)
      end
      if element.name=="number"
        return NumberTranslatorKeyRule.new(element)
      end
      if element.name=="calculate_from"
        return CalculateFromTranslatorKeyRule.new(element)
      end
      if element.name=="calculate"
        return CalculateTranslatorKeyRule.new(element)
      end
      if element.name=="translate"
        return TranslateTranslatorKeyRule.new(element)
      end
      return nil
    end
  end
  class SumTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
    end
    def formula(table,hint)
      if @subrules[0].formula(table,hint).is_a?(Numeric) and @subrules[1].formula(table,hint).is_a?(Numeric)
        return @subrules[0].formula(table,hint)+@subrules[1].formula(table,hint)
      end
      if @subrules[1].formula(table,hint).is_a?(Numeric)
        if @subrules[1].formula(table,hint)==0
          return @subrules[0].formula(table,hint).to_s
        end
        if @subrules[1].formula(table,hint)<0
          return @subrules[0].formula(table,hint).to_s+@subrules[1].formula(table,hint).to_s
        end
      end
      return @subrules[0].formula(table,hint).to_s+"+"+@subrules[1].formula(table,hint).to_s
    end
    def calculate(character,table,hint)
      return @subrules[0].calculate(character,table,hint)+@subrules[1].calculate(character,table,hint)
    end
  end
  class TranslateTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
      @translator=element.attributes["translate_value"]
    end
    def formula(table,hint)
      return @subrules[0].formula(table,hint).to_s
    end
    def calculate(character,table,hint)
      puts @translator
      return $systems[$campaign.system].get_translator(@translator).translate(character,"default",@subrules[0].calculate(character,table,hint))
    end
  end
  class DivTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
    end
    def formula(table,hint)
      if @subrules[0].formula(table,hint).is_a?(Numeric) and @subrules[1].formula(table,hint).is_a?(Numeric)
        return @subrules[0].formula(table,hint)/@subrules[1].formula(table,hint)
      end
      if @subrules[1].formula(table,hint).is_a?(Numeric)
        if @subrules[1].formula(table,hint)==0
          return @subrules[0].formula(table,hint).to_s
        end
      end
      return @subrules[0].formula(table,hint).to_s+"/"+@subrules[1].formula(table,hint).to_s
    end
    def calculate(character,table,hint)
      return @subrules[0].calculate(character,table,hint).to_f/@subrules[1].calculate(character,table,hint).to_f
    end
  end
  class MultTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
    end
    def formula(table,hint)
      if @subrules[0].formula(table,hint).is_a?(Numeric) and @subrules[1].formula(table,hint).is_a?(Numeric)
        return @subrules[0].formula(table,hint)/@subrules[1].formula(table,hint)
      end
      if @subrules[1].formula(table,hint).is_a?(Numeric)
        if @subrules[1].formula(table,hint)==0
          return @subrules[0].formula(table,hint).to_s
        end
      end
      return @subrules[0].formula(table,hint).to_s+"*"+@subrules[1].formula(table,hint).to_s
    end
    def calculate(character,table,hint)
      return @subrules[0].calculate(character,table,hint).to_f*@subrules[1].calculate(character,table,hint).to_f
    end
  end
  class SubTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
    end
    def formula(table,hint)
      if @subrules[0].formula(table,hint).is_a?(Numeric) and @subrules[1].formula(table,hint).is_a?(Numeric)
        return @subrules[0].formula(table,hint)-@subrules[1].formula(table,hint)
      end
      if @subrules[1].formula(table,hint).is_a?(Numeric)
        if @subrules[1].formula(table,hint)==0
          return @subrules[0].formula(table,hint).to_s
        end
      end
      return @subrules[0].formula(table,hint).to_s+"-"+@subrules[1].formula(table,hint).to_s
    end
    def calculate(character,table,hint)
      return @subrules[0].calculate(character,table,hint).to_f-@subrules[1].calculate(character,table,hint).to_f
    end
  end
  class RounddownTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      super(element)
    end
    def calculate(character,table,hint)
      return @subrules[0].calculate(character,table,hint).to_i
    end
    def formula(table,hint)
      return "~"+@subrules[0].formula(table,hint).to_s
    end
  end
  class NumberTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      @number=element.attributes["id"].to_i
      super(element)
    end
    def calculate(character,table,hint)
      return @number
    end
    def formula(table,hint)
      return @number
    end
  end
  class CalculateTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      @id=element.attributes["id"]
      super(element)
    end
    def calculate(character,table,hint)
      table.keys.each do |key|
        if key.name==hint
          return key.attributes[@id].to_i
        end
      end
      return 0
    end
    def formula(table,hint)
      table.keys.each do |key|
        if key.name==hint
          return key.attributes[@id].to_i
        end
      end
      return 0
    end
  end
  class CalculateFromTranslatorKeyRule<TranslatorKeyRule
    def initialize(element)
      @id=element.attributes["id"]
      super(element)
    end
    def calculate(character,table,hint)
      if table!=nil
        table.keys.each do |key|
          if key.name==hint
            character.hash_tables.each_pair do |key2, value|
              value.each_pair do |key3,value2|
                if key3==key.attributes[@id]
                  return value2
                end
              end
            end
          end
        end
      else
        character.hash_tables.each_pair do |key2, value|
          value.each_pair do |key3,value2|
            if key3==@id
              return value2
            end
          end
        end
      end
      return 0
    end
    def formula(table,hint)
      if table!=nil
      table.keys.each do |key|
        if key.name==hint
          return key.attributes[@id]
        end
      end
      else
          return @id
      end
      return 0
    end
  end
  class TranslatorKey
    attr_accessor :name
    def initialize(element)
      @name=element.attributes["id"].to_i
      @default_value=element.attributes["default_value"]
      @value=element.attributes["value"]
      if element.elements[1]!=nil
        @rule=TranslatorKeyRule.create(element.elements[1])
      end
    end
    def translate(character,table,hint)
      if(hint=="default" and @default_value!=nil)
        return @default_value
      end
      if @rule!=nil
        return @value.gsub("value", @rule.calculate(character,table,hint).to_s).gsub("formula", @rule.formula(table,hint).to_s)
      end
      return @value
    end
  end
  class RuleTranslator
    attr_accessor :name
    def initialize(system,element)
      @name=element.attributes["id"]
      @keys=[]
      element.elements.each("key") do |elem|
        @keys+=[TranslatorKey.new(elem)]
      end
      table=element.attributes["key_table"]
      if table!=nil
        @table=system.get_key_table(table)
      end
    end
    def translate(character,hint,value)
      @keys.each do |key|
        if(key.name==value)
          return key.translate(character,@table,hint)
        end
      end
      return value.to_s
    end
  end
  class RuleHashTable
    attr_accessor :name,:singular, :modify_keys,:array,:keytable,:translate_value,:def_value,:max_value,:min_value
    def initialize(element)
      @name=element.attributes["id"]
      @singular=element.attributes["singular"]
      @modify_keys=element.attributes["modify_keys"]=="True"
      @array=element.attributes["key_from_array"]
      @keytable=element.attributes["keytable"]
      @min_value=element.attributes["min_value"].to_i
      @max_value=element.attributes["max_value"].to_i
      @def_value=element.attributes["def_value"].to_i
      @translate_value=element.attributes["translate_value"]
    end
  end
  class RuleTable
    attr_accessor :name,:singular, :modify_keys,:keytable
    def initialize(element)
      @name=element.attributes["id"]
      @singular=element.attributes["singular"]
      @modify_keys=element.attributes["modify_keys"]=="True"
      @keytable=element.attributes["keytable"]
		
    end
  end
  class Calculation
    attr_accessor :name,:translate_value,:attribute
    def initialize(element)
      @name=element.attributes["id"]
      @translate_value=element.attributes["translate_value"]
      @attribute=element.attributes["attribute"]
    end
  end
  class CharacterSystem
    attr_accessor :hash_tables,:tables, :calculations
    def initialize(system,element)
      @system=system
      @hash_tables=[]
      @tables=[]
      @calculations=[]
      element.elements.each("hash_table") do |elem|
        @hash_tables+=[RuleHashTable.new(elem)]
      end
      element.elements.each("table") do |elem|
        @tables+=[RuleTable.new(elem)]
      end
      element.elements.each("calculation") do |elem|
        @calculations+=[Calculation.new(elem)]
      end
		
    end
    def get_hash_table(name)
      @hash_tables.each do |h_table|
        if h_table.name==name
          return h_table
        end
      end
      return nil
    end
    def get_calculation(name)
      @calculations.each do |h_table|
        if h_table.name==name
          return h_table
        end
      end
      return nil
    end
    def get_table(name)
      @tables.each do |table|
        if table.name==name
          return table
        end
      end
      return nil
    end
  end
	attr_accessor :name, :character,:arrays, :css, :print_css, :creature
  #RuleSystem
	def initialize(file)
		doc = REXML::Document.new(file)
		@name=doc.elements["system"].attributes["id"]
		@css=doc.elements["system"].attributes["css"]
		@print_css=doc.elements["system"].attributes["print_css"]
		@arrays=[]
		doc.elements.each("//array") do |elem|
			array=RuleArray.new(elem)
			@arrays+=[array]
		end
		@keytables=[]
		doc.elements.each("//key_table") do |elem|
			key_table=RuleKeyTable.new(elem)
			@keytables+=[key_table]
		end
		@translators=[]
		doc.elements.each("//translator") do |elem|
			trans=RuleTranslator.new(self,elem)
			@translators+=[trans]
		end
		@character=CharacterSystem.new(self,doc.elements["//character"])
		@creature=CharacterSystem.new(self,doc.elements["//creature"])
	end
	def get_array(name)
		@arrays.each do |array|
			if array.name==name
				return array
			end
		end
		return nil
	end
	def get_key_table(name)
		@keytables.each do |key_table|
			if key_table.name==name
				return key_table
			end
		end
		return nil
	end
	def get_translator(name)
		@translators.each do |tr|
			if tr.name==name
				return tr
			end
		end
		return nil
	end
end


