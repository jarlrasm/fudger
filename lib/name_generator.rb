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
require 'yaml'

class NameGenerator
	def initialize(type)
		@type=type
    list=nil
	end
  def find_name(list,array)
  	name=""
    rule=array[rand(array.length)]
    unless rule.is_a?(Array)
    	return rule
  	end
    rule.each do|subrule|
      if subrule[-4..-1]==".yml"
        n=get_name_from_file(subrule)
        name+=n unless n==nil
      else
        name+=find_name(list,list[subrule])
      end
  	end
  	return name
  end
  def get_name_from_file(filename)
    begin
      file=File.dirname(__FILE__)+"/names/"+filename
      unless File.exist?(file)
        file=File.expand_path("~/.fudger/names/"+filename)
        unless File.exist?(file)
          return nil
        end
      end
      list= YAML::load(File.open(file))
      unless list==nil

        splitname=find_name(list,list["final"]).split
        name=""
        splitname.each do |str|
          name+=str.capitalize+" "
        end
        return name.strip
      end
    rescue Object=>s
      puts s
    end
    return nil
	end
	def get_name()
    gen=eval("$campaign."+@type+"_name_generator")
    file=gen+"_"+@type+".yml"
    return get_name_from_file(file)
	end
	
end
