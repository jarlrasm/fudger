require 'ui/fudger-gtk/base_ui'
class WithParentUi<BaseUi
  def initialize
    super
    $user_interface.builder[@handle_string+"_parent_chooser"].signal_connect("changed") do
      parent_changed unless @parent_chooser_is_updating
    end
    @parent_chooser_is_updating=false
  end
  def remove_selected
    if @selected!=nil
      eval("$campaign."+@handle_string+"s.delete(@selected)")
      @selected=nil
      clean_up_parents
      update_chooser_list()
    end
    project_changed
  end
  def parent_changed()
    parent_name=$user_interface.builder[@handle_string+"_parent_chooser"].model.get_value($user_interface.builder[@handle_string+"_parent_chooser"].active_iter,0)
    if(parent_name!="None")
      unless @selected.parent==parent_name
        @selected.parent=parent_name
      end
    else
      unless @selected.parent==nil
        @selected.parent=nil
      end
    end
    item=@selected
    update_chooser_list()
    select(item)
  end
  def do_select()
    super
    populate_parent_chooser()
  end
  def populate_parent_chooser()
    @parent_chooser_is_updating=true
    model=Gtk::ListStore.new(String)
    iter=model.append()
    model.set_value(iter,0,"None")
    i=1
    chosen=0
    eval("$campaign."+@handle_string+"s").each() do |item|
      if(item!=@selected) and !@selected.is_ancestor_of?(item)
        iter=model.append()
        model.set_value(iter,0,item.name)
        if(item.name==@selected.parent)
          chosen=i
        end
        i+=1
      end
    end
    chooser=$user_interface.builder[@handle_string+"_parent_chooser"]
    chooser.model=model
    cell_renderer=Gtk::CellRendererText.new
    chooser.clear
    chooser.pack_start(cell_renderer,true)
    chooser.set_attributes(cell_renderer,:text=>0)
    chooser.active=chosen
    @parent_chooser_is_updating=false
  end
  def clean_up_parents()
    unless $campaign==nil
    eval("$campaign."+@handle_string+"s.select{|place|place.parent!=nil}").each() do |item|
      if  eval("$campaign."+@handle_string+"s.select{|parent_item|parent_item.name==item.parent}").length==0
        item.parent=nil
      end
    end
    end
  end
	#TODO split up function...
  def update_chooser_list()
    list=$user_interface.builder[@handle_string+"_list"]
    clean_up_parents()
    iters={}
    unset=eval("$campaign."+@handle_string+"s.clone")
    toremove=[]
    list.model.each() do |model,path,iter|
      item=model.get_value(iter,1)
      if !eval("$campaign."+@handle_string+"s").include?(item)
        toremove<<iter
      else
        if item.parent!=nil
          if iter.parent==nil
            toremove<<iter
          elsif model.get_value(iter.parent,1).name!=item.name
            toremove<<iter
          else
            unset-=[item]
            iters[item.name]=iter
          end
        elsif iter.parent!=nil
          toremove<<iter
        else
          unset-=[item]
          iters[item.name]=iter
        end
      end
    end
    while toremove.length>0
      toremove.each do |iter|
        unless iter.has_child?
          list.model.remove(iter)
          toremove-=[iter]
        end
      end
    end
    while unset.length>0
      unset.each() do |item|
        if item.parent==nil
          iter=list.model.append(nil)
          list.model.set_value(iter,0,item.name)
          list.model.set_value(iter,1,item)
          iters[item.name]=iter
          unset-=[item]
        else
          if iters.include?(item.parent)
            iter=list.model.append(iters[item.parent])
            list.model.set_value(iter,0,item.name)
            list.model.set_value(iter,1,item)
            iters[item.name]=iter
            unset-=[item]
          end
        end
      end
    end
  end
end
