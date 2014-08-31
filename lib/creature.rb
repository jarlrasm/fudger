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


class Creature < ElementWithRule
  fudger_campaign_accessor [:male_name_generator, :female_name_generator]
	def initialize(system=nil,campaign=nil)
    super
		set_name _("noone")
    unless $campaign==nil
    @male_name_generator=$campaign.male_name_generator
    @female_name_generator=$campaign.female_name_generator
    else
    @male_name_generator=="None"
    @female_name_generator="None"
    end
	end
  def create_character
    char=Character.new($campaign.system)
    if $use_character_name_generator
      if FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_QUESTION,_("Male character?"))
        unless @male_name_generator==nil or @male_name_generator=="None"
          name=$male_character_name_generator.get_name_from_file(@male_name_generator+"_male.yml")
        end
      else
        unless @female_name_generator==nil or @female_name_generator=="None"
          name=$female_character_name_generator.get_name_from_file(@female_name_generator+"_female.yml")
        end
        char.gender=1
      end
      if(name!=nil)
        char.name=name
      end
    end
    char.description=@name
    tables.each_pair do|key,value|
      table=[]
      value.each do |v2|
        table<<v2
      end
      char.tables[key]=table
    end
    hash_tables.each_pair do|key,value|
      table={}
      value.each_pair do |k2,v2|
        table[k2]=v2
      end
      char.hash_tables[key]=table
    end
    $campaign.characters+=[char]
    $user_interface.update_and_select(char)
    project_changed
    
  end
end
