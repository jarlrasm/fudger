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
require 'ui/fudger-gtk/time_box'
class EventUi < WithParentUi
  def initialize
    super
    @start_box=TimeBox.new($user_interface.builder["start_time_box"])
    @start_box.emit_changed do |time|
      event_start_changed(time)
    end
    @end_box=TimeBox.new($user_interface.builder["end_time_box"])
    @end_box.emit_changed do |time|
      event_end_changed(time)
    end
    $user_interface.builder["event_type_combo"].child.signal_connect("changed") do
      event_type_changed
    end
    $user_interface.builder["event_type_combo"].text_column=0
    $user_interface.builder["update_event_button"].signal_connect("clicked") do
      update_chooser_list()
    end
  end
  def event_type_changed()
    if(@selected!=nil)
      unless @selected.type==$user_interface.builder["event_type_combo"].child.text
        @selected.type=$user_interface.builder["event_type_combo"].child.text
        project_changed
      end
    end
  end
  def event_start_changed(time)
    if(@selected!=nil)
      unless @selected.start==time
        @selected.start=time
        @end_box.min=time
      end
    end
  end
  def event_end_changed(time)
    if(@selected!=nil)
      unless @selected.end==time
        @selected.end=time
      end
    end
  end
  def do_select()
    super
    $user_interface.builder["event_type_combo"].child.text=@selected.type
    @start_box.min=DateTime.new(-50000)
    @start_box.max=DateTime.new(50000)
    @end_box.min=DateTime.new(-50000)
    @end_box.max=DateTime.new(50000)
    @end_box.time=@selected.end
    @start_box.time=@selected.start
    if @selected.parent!=nil
      parent=$campaign.events.select{|event|event.name==@selected.parent}[0]
      @start_box.min=parent.start
      @start_box.max=parent.end
      @end_box.max=parent.end
    end
    @end_box.min=@start_box.time
  end

end
