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

class CreatureUi < RuleUi
  def initialize
    super
    $user_interface.builder["create_character_from_creature_button"].signal_connect("clicked") do
      @selected.create_character
    end
    $user_interface.builder["creature_male_name_generator_box"].signal_connect("changed") do
      name_gen_changed("male")
    end
    $user_interface.builder["creature_female_name_generator_box"].signal_connect("changed") do
      name_gen_changed("female")
    end
  end
  def name_gen_changed(name_type)
    if(@selected!=nil)
      unless eval("@selected."+name_type+"_name_generator")==$user_interface.builder["creature_"+name_type+"_name_generator_box"].active_text
         eval("@selected."+name_type+"_name_generator=$user_interface.builder['creature_"+name_type+"_name_generator_box'].active_text")
      end
    end
  end
  def do_select()
    super
    if @selected!=nil
      set_up_name_generator_chooser("male")
      set_up_name_generator_chooser("female")
    end
  end
  def set_up_name_generator_chooser(name_type)
    model=Gtk::ListStore.new(String)
    iter=model.append()
    model.set_value(iter,0,name_type.capitalize+" names")
    i=1
    chosen=0
    gens=get_name_generators(name_type)
    gens.each  do |generator|
      iter=model.append()
      model.set_value(iter,0,generator)

      if(generator==eval("@selected."+name_type+"_name_generator"))
        chosen=i
      end
      i+=1
    end

    chooser=$user_interface.builder["creature_"+name_type+"_name_generator_box"]
    chooser.model=model
    cell_renderer=Gtk::CellRendererText.new
    chooser.clear
    chooser.pack_start(cell_renderer,true)
    chooser.set_attributes(cell_renderer,:text=>0)
    chooser.active=chosen
  end
end
