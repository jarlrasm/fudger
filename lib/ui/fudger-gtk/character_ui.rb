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

require 'ui/fudger-gtk/rule_ui'
require 'ui/fudger-gtk/view_sorter'
class CharacterUi < RuleUi
  include ViewSorter
  include GetText
  def initialize
    super
    $user_interface.builder["importancebox"].signal_connect("changed") do
      importance_changed
    end
    $user_interface.builder["ageinput"].signal_connect("changed") do
      age_changed
    end
    $user_interface.builder["genderbutton"].signal_connect("clicked") do
      gender_changed
    end
    $user_interface.builder["update_character_button"].signal_connect("clicked") do
      update_chooser_list()
    end
    $user_interface.builder["character_sort_combo"].signal_connect("changed") do
      sort_changed()
    end
  end
  def age_changed()
    if(@selected!=nil)
      unless @selected.age==$user_interface.builder["ageinput"].value
        @selected.age=$user_interface.builder["ageinput"].value
      end
    end
  end
  def importance_changed()
    if(@selected!=nil)
      unless @selected.importance==$user_interface.builder["importancebox"].active
        @selected.importance=$user_interface.builder["importancebox"].active
      end
    end
  end
  def gender_changed()
    if @selected.gender==0
      $user_interface.builder["genderbutton"].label=_("Female")
      @selected.gender=1
    else
      $user_interface.builder["genderbutton"].label=_("Male")
      @selected.gender=0
    end
  end
  def do_select()
    super
    $user_interface.builder["ageinput"].value=@selected.age
    $user_interface.builder["importancebox"].active=@selected.importance
    if @selected.gender==0
      $user_interface.builder["genderbutton"].label=_("Male")
    else
      $user_interface.builder["genderbutton"].label=_("Female")
    end
  end
  def update_chooser_list()
    list=$user_interface.builder["character_list"]
    if($user_interface.builder["character_sort_combo"].active==0)
      sort_by_related(list,Character,Place)
    end
    if($user_interface.builder["character_sort_combo"].active==1)
      sort_by_related(list,Character,Event)
    end
    if($user_interface.builder["character_sort_combo"].active==2)
      sort_by_related(list,Character,Religion)
    end
    if($user_interface.builder["character_sort_combo"].active==3)
      sort_by_attribute(list,Character,"importance",
        [_("Irrellevant"),_("Minor"),_("Important"),_("Major"),_("PC")])
    end
  end



  # I don't know why this is neccesary when loading, but it fixes a bug..
  def clean_chooser_list
    super
    unless $user_interface.builder["character_sort_combo"].active==3
      unknowniter=$user_interface.builder["character_list"].model.append(nil)
      $user_interface.builder["character_list"].model.set_value(unknowniter,0,_("Unknown"))
      $user_interface.builder["character_list"].model.set_value(unknowniter,1,nil)
    end
    update_chooser_list()
  end
  def clean_all
    super
  end
  def sort_changed
    clean_chooser_list
  end

end
