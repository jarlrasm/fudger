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

class Religion < ElementWithParent
  fudger_campaign_accessor [:illegal, :name_generator]
	def initialize()
    super
		set_name _("godless")
    @illegal=false
    @name_generator="None"
	end
  def get_temple_name
    unless @name_generator==nil or @name_generator=="None"
      return $temple_name_generator.get_name_from_file($temple_generators[@name_generator])
    end
    if $campaign.religions.select{|rel|rel.name==parent}.length>0
      return $campaign.religions.select{|rel|rel.name==parent}[0].get_temple_name
    end
    return "Unnamed temple"
  end
end
