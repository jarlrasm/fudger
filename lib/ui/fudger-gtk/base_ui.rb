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


class BaseUi
  include GetText
  #page is a BIG hack!
  attr_accessor :page, :tagger, :selected
  def self.all_views
    return @@all_views
  end
  @@all_views={}
  def initialize
    @handle_string=self.class.name.downcase[0..-3]
    @@all_views[@handle_string]=self
    create_related_views()
    create_relation_views_callbacks()
    @page=$user_interface.builder["notebook"].page_num($user_interface.builder[@handle_string+"_list"].parent.parent.parent)
    $user_interface.builder[@handle_string+"_name_input"].signal_connect("changed") do
      name_changed
    end
    $user_interface.builder[@handle_string+"_description_view"].buffer.signal_connect("end-user-action") do
      description_changed
    end
    @tagger=TextTagger.new($user_interface.builder[@handle_string+"_description_view"])
    @@all_views.each_pair do |key,value|
      value.tagger.create_tags
    end
    create_chooser_list()
    $user_interface.builder["add_"+@handle_string+"_button"].signal_connect("clicked") do
      new_item
    end
    $user_interface.builder["remove_"+@handle_string+"_button"].signal_connect("clicked") do
      remove_selected
    end
  end
  def remove_selected
    if @selected!=nil
      eval("$campaign."+@handle_string+"s.delete(@selected)")
      @selected=nil
      update_chooser_list()
    end
    project_changed
  end
  def new_item()
  	item=CampaignElement.create(eval(@handle_string.capitalize))
  	eval("$campaign."+@handle_string+"s+=[item]")
  	update_chooser_list()
    select(item)
    $user_interface.builder[@handle_string+"_name_input"].grab_focus
    project_changed
  end
  def select(item)
    list=$user_interface.builder[@handle_string+"_list"]
    list.model.each() do |model, path, iter|
      if model.get_value(iter,1)==item
        parent_iter=iter.parent
        while parent_iter!=nil
          list.expand_row(parent_iter.path,true)
          parent_iter=parent_iter.parent
        end
        list.selection.select_iter(iter)
        $user_interface.builder["page_chooser"].select_path(Gtk::TreePath.new(page))
      end
    end
  end
  def description_changed()
    unless @selected.description==@tagger.serialize()
      @selected.description=@tagger.serialize()
    end
  end
  def do_select
    if @selected==nil
      return
    end
    $user_interface.builder[@handle_string+"_name_input"].text=@selected.name
    $user_interface.builder[@handle_string+"_description_view"].buffer.text=@selected.description
    update_related_views()

  end
  def name_changed()
    unless @selected.name==$user_interface.builder[@handle_string+"_name_input"].text
      @selected.name=$user_interface.builder[@handle_string+"_name_input"].text
      $user_interface.builder[@handle_string+"_list"].model.each() do |model, path,iter|
        if $user_interface.builder[@handle_string+"_list"].model.get_value(iter,1)==@selected
          $user_interface.builder[@handle_string+"_list"].model.set_value(iter,0,@selected.name)
        end
      end
    end
  end
  def update_relation_view(array,list)
    model=Gtk::ListStore.new(String)
    list.model=model
    array.each() do |char|
      iter=model.append
      model.set_value(iter,0,char.name)
    end
  end
  def self.clean_all_views
    @@all_views.each_value do |view|
      view.clean_all
    end
  end
  def clean_all
    update_chooser_list()
  end
  def relation_view_selection_changed(sel,list)
    if sel.selected!=nil
      name=sel.tree_view.model.get_value(sel.selected,0)
      list.model.each() do |model, path, iter|
        if model.get_value(iter,0)==name
          parent_iter=iter.parent
          while parent_iter!=nil
            list.expand_row(parent_iter.path,true)
            parent_iter=parent_iter.parent
          end
          list.selection.select_iter(iter)
          #careful there buddy...
          $user_interface.builder["page_chooser"].select_path(Gtk::TreePath.new($user_interface.builder["notebook"].page_num(list.parent.parent.parent)))
          sel.unselect_all
        end
      end
    end
  end
  def create_chooser_list()
    $user_interface.builder[@handle_string+"_list"].append_column(Gtk::TreeViewColumn.new(_(@handle_string.capitalize),Gtk::CellRendererText.new,:text=>0))
    $user_interface.builder[@handle_string+"_list"].selection.signal_connect("changed") do |sel|
      $user_interface.builder[@handle_string+"_box"].sensitive=false
      if sel.selected!=nil
        if $user_interface.builder[@handle_string+"_list"].model.get_value(sel.selected,1)!=nil
          @selected=$user_interface.builder[@handle_string+"_list"].model.get_value(sel.selected,1)
          do_select()
          $user_interface.builder[@handle_string+"_box"].sensitive=true
        end
      end
    end
    clean_chooser_list
  end
  def update_chooser_list()
    list=$user_interface.builder[@handle_string+"_list"]
    model=Gtk::TreeStore.new(String, Object)
    list.model=model
    eval("$campaign."+@handle_string+"s").each() do |item|
      iter=model.append(nil)
      model.set_value(iter,0,item.name)
      model.set_value(iter,1,item)
    end
  end

  # I don't know why this is neccesary when loading, but it fixes a bug..
  def clean_chooser_list
    model=Gtk::TreeStore.new(String, Object)
    $user_interface.builder[@handle_string+"_list"].model=model

    update_chooser_list()
  end
  def create_relation_views_callbacks
    @@all_views.each_pair do |key,value|
      list=$user_interface.builder[@handle_string+"_related_to_"+key+"_view"]
      unless list==nil
        list.selection.signal_connect("changed") do |sel|
          relation_view_selection_changed(sel,$user_interface.builder[key+"_list"])
        end
      end
      unless key==@handle_string
        list=$user_interface.builder[key+"_related_to_"+@handle_string+"_view"]
        unless list==nil
          list.selection.signal_connect("changed") do |sel|
            relation_view_selection_changed(sel,$user_interface.builder[@handle_string+"_list"])
          end
        end
      end
    end
  end
  def update_related_views()
    if @selected==nil
      return
    end

    @@all_views.each_pair do |key,value|
      list=$user_interface.builder[@handle_string+"_related_to_"+key+"_view"]
      update_relation_view(eval("@selected.related_"+key+"s"),list) unless list==nil
    end
  end
  def create_related_views()
    @@all_views.each_pair do |key,value|
      list=$user_interface.builder[@handle_string+"_related_to_"+key+"_view"]
      text_cell=Gtk::CellRendererText.new
      list.append_column(Gtk::TreeViewColumn.new(_(key.capitalize),text_cell,:text=>0)) unless list==nil
      unless key==@handle_string
        list=$user_interface.builder[key+"_related_to_"+@handle_string+"_view"]
        text_cell=Gtk::CellRendererText.new
        list.append_column(Gtk::TreeViewColumn.new(_(@handle_string.capitalize),text_cell,:text=>0)) unless list==nil
      end
    end
  end
end
