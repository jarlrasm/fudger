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

require 'campaign_element'
class ElementWithRule < CampaignElement
	fudger_campaign_accessor [:hash_tables,:tables]
  def initialize(system=nil,campaign=nil)
    super()
    @hash_tables={}
    @tables={}
    system_changed(system,campaign)
    
  end
  def update_array(array)
    eval("$systems[$campaign.system].#{self.class.name.downcase}.hash_tables").each do |table|
      if table.array==array.name
        left_to_add=array.keys.clone
        to_remove=[]
        hash_table=@hash_tables[table.name]
        hash_table.each_pair do |key,value|
          if left_to_add.include?(key)
            left_to_add-=[key]
          else
            to_remove+=[key]
          end
        end
        to_remove.each do |key|
          @hash_tables[table.name].delete(key)
        end
        left_to_add.each do |key|
          @hash_tables[table.name][key]=table.def_value
        end
      end
    end
  end
  def system_changed(system,campaign=nil)
    @hash_tables={}
    @tables={}
    if campaign==nil
      campaign=$campaign
    end
    if system==nil
      system=campaign.system
    end
   eval("$systems[system].#{self.class.name.downcase}.hash_tables").each do |table|
      ht={}
      if table.array!=nil
        campaign.get_array(table.array).keys.each do |key|
          ht[key]=table.def_value
        end
      end
      @hash_tables[table.name]=ht
    end
    eval("$systems[system].#{self.class.name.downcase}.tables").each do |table|
      @tables[table.name]=[]
    end
  end
end
