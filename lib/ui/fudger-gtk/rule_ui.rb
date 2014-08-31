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

class RuleUi < BaseUi
  def initialize
    super
    
  end
  def system_changed
    notebook=$user_interface.builder[@handle_string+"_rule_notebook"]
    while notebook.n_pages>0
      notebook.remove_page(0)
    end
    @h_tables={}
    eval("$systems[$campaign.system].#{@handle_string}.hash_tables").each do |table|
      vbox = create_gui_for_hash_table(table)
      notebook.append_page(vbox,Gtk::Label.new(table.name.capitalize))
    end
    @tables={}
    eval("$systems[$campaign.system].#{@handle_string}.tables").each do |table|
      vbox = create_gui_for_table(table)
      notebook.append_page(vbox,Gtk::Label.new(table.name.capitalize))
    end
    if eval("$systems[$campaign.system].#{@handle_string}.calculations").length>0
      tree_view=Gtk::TreeView.new()
    model=Gtk::ListStore.new(String,String)
    tree_view.model=model
    col=Gtk::TreeViewColumn.new(_("Name"),Gtk::CellRendererText.new,:text=>0)
    tree_view.append_column(col)
    col=Gtk::TreeViewColumn.new(_("Value"),Gtk::CellRendererText.new,:text=>1)
    tree_view.append_column(col)
      notebook.append_page(tree_view,Gtk::Label.new(_"Calculated"))
      @calculated_treeview=tree_view
    end
    notebook.show_all
  end

  def create_gui_for_table(table)
    vbox=Gtk::VBox.new
    tree_view=Gtk::TreeView.new
    @tables[table]=tree_view
    model=Gtk::ListStore.new(String)
    tree_view.model=model
    render = create_table_key_renderer( table, tree_view)
    col=Gtk::TreeViewColumn.new(table.singular.capitalize,render,:text=>0)
    tree_view.append_column(col)
    vbox.pack_start(tree_view,true,true)
    if table.modify_keys==true
      hbox=Gtk::HBox.new
      add_button=create_table_add_button(table, tree_view)
      hbox.pack_start(add_button,false,false)
      remove_button = create_table_remove_button(table, tree_view)
      hbox.pack_start(remove_button,false,false)
      vbox.pack_end(hbox,false,false)
    end
    return vbox
  end

  def create_table_remove_button(table, tree_view)
    remove_button=Gtk::Button.new(Gtk::Stock::REMOVE)
    remove_button.signal_connect("clicked") do
      sel=tree_view.selection.selected
      if sel!=nil
        what=tree_view.model.get_value(sel,0)
        @selected.tables[table.name].delete(what)
        tree_view.model.remove(sel)
        project_changed
      end
    end
    return remove_button
  end

  def create_table_add_button( table, tree_view)
    add_button=Gtk::Button.new(Gtk::Stock::ADD)
    add_button.signal_connect("clicked") do
      iter=tree_view.model.append()
      tree_view.model.set_value(iter,0,"something")
      @selected.tables[table.name]<<"something"
      project_changed
    end
    return add_button
  end

  def create_table_key_renderer( table, tree_view)
    render=Gtk::CellRendererText.new
    if table.modify_keys
      render=Gtk::CellRendererCombo.new
      render.model=Gtk::ListStore.new(String)
      render.text_column=0
      render.has_entry=true
      render.editable=true
      render.signal_connect("edited") do |renderer,path, text|
        old=tree_view.model.get_value(tree_view.model.get_iter(path),0)
        tree_view.model.set_value(tree_view.model.get_iter(path),0,text)
        @selected.tables[table.name]+=[text]
        if @selected.tables[table.name].include?(old)
          @selected.tables[table.name].delete(old)
        end
        unless old==text
          project_changed
        end
      end
    end
    return render
  end

  def create_gui_for_hash_table(table)
    vbox=Gtk::VBox.new
    tree_view=Gtk::TreeView.new
    @h_tables[table]=tree_view
    model=Gtk::ListStore.new(String,String)
    tree_view.model=model
    render = create_hash_table_key_renderer(table, tree_view)
    col=Gtk::TreeViewColumn.new(table.singular.capitalize,render,:text=>0)
    tree_view.append_column(col)
    render = create_hash_table_value_renderer(table, tree_view)
    col=Gtk::TreeViewColumn.new(_("Level"),render,:text=>1)
    tree_view.append_column(col)
    vbox.pack_start(tree_view,true,true)
    if table.modify_keys==true
      hbox=Gtk::HBox.new
      add_button = create_hash_table_add_button(table, tree_view)
      hbox.pack_start(add_button,false,false)
      remove_button = create_hash_table_remove_button(table, tree_view)
      hbox.pack_start(remove_button,false,false)
      vbox.pack_end(hbox,false,false)
    end
    return vbox
  end

  def create_hash_table_remove_button( table, tree_view)
    remove_button=Gtk::Button.new(Gtk::Stock::REMOVE)
    remove_button.signal_connect("clicked") do
      sel=tree_view.selection.selected
      if sel!=nil
        what=tree_view.model.get_value(sel,0)
        @selected.hash_tables[table.name].delete(what)
        tree_view.model.remove(sel)
        project_changed
        do_select
      end
    end
    return remove_button
  end

  def create_hash_table_add_button(table, tree_view)
    add_button=Gtk::Button.new(Gtk::Stock::ADD)
    add_button.signal_connect("clicked") do
      iter=tree_view.model.append()
      tree_view.model.set_value(iter,0,_("something"))
      if table.translate_value!=nil
        tree_view.model.set_value(iter,1,$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,"default",table.def_value))
      else
        tree_view.model.set_value(iter,1,table.def_value.to_s)
      end
      @selected.hash_tables[table.name][_("something")]=table.def_value
      project_changed
        do_select
    end
    return add_button
  end

  def create_hash_table_value_renderer(table, tree_view)
    render=Gtk::CellRendererCombo.new
    render.model=Gtk::ListStore.new(String)
    render.text_column=0
    render.has_entry=false
    render.editable=true
    render.signal_connect("edited") do |renderer,path,text|
      what=tree_view.model.get_value(tree_view.model.get_iter(path),0)
      iter=render.model.iter_first
      i=0
      value=0
      iter=render.model.iter_first
      while iter.next!
        i+=1
        if render.model.get_value(iter,0)==text
          value=i
        end
      end
      value=value+table.min_value
      if table.translate_value!=nil
        tree_view.model.set_value(tree_view.model.get_iter(path),1,$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,what,value))
      else
        tree_view.model.set_value(tree_view.model.get_iter(path),1,value.to_s)
      end
      unless @selected.hash_tables[table.name][what]==value
        @selected.hash_tables[table.name][what]=value
        project_changed
        do_select
      end
    end
    return render
  end

  def create_hash_table_key_renderer(table, tree_view)
    render=Gtk::CellRendererText.new
    if table.modify_keys
      render=Gtk::CellRendererCombo.new
      render.model=Gtk::ListStore.new(String)
      render.text_column=0
      render.has_entry=true
      render.editable=true
      render.signal_connect("edited") do |renderer,path, text|
        old=tree_view.model.get_value(tree_view.model.get_iter(path),0)
        tree_view.model.set_value(tree_view.model.get_iter(path),0,text)
        unless @selected.hash_tables[table.name][text]==@selected.hash_tables[table.name][old]
          @selected.hash_tables[table.name][text]=@selected.hash_tables[table.name][old]
          @selected.hash_tables[table.name].delete(old)
          project_changed
        do_select
        end
      end
    end
    return render
  end
  def do_select()
    super
    populate_tables
    populate_hash_tables
    populate_other
  end
  def populate_tables
    @tables.each_pair do |table,list|
      list.model.clear
      @selected.tables[table.name].each do |value|
        iter=list.model.append()
        list.model.set_value(iter,0,value)
      end
      render=list.get_column(0).cell_renderers[0]
      if(table.keytable!=nil and table.modify_keys)
        render.model.clear
        $systems[$campaign.system].get_key_table(table.keytable).keys.each do |key|
          iter=render.model.append()
          render.model.set_value(iter,0,key.name)
        end

      end
    end
  end
  #TODO split up more
  def populate_hash_tables
    @h_tables.each_pair do |table,list|
      list.model.clear
      @selected.hash_tables[table.name].each do |key,value|
        iter=list.model.append()
        list.model.set_value(iter,0,key)
        if table.translate_value!=nil
          list.model.set_value(iter,1,$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,key,value))
        else
          list.model.set_value(iter,1,value.to_s)
        end
      end
      render=list.get_column(0).cell_renderers[0]
      if(table.keytable!=nil and table.modify_keys)
        render.model.clear
        $systems[$campaign.system].get_key_table(table.keytable).keys.each do |key|
          iter=render.model.append()
          render.model.set_value(iter,0,key.name)
        end

      end

      render=list.get_column(1).cell_renderers[0]
      render.model.clear
      table.min_value.upto(table.max_value) do |i|
        iter=render.model.append()
        if table.translate_value!=nil
          render.model.set_value(iter,0,$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,"default",i))
        else
          render.model.set_value(iter,0,i.to_s)
        end
      end
    end
  end

  def populate_other
      tree_view=@calculated_treeview
      if tree_view==nil
        return
      end
      tree_view.model=Gtk::ListStore.new(String,String)
    eval("$systems[$campaign.system].#{@handle_string}.calculations").each do |calc|
      trans=$systems[$campaign.system].get_translator(calc.translate_value)
      value=0
      if calc.attribute!=nil
        @selected.hash_tables.each_pair do |key2, values|
          values.each_pair do |key3,value2|
            if key3==calc.attribute
              value=value2
            end
          end
        end
      end
      iter=tree_view.model.append()
      tree_view.model.set_value(iter,0,calc.name)
      tree_view.model.set_value(iter,1,trans.translate(@selected,"default",value))
    end
  end
end
