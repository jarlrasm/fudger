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
class ReligionUi < WithParentUi
  def initialize
    super
    $user_interface.builder["temple_name_generator_chooser"].signal_connect("changed") do
      name_gen_changed
    end
    $user_interface.builder["illegal_toggle"].signal_connect("toggled") do
      unless @selected.illegal==$user_interface.builder["illegal_toggle"].active?
        @selected.illegal=$user_interface.builder["illegal_toggle"].active?
      end
    end
  end
  def name_gen_changed()
    if(@selected!=nil)
      unless @selected.name_generator==$user_interface.builder["temple_name_generator_chooser"].active_text
        @selected.name_generator=$user_interface.builder["temple_name_generator_chooser"].active_text
      end
    end
  end
  def do_select()
    super
    $user_interface.builder["illegal_toggle"].active=@selected.illegal
    chosen=false
    $user_interface.builder["temple_name_generator_chooser"].model.each do |model,path,iter|
      if model.get_value(iter,0)==@selected.name_generator
        $user_interface.builder["temple_name_generator_chooser"].active_iter=iter
        chosen=true
      end
    end
    if !chosen
    $user_interface.builder["temple_name_generator_chooser"].active=0
    end
  end
end
