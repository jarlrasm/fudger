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

require 'character'
require 'place'
require 'event'
require 'item'
require 'creature'
require 'religion'
require 'other'
require 'image'
require 'rexml/document'
class Campaign
  include GetText
	attr_accessor :arrays, :characters, :places, :events, :items, :name, :creatures,:religions, :others,  :overview, :images, :male_name_generator,:female_name_generator,:place_name_generator
	def initialize()
		@name=_("Campaign name")
		@characters=[]
		@places=[]
		@events=[]
		@items=[]
		@images=[]
		@creatures=[]
		@religions=[]
		@others=[]
		@system="Systemless"
    @arrays=$systems[system].arrays
    #neccessary in order to init stuff
    Character.new(@system,self)
    Place.new
    Event.new
    Item.new
    Image.new
    Creature.new(@system,self)
    Religion.new
    Other.new
		@overview=_("Add description here")
    @male_name_generator="none"
    @female_name_generator="none"
    @place_name_generator="none"
	end
  def legacy
    if @characters==nil
		@characters=[]
    end
    if @places==nil
		@places=[]
    end
    if @events==nil
		@events=[]
    end
    if @items==nil
		@items=[]
    end
    if @images==nil
		@images=[]
    end
    if @creatures==nil
		@creatures=[]
    end
    if @religions==nil
		@religions=[]
    end
    if @others==nil
		@others=[]
    end
      @creatures.each() do |char|
        if char.tables==nil
        	char.system_changed(@system,self)
        end
      end
  end
  def system
    return @system
  end
  def system=(sys)
    if(sys!=@system)
      @system=sys
      @arrays=$systems[system].arrays
      @characters.each() do |char|
      	char.system_changed(sys,self)
      end
      @creatures.each() do |char|
      	char.system_changed(sys,self)
      end
      $user_interface.system_changed
    end
  end
  def update_array(array)
		@characters.each() do |char|
      char.update_array(array)
    end
  end
	def get_array(name)
		@arrays.each do |array|
			if array.name==name
				return array
			end
		end
		return nil
	end
end
