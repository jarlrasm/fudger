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

require 'ui/fudger-gtk/base_ui'
class OtherUi < BaseUi
  def initialize
    super
    $user_interface.builder["other_type_combo"].child.signal_connect("changed") do
      type_changed
    end
    $user_interface.builder["other_type_combo"].text_column=0
  end
  def type_changed()
    if(@selected!=nil)
      unless @selected.type==$user_interface.builder["other_type_combo"].child.text
        @selected.type=$user_interface.builder["other_type_combo"].child.text
      end
    end
  end
  def do_select()
    super
    $user_interface.builder["other_type_combo"].child.text=@selected.type
  end

end