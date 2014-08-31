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

require 'ui/fudger-swing/base_panel_handler'
require 'ui/fudger-swing/ruby_swing_table_model_listener'

class WithRulesPanel < BasePanelHandler
  def initialize(panel)
    super(panel)
    @populating_rules_tables=false
  end
  def system_changed
    if $campaign==nil
      return
    end
    notebook=@panel.rule_notebook
    notebook.remove_all
    @h_tables={}
    eval("$systems[$campaign.system].#{@handler}.hash_tables").each do |table|
      vbox = create_gui_for_hash_table(table)
      notebook.add(table.name.capitalize,vbox)
    end
    @tables={}
    eval("$systems[$campaign.system].#{@handler}.tables").each do |table|
      vbox = create_gui_for_table(table)
      notebook.add(table.name.capitalize,vbox)
    end
    if eval("$systems[$campaign.system].#{@handler}.calculations").length>0
      tree_view=javax.swing.JTable.new()
      tree_view.model.set_column_count(2)
      notebook.add("Calculated",tree_view)
      @calculated_treeview=tree_view
    end
  end

  def create_gui_for_table(table)
    tree_view=javax.swing.JTable.new()
    @tables[table]=tree_view
    tree_view.model.set_column_count(1)
    editor=javax.swing.JComboBox.new()
    editor.enabled=false
    tree_view.get_column_model.get_column(0).set_cell_editor(javax.swing.DefaultCellEditor.new(editor))
    if table.modify_keys==true
      editor.enabled=true
      editor.set_editable(true)
      create_table_popup(tree_view)
      unless table.keytable==nil
        $systems[$campaign.system].get_key_table(table.keytable).keys.each do |key|
          editor.add_item(key.name)
        end
      end
      create_table_listener(table, tree_view)
    end
    return tree_view
  end
  
  def create_table_popup(tree_view)
    popup = javax.swing.JPopupMenu.new()
    new_item = javax.swing.JMenuItem.new()
    new_item.setText("Add")
    popup.add(new_item)
    listner=RubySwingActionListener.new() do |evt|
      unless @selected==nil
        tree_view.model.add_row(["noname"].to_java)
      end
    end
    new_item.add_action_listener(listner)
    remove_item = javax.swing.JMenuItem.new()
    remove_item.setText("Remove")
    popup.add(remove_item)
    listner=RubySwingActionListener.new() do |evt|
      unless tree_view.get_selected_row==-1
        tree_view.model.remove_row(tree_view.get_selected_row)
      end
    end
    remove_item.add_action_listener(listner)
    tree_view.set_component_popup_menu(popup)
  end

  def create_table_listener(table, tree_view)
    listner=RubySwingTableModelListener.new() do |evt|
      unless (@populating_rules_tables or @selected==nil)
        @selected.tables[table.name]=[]
        tree_view.model.get_row_count.times do |i|
          @selected.tables[table.name]+=[tree_view.model.get_value_at(i,0)]
        end
        update_tables
      end
    end
    tree_view.model.add_table_model_listener(listner)
  end

  def create_gui_for_hash_table(table)
    tree_view=javax.swing.JTable.new()
    @h_tables[table]=tree_view
    tree_view.model.set_column_count(2)
    keyeditor=javax.swing.JTextField.new()
    keyeditor.enabled=false
    if table.modify_keys==true
      keyeditor=javax.swing.JComboBox.new()
    end
    tree_view.get_column_model.get_column(0).set_cell_editor(javax.swing.DefaultCellEditor.new(keyeditor))
    valueeditor=javax.swing.JComboBox.new()
    tree_view.get_column_model.get_column(1).set_cell_editor(javax.swing.DefaultCellEditor.new(valueeditor))
    if table.modify_keys==true
      keyeditor.enabled=true
      keyeditor.set_editable(true)
      create_hash_table_popup(table,tree_view)
      unless table.keytable==nil
        $systems[$campaign.system].get_key_table(table.keytable).keys.each do |key|
          keyeditor.add_item(key.name)
        end
      end
    end
    table.min_value.upto(table.max_value) do |i|
      if table.translate_value!=nil
        valueeditor.add_item($systems[$campaign.system].get_translator(table.translate_value).translate(@selected,"default",i))
      else
        valueeditor.add_item(i.to_s)
      end
    end
    create_hash_table_listener(table, tree_view)
    return tree_view
  end
  def create_hash_table_listener(table, tree_view)
    listner=RubySwingTableModelListener.new() do |evt|
      unless (@populating_rules_tables or @selected==nil)
        @selected.hash_tables[table.name]={}
        tree_view.model.get_row_count.times do |i|
          combo=tree_view.get_column_model.get_column(1).get_cell_editor.get_component
          val=0
          combo.get_item_count.times do |j|
            if combo.get_item_at(j)==tree_view.model.get_value_at(i,1)
              val=j
            end
          end
          val=val+table.min_value
          @selected.hash_tables[table.name][tree_view.model.get_value_at(i,0)]=val
        end
        update_tables
      end
    end
    tree_view.model.add_table_model_listener(listner)
  end
  def create_hash_table_popup(table,tree_view)
    popup = javax.swing.JPopupMenu.new()
    new_item = javax.swing.JMenuItem.new()
    new_item.setText("Add")
    popup.add(new_item)
    listner=RubySwingActionListener.new() do |evt|
      unless @selected==nil
        if table.translate_value!=nil
          tree_view.model.add_row(["noname",$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,"default",table.def_value)].to_java)
        else
          tree_view.model.add_row(["noname",table.def_value.to_s].to_java)
        end
      end
    end
    new_item.add_action_listener(listner)
    remove_item = javax.swing.JMenuItem.new()
    remove_item.setText("Remove")
    popup.add(remove_item)
    listner=RubySwingActionListener.new() do |evt|
      unless tree_view.get_selected_row==-1
        tree_view.model.remove_row(tree_view.get_selected_row)
      end
    end
    remove_item.add_action_listener(listner)
    tree_view.set_component_popup_menu(popup)
  end
  def update_tables
    @populating_rules_tables=true
    populate_tables
    populate_hash_tables
    populate_other
    @populating_rules_tables=false
  end
  def select(item)
    super(item)
    update_tables unless item==nil
  end
  def populate_tables
    @tables.each_pair do |table,list|
      list.get_model.set_row_count(0)
      @selected.tables[table.name].each do |value|
        list.get_model.add_row([value].to_java)
      end\
      end
  end
  #TODO split up more
  def populate_hash_tables
    @h_tables.each_pair do |table,list|
      list.get_model.set_row_count(0)
      @selected.hash_tables[table.name].each do |key,value|
        if table.translate_value!=nil
          list.get_model.add_row([key,$systems[$campaign.system].get_translator(table.translate_value).translate(@selected,key,value)
            ].to_java)
        else
          list.get_model.add_row([key,value.to_s].to_java)
        end
      end
    end
  end

  def populate_other
    tree_view=@calculated_treeview
    if tree_view==nil
      return
    end
    tree_view.get_model.set_row_count(0)
    eval("$systems[$campaign.system].#{@handler}.calculations").each do |calc|
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
      tree_view.get_model.add_row([calc.name,trans.translate(@selected,"default",value)].to_java)
    end
  end
end
