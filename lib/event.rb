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

require 'date_time_override'
require 'element_with_parent'
require 'date'

class Event <ElementWithParent
	fudger_campaign_accessor [:type, :start, :end]
	def initialize()
    super
		set_name _("peace and love")
		@type=_("Other")
    @start=DateTime.new(2009)
    @end=DateTime.new(2009)
	end
end
