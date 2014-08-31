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

require 'ui/fudger-gtk/with_parent_ui'
class PlaceUi < WithParentUi
  def initialize
    super
    $user_interface.builder["place_type_combo"].child.signal_connect("changed") do
      place_type_changed
    end
    $user_interface.builder["place_type_combo"].text_column=0
    $user_interface.builder["update_place_button"].signal_connect("clicked") do
      update_chooser_list()
    end
    
  end
  def place_type_changed()
    if(@selected!=nil)
      unless @selected.type==$user_interface.builder["place_type_combo"].child.text
        @selected.type=$user_interface.builder["place_type_combo"].child.text
      end
    end
  end
  def do_select()
    super
    $user_interface.builder["place_type_combo"].child.text=@selected.type
  end

end
