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

#This class is a fucking mess, but it sort of works..
class TextTagger
  include GetText
	def initialize(text_view)
		@text_view=text_view
		@text_view.buffer.signal_connect("changed") do
			text_changed
		end
		@pointcursor=Gdk::Cursor.new(Gdk::Cursor::HAND1)
		@lastevent=@currentevent=nil
		#hack!!
		@text_view.signal_connect("motion-notify-event") do
			if @lastevent==nil and @currentevent==nil
				@text_view.get_window(Gtk::TextView::WINDOW_TEXT).set_cursor(nil)
			end
			@lastevent=@currentevent
			@currentevent=nil
		end
    create_tags
    @public_tag.priority=0
		adjust_menu
	end
  def update_tag_colors
    @public_tag.foreground=$public_tag_color
		BaseUi.all_views.each_pair do |key,ui|
      @text_view.buffer.tag_table[key].foreground=$link_color
    end
  end
  def create_tags
    #this function might be called many times...
    if(@text_view.buffer.tag_table.lookup("public")==nil)
      @public_tag=Gtk::TextTag.new("public")
      @public_tag.foreground=$public_tag_color
      @text_view.buffer.tag_table.add(@public_tag)
    end
		BaseUi.all_views.each_pair do |key,ui|
      if(@text_view.buffer.tag_table.lookup(key)==nil)
        tag=@text_view.buffer.create_tag(key,:foreground=>$link_color)
        tag.signal_connect("event") do |tag, view, event, iter|
          tag_event(event, iter,tag,$user_interface.builder[key+"_list"],ui)
        end
      end
    end
  end
  #page sets the page of the notebook. I don't know if this is the best way of doing it tho..
  def tag_event(event, iter,tag,list,ui)
    if event.is_a?(Gdk::EventMotion)
      @lastevent=@currentevent
      @currentevent=event
      @text_view.get_window(Gtk::TextView::WINDOW_TEXT).set_cursor(@pointcursor)
    end
    if event.event_type==Gdk::Event::BUTTON_PRESS
      if !iter.begins_tag?(tag)
        iter.backward_to_tag_toggle(tag)
      end
      iter2=iter.clone
      iter2.forward_to_tag_toggle(tag)
      name = iter.get_text(iter2)
      item=eval("$campaign."+tag.name+"s.select{|obj| obj.name==name}[0]")
      if(item!=nil)
        ui.select(item)
      end
    end
  end
	def adjust_menu
		@text_view.signal_connect("populate-popup") do |view, menu|
			selection=@text_view.buffer.selection_bounds
			startiter=selection[0]
			enditer=selection[1]
			selected=selection[2]
			if selected
				menuitem=Gtk::ImageMenuItem.new(Gtk::Stock::ADD)
				submenu=Gtk::Menu.new()
				menuitem.submenu=submenu
        BaseUi.all_views.each_pair do |key,view|
          item=Gtk::MenuItem.new(_(key.capitalize))
          item.signal_connect("activate") do
            add_callback(key,@text_view.buffer.get_text(startiter,enditer))
            text_changed
          end
          submenu.append(item)
        end
				menu.prepend(menuitem)
				menuitem.show_all
				menuitem=Gtk::MenuItem.new(_("Public knowledge"))
				menuitem.signal_connect("activate") do
          @text_view.buffer.begin_user_action
					@text_view.buffer.apply_tag(@public_tag,startiter,enditer)
					@text_view.buffer.signal_emit("changed")
          @text_view.buffer.end_user_action
				end
				menu.prepend(menuitem)
				menuitem.show_all
				menuitem=Gtk::MenuItem.new(_("GM knowledge"))
				menuitem.signal_connect("activate") do
          @text_view.buffer.begin_user_action
					@text_view.buffer.remove_tag(@public_tag,startiter,enditer)
					@text_view.buffer.signal_emit("changed")
          @text_view.buffer.end_user_action
				end
				menu.prepend(menuitem)
				menuitem.show_all
			end
		end
	end
	def add_callback(type,name)
    if type=="character"
      char=Character.new($campaign.system)
    else
      char=eval(type.capitalize).new()
    end
		char.name=name
		eval("$campaign."+type+"s+=[char]")
		eval("$user_interface."+type+"_ui").update_chooser_list()
    project_changed
	end
	def tag(klass)
		eval("$campaign."+klass+"s").each() do |char|
			iters=@text_view.buffer.start_iter.forward_search(char.name,Gtk::TextIter::SEARCH_TEXT_ONLY)
			while iters!=nil
				if iters[0].starts_word? and iters[1].ends_word?
					@text_view.buffer.apply_tag(klass,iters[0],iters[1])
					BaseUi.all_views.each_pair do |key,view|
            view.update_related_views()
          end
				end
				iters=iters[1].forward_search(char.name,Gtk::TextIter::SEARCH_TEXT_ONLY)
			end
		end
	end
  def serialize()
    buffer=@text_view.buffer
    text=buffer.text
    #Warning Insanity!
    add=0
    iter=buffer.start_iter
    if iter.toggles_tag?(@public_tag)
      text.insert(0,"[public]")
      add+=8
    end
    while iter.forward_to_tag_toggle(@public_tag)
      if(iter.begins_tag?(@public_tag))
        text.insert(add+buffer.start_iter.get_text(iter).length,"[public]")
        add+=8
      else
        text.insert(add+buffer.start_iter.get_text(iter).length,"[/public]")
        add+=9
      end
      #not sure why this is neccesary
      if iter==buffer.end_iter
        return text
      end
    end
    return text
  end
  def find_public_statements
    #I don't trust this func so we catch all problems
    begin
      iter=@text_view.buffer.start_iter.forward_search("[public]",Gtk::TextIter::SEARCH_TEXT_ONLY)
      if iter!=nil
        iter2=iter[1].forward_search("[/public]",Gtk::TextIter::SEARCH_TEXT_ONLY)
        if iter2!=nil
          @text_view.buffer.apply_tag(@public_tag,iter[1],iter2[0])
          @text_view.buffer.delete(iter[0],iter[1])
          iter=@text_view.buffer.start_iter.forward_search("[/public]",Gtk::TextIter::SEARCH_TEXT_ONLY)
          @text_view.buffer.delete(iter[0],iter[1])
        end
      end
    rescue Object=>s
    end
  end
	def text_changed
		#this is prolly SLOW
    BaseUi.all_views.each_pair do |key,view|
      @text_view.buffer.remove_tag(key,@text_view.buffer.start_iter,@text_view.buffer.end_iter)
      tag(key)
    end
    find_public_statements
	end
end
