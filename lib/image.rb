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

class Image <CampaignElement
  def to_yaml(opts = {})
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri) do |map|
        map.add("name",@name)
        map.add("description",@description)
        map.add("filename",@filename)
      end
    end

  end
  fudger_campaign_accessor [:image]
  def filename
    return @filename
  end
  def filename=(name)
    @image=File.new(name).read
    @filename=File.basename(name)
    project_changed(true)
  end
	def initialize()
    super
		set_name _("noimage")
		@filename="fudger.png"
    @image=File.new(File.dirname(__FILE__)+"/images/fudger.png").read
	end
end
