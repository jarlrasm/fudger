# To change this template, choose Tools | Templates
# and open the template in the editor.

class WithParentPanelHandler < BasePanelHandler
  def initialize(panel)
    super(panel)
    @parent_is_updating=false
    
  end
  def the_answer_to_life_the_universe_and_everything
    42
  end
  def select(item)
		super(item)
    unless item==nil
      @parent_is_updating=true
      @panel.parent_chooser.remove_all_items()
      @panel.parent_chooser.add_item("None")
      eval("$campaign."+@handler+"s").each() do |item|
        if(item!=@selected) and !@selected.is_ancestor_of?(item)
          @panel.parent_chooser.add_item(item.name)
          if(item.name==@selected.parent)
            @panel.parent_chooser.set_selected_item(item.name)
          end
        end
      end
      @parent_is_updating=false
    end
  end
  def clean_up_parents()
    unless $campaign==nil
      eval("$campaign."+@handler+"s.select{|place|place.parent!=nil}").each() do |item|

        if  eval("$campaign."+@handler+"s.select{|parent_item|parent_item.name==item.parent}").length==0
          item.parent=nil
        end
      end
    end
  end
  def configure
    super
    parent_listner=RubySwingActionListener.new do |evt|
      if @selected!=nil and !@parent_is_updating
        if @panel.parent_chooser.get_selected_item=="None"
          @selected.parent=nil
        else
          @selected.parent=@panel.parent_chooser.get_selected_item
        end
        clean_up_parents()
        update_tree
      end
    end
    @panel.parent_chooser.add_action_listener(parent_listner)
  end
  def do_update_tree()
    clean_up_parents()
    chosen=nil
    model=@panel.item_tree.get_model()
    model.root.removeAllChildren()
    unless $campaign==nil
      unallocated_items=eval("$campaign.#{@handler.downcase}s").clone
      allocated_items={}
      while unallocated_items.length>0
        toremove=[]
        unallocated_items.each() do |item|
          if item.parent==nil
            node=org.rubyforge.fudger.ExtraDataTreeNode.new(item.name)
            node.setExtraData(item)
            model.root.add(node)
            allocated_items[item.name]=node
            toremove<<item
          else
            if allocated_items.include?(item.parent)
              node=org.rubyforge.fudger.ExtraDataTreeNode.new(item.name)
              node.setExtraData(item)
              allocated_items[item.parent].add(node)
              allocated_items[item.name]=node
              toremove<<item
              if item==@selected
                patharray=allocated_items[item.parent].get_path()
                #No idea why this is neccessary, but I can't use the patharray directly...
                temparray=[]
                patharray.each() do |p|
                  temparray<<p
                end
                chosen=javax.swing.tree.TreePath.new(temparray.to_java)
              end
            end
          end
        end
        if toremove.length==0
          unallocated_items.each do |item|
            puts "Error with #{item.name} parent:#{item.parent}."
          end
          raise Exception.new("Can't place all items")
        end
        toremove.each do|item|
          unallocated_items.delete(item)
        end
      end
    end
    model.reload
    unless chosen==nil
      @panel.item_tree.expand_path(chosen)
    end
  end
end
