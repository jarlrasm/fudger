require 'java'
require 'ui/fudger-swing/fudger_swing_ui.jar'
require 'ui/fudger-swing/html_viewer'
require 'ui/fudger-swing/splash'
require 'ui/fudger-swing/characterpanel'
require 'ui/fudger-swing/place_panel'
require 'ui/fudger-swing/creature_panel'
require 'ui/fudger-swing/event_panel'
require 'ui/fudger-swing/image_panel'
require 'ui/fudger-swing/item_panel'
require 'ui/fudger-swing/other_panel'
require 'ui/fudger-swing/religion_panel'
require 'ui/fudger-swing/ruby_swing_action_listener'
require 'ui/fudger-swing/fudger_editor_kit'
require 'ui/fudger-swing/page_chooser_cell_renderer'
#make nativelooking gui
javax.swing.UIManager::setLookAndFeel(javax.swing.UIManager::getSystemLookAndFeelClassName())
class UserInterface
	attr_accessor :main_window,:character_panel
  def initialize()
    @main_window=org.rubyforge.fudger.MainWindow.new
  end
  def load_temple_name_generators()
    
  end
  def create_array_selector_popup(tree_view)
    popup = javax.swing.JPopupMenu.new()
    new_item = javax.swing.JMenuItem.new()
    new_item.setText("Add")
    popup.add(new_item)
    listner=RubySwingActionListener.new() do |evt|
      tree_view.get_model.root.add(javax.swing.tree.DefaultMutableTreeNode.new("noname"))
      tree_view.model.reload
    end
    new_item.add_action_listener(listner)
    remove_item = javax.swing.JMenuItem.new()
    remove_item.setText("Remove")
    popup.add(remove_item)
    listner=RubySwingActionListener.new() do |evt|
      if tree_view.get_selection_count==1
        tree_view.model.root.remove(tree_view.get_min_selection_row)
        tree_view.model.reload
      end
    end
    remove_item.add_action_listener(listner)
    tree_view.set_component_popup_menu(popup)
  end
  def create_array_selectors(panel,system)
    panel.remove_all
    @array_lists={}
    arrays=system.arrays
    if system==$systems[$campaign.system]
      arrays=$campaign.arrays
    end
    arrays.each do |array|
      if array.modify_keys
        tree=javax.swing.JTree.new()
        tree.model.root.removeAllChildren()
        tree.set_root_visible(false)
        tree.set_editable(true)
        @array_lists[array]=tree
        array.keys.each do|key|
          tree.get_model.root.add(javax.swing.tree.DefaultMutableTreeNode.new(key))
        end
        create_array_selector_popup(tree)
        tree.model.reload
        scroll_pane = javax.swing.JScrollPane.new()
        scroll_pane.set_viewport_view(tree)
        panel.add(array.name.capitalize,scroll_pane)
      end
    end
  end
  def set_up_page_chooser
    model=javax.swing.DefaultListModel.new
    ["Overview","Characters","Places","Events","Items","Images","Creatures","Religions","Others"].each do |item|
      model.add_element(item)
    end
    @main_window.page_chooser.add_list_selection_listener() do |evt|
      @main_window.pages.get_layout.show(@main_window.pages,@main_window.page_chooser.get_selected_value().downcase)
    end
    @main_window.page_chooser.set_model(model)
    @main_window.page_chooser.set_cell_renderer(PageChooserCellRenderer.new())
  end
  def add_generator(name)

    menu_item= javax.swing.JMenuItem.new
    menu_item.set_text(name)
    listener=RubySwingActionListener.new do |evt|
      yield
    end
    menu_item.add_action_listener(listener)
    @main_window.generator_menu.add(menu_item)
  end
  def campaign_properties
    dialog=org.rubyforge.fudger.configure_project_dialog.new(@main_window,true)
    property_dialog_set_up_system_chooser(dialog)
    property_dialog_setup_name_generators(dialog)
    listener=RubySwingActionListener.new do |evt|
      property_dialog_callback(dialog)
    end
    dialog.close_button.add_action_listener(listener)
    create_array_selectors(dialog.system_details_panel,$systems[$campaign.system])
    dialog.show
  end

  def property_dialog_set_up_system_chooser(dialog)
    dialog.name_input.text=$campaign.name
    $systems.each_key  do |system|
      dialog.system_chooser.add_item(system)
    end
    dialog.system_chooser.set_selected_item($campaign.system)
    dialog.system_chooser.add_action_listener do
      value=dialog.system_chooser.get_selected_item
      create_array_selectors(dialog.system_details_panel,$systems[value])
    end
  end
  
  def property_dialog_setup_name_generators(dialog)
    dialog.male_names.add_item("Male names")
    gens=get_name_generators("male")
    gens.each  do |generator|
      dialog.male_names.add_item(generator)
    end
    dialog.male_names.set_selected_item($campaign.male_name_generator)
    dialog.female_names.add_item("Female names")
    gens=get_name_generators("female")
    gens.each  do |generator|
      dialog.female_names.add_item(generator)
    end
    dialog.female_names.set_selected_item($campaign.female_name_generator)
    dialog.place_names.add_item("Place names")
    gens=get_name_generators("place")
    gens.each  do |generator|
      dialog.place_names.add_item(generator)
    end
    dialog.place_names.set_selected_item($campaign.place_name_generator)
  end

  def property_dialog_callback(dialog)
    $campaign.name=dialog.name_input.text
    $campaign.system=dialog.system_chooser.get_selected_item
    $campaign.male_name_generator=dialog.male_names.get_selected_item
    $campaign.female_name_generator=dialog.female_names.get_selected_item
    $campaign.place_name_generator=dialog.place_names.get_selected_item
    @array_lists.each_pair do |array,list|
      array.keys=[]
      list.model.root.children.each do |node|
        array.keys<<node.get_user_object()
      end
      $campaign.update_array(array)
    end
    $campaign.system=dialog.system_chooser.get_selected_item
    dialog.dispose
  end
  def save_as
    chooser = javax.swing.JFileChooser.new
    return_val = chooser.show_save_dialog(@main_window)
    if(return_val == javax.swing.JFileChooser::APPROVE_OPTION)
      save_file(chooser.get_selected_file().get_path())
    end

  end
  def open_file
    chooser = javax.swing.JFileChooser.new
    return_val = chooser.show_open_dialog(@main_window)
    if(return_val == javax.swing.JFileChooser::APPROVE_OPTION)
      load_file(chooser.get_selected_file().get_path())
    end

  end
  def select_by_name(name)
    ["characters","places","events","creatures","images","items","religions","others"].each do |handler|
      eval("$campaign.#{handler}").each do |item|
        if item.name==name
          select(item)
          return
        end
      end
    end
  end
  def configure_ui
    listener=RubySwingActionListener.new do |evt|
      new_campaign
    end
    @main_window.new_menu.add_action_listener(listener)
    listener=RubySwingActionListener.new do |evt|
      open_file
    end
    @main_window.open_file_menu.add_action_listener(listener)
    listener=RubySwingActionListener.new do |evt|
      save_as
    end
    @main_window.save_as_menu.add_action_listener(listener)
    listener=RubySwingActionListener.new do |evt|
      gen=ReportGenerator.new()
      gen.generate
    end
    @main_window.report_menu.add_action_listener(listener)
    overview_listener=RubySwingDocumentListener.new do |evt|
      $campaign.overview=evt.getDocument.getText(0,evt.getDocument.length)
    end
    selection_model=@main_window.related_table.get_selection_model
    selection_model.add_list_selection_listener do |evt|
      unless @updating_related_table or @main_window.related_table.get_selected_row<0 or @main_window.related_table.get_selected_column<0
        name=@main_window.related_table.get_model.get_value_at(@main_window.related_table.get_selected_row,@main_window.related_table.get_selected_column)
        unless name==nil
          select_by_name(name)
        end
        @main_window.related_table.clear_selection
      end
    end
    @main_window.overview_editor.set_editor_kit(FudgerEditorKit.new())
    @main_window.overview_editor.document.add_document_listener(overview_listener)
    @character_panel=CharacterPanelHandler.new(@main_window.character_panel)
    @place_panel=PlacePanelHandler.new(@main_window.place_panel)
    @creature_panel=CreaturePanelHandler.new(@main_window.creature_panel)
    @event_panel=EventPanelHandler.new(@main_window.event_panel)
    @item_panel=ItemPanelHandler.new(@main_window.item_panel)
    @image_panel=ImagePanelHandler.new(@main_window.image_panel)
    @other_panel=OtherPanelHandler.new(@main_window.other_panel)
    @religion_panel=ReligionPanelHandler.new(@main_window.religion_panel)
    set_up_page_chooser
  end
  def system_changed
    @character_panel.system_changed
    @creature_panel.system_changed
  end
  def do_project_changed(changed)
  end
  def campaign_closed
    @main_window.work_area.set_visible(false)
    @main_window.generator_menu.set_enabled(false)
    @main_window.save_as_menu.set_enabled(false)
    @main_window.report_menu.set_enabled(false)
  end
  #don't give nil to this method. Use the exact panel if you need to use nil
  def select(item)
    if item==nil
      return
    end
    eval("@#{item.class.name.downcase}_panel.select(item)")
    update_related_table(item)
  end

  def update_related_table(item)
    @updating_related_table=true
    table=@main_window.related_table
    model=javax.swing.table.DefaultTableModel.new(["Characters","Places","Events","Creatures","Images","Items","Religions","Other"].to_java,0)
    table.set_model(model)
    unless item==nil
      j=0
      ["characters","places","events","creatures","images","items","religions","others"].each do |handler|
        if eval("model.get_row_count<item.related_#{handler}.length")
          eval("model.set_row_count(item.related_#{handler}.length)")
        end
        i=0
        eval("item.related_#{handler}").each do |char|
          model.set_value_at(char.name,i,j)
          i+=1
        end
        j+=1
      end
    end
    @updating_related_table=false
  end
  #legacy func
  def update_tree(which)
    eval("@#{which.downcase}_panel.update_tree()")
  end
  def reset_ui
    unless $campaign==nil
      @main_window.overview_editor.set_text($campaign.overview)
      @main_window.work_area.set_visible(true)
      @main_window.generator_menu.set_enabled(true)
      @main_window.save_as_menu.set_enabled(true)
      @main_window.report_menu.set_enabled(true)
    end
    update_tree("Character")
    update_tree("Place")
    update_tree("Event")
    update_tree("Creature")
    update_tree("Image")
    update_tree("Item")
    update_tree("Other")
    update_tree("Religion")
    @character_panel.system_changed
    @creature_panel.system_changed
  end
  def run
    @main_window.setVisible(true)
    reset_ui
  end
  def update_all
    reset_ui
  end
end
