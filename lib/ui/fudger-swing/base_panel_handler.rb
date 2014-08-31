# To change this template, choose Tools | Templates
# and open the template in the editor.

class BasePanelHandler
	attr_accessor :panel, :selected
  def initialize(panel)
		@panel=panel
    @panel.editor.set_visible(false)
    @handler=self.class.name.downcase[0..-13]
    @is_updating=false
		configure
  end
  def select(item)
    @selected=item
		if item==nil
      @panel.editor.set_visible(false)
		else
      @is_updating=true
      @panel.name_input.set_text(item.name)
      @panel.description_entry.set_text(item.description)
      @panel.editor.set_visible(true)
      $user_interface.main_window.page_chooser.set_selected_value(@handler.capitalize+"s",true)
      @is_updating=false
		end
  end
  def update_tree()
    @is_updating=true
    do_update_tree
    @is_updating=false
  end
  #This is the func that should be overridden in subclasses
  def do_update_tree()
    model=@panel.item_tree.get_model()
    model.root.removeAllChildren()
    unless $campaign==nil
      eval("$campaign.#{@handler.downcase}s").each() do |char|
        node=org.rubyforge.fudger.ExtraDataTreeNode.new(char.name)
        node.setExtraData(char)
        model.root.add(node)
      end
    end
    model.reload
  end
  def rename_in_tree(node,item)
    @is_updating=true
    node.children.each do |sub_node|
      if sub_node.get_extra_data==item
        sub_node.user_object=item.name
      end
      rename_in_tree(sub_node, item)
    end
    @is_updating=false
  end
  def configure
    #next line could be in the ui itself, but it was easier to put here.
    @panel.item_tree.set_expands_selected_paths(true)
    new_listner=RubySwingActionListener.new do |evt|
      char=CampaignElement.create(eval("#{@handler.capitalize}"))
      eval("$campaign.#{@handler}s+=[char]")
      $user_interface.update_tree(@handler)
      $user_interface.select(char)
      @panel.name_input.request_focus()
    end
    @panel.new_menu.add_action_listener(new_listner)
    @panel.update_menu.add_action_listener() do |evt|
      $user_interface.update_tree(@handler)
    end
    @panel.remove_menu.add_action_listener() do |evt|
      unless @selected==nil
        eval("$campaign.#{@handler}s.delete(@selected)")
        select(nil)
        $user_interface.update_tree(@handler)
      end
    end
    name_listener=RubySwingDocumentListener.new do |evt|
      unless @is_updating
        unless @selected==nil
          @selected.name=evt.getDocument.getText(0,evt.getDocument.length)
          rename_in_tree(@panel.item_tree.model.root,@selected)
          @panel.item_tree.model.reload
        end
      end
    end
		@panel.name_input.document.add_document_listener(name_listener)
    tree_listener=RubySwingTreeSelectionListener.new do |evt|
      unless @is_updating
        unless @panel.item_tree.getLastSelectedPathComponent==nil
          if @panel.item_tree.getLastSelectedPathComponent.is_a?(org.rubyforge.fudger.ExtraDataTreeNode)
            $user_interface.select(@panel.item_tree.getLastSelectedPathComponent.getExtraData)
          end
        end
      end
    end
		@panel.item_tree.addTreeSelectionListener(tree_listener)
    description_listener=RubySwingDocumentListener.new do |evt|
      unless @selected==nil
        @selected.description=evt.getDocument.getText(0,evt.getDocument.length)
      end
    end
    @panel.description_entry.document.add_document_listener(description_listener)
  end
end
