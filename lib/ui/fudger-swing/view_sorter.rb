module ViewSorter
  def sort_by_attribute(list,klass,attr,translator_array)
    if $campaign==nil
      return
    end
    nodes = set_up_parent_iters(list, translator_array)
    put_characters_to_attributes(attr, nodes, klass, list,translator_array)
  end
  private
  def put_characters_to_attributes(attr, nodes, klass, list,translator_array)
    toremove=[]
    eval("$campaign.#{klass.name.downcase}s").each do |item|
      allready=false
      list.model.root.children.each do |parent_node|
        parent_node.children.each do |node|
          if node.to_s==item.name
            if parent_node!=nodes[eval("item.#{attr}")]
              toremove<<node
            else
              allready=true
            end
          end
        end
      end
      unless allready
        node=org.rubyforge.fudger.ExtraDataTreeNode.new(item.name)
        node.setExtraData(item)
        nodes[eval("item.#{attr}")].add(node)
      end

    end
    #remove old stuff
    list.model.root.children.each do |parent_node|
      parent_node.children.each do |node|
        if !eval("$campaign.#{klass.name.downcase}s.include?(node.get_extra_data)")
          toremove<<node
        end
      end
    end
    toremove.each do |iter|
      list.model.removeNodeFromParent(iter)
    end
    toremove=[]
    list.model.root.children.each do |node|
      unless translator_array.select{|s|_(s)==node.to_s}.length>0
        toremove<<node
      end
    end
    toremove.each do |iter|
      list.model.removeNodeFromParent(iter)
    end
  end

  def set_up_parent_iters(list, translator_array)
    nodes=[]
    i=0
    translator_array.each do |translated|
      nodes[i]=nil
      list.model.root.children.each() do |node|
        if node.to_string==_(translated)
          nodes[i]=node
        end
      end
      if nodes[i]==nil
        nodes[i]=org.rubyforge.fudger.ExtraDataTreeNode.new(_(translated))
        list.model.root.add(nodes[i])
      end
      i+=1
    end
    return nodes
  end
  public
  def sort_by_related(list,klass,sortklass)
    if $campaign==nil
      return
    end
    sortklasselements = find_sort_klass_elements(klass,sortklass)
    model=list.model
    remove_old_stuff_from_model(model,klass,sortklass,sortklasselements)
    add_stuff_to_model(list,klass,sortklass,sortklasselements)
    handle_unknown(list,klass,sortklass)
  end
  private
  #TODO Too big function
  def add_stuff_to_model(list,klass,sortklass,sortklasselements)
    model=list.model
    placeiters={}
    finished=false
    while !finished
      finished=true
      if sortklass.superclass==ElementWithParent
        sortklasselements.each do |place|
          if place.parent==nil
            placeiters[place]= create_and_get_sort_node(list, place,nil)
            eval("$campaign.#{klass.name.downcase}s").each do |char|
              if eval("char.related_#{sortklass.name.downcase}s.include?(place)")
                create_and_get_node(list, placeiters[place],char)
              else
                model.removeNodeFromParent(create_and_get_node(list, placeiters[place],char))
              end
            end
          else
            parent=eval("$campaign.#{sortklass.name.downcase}s.select() {|pl| pl.name==place.parent}[0]")
            if placeiters.include?(parent)
              placeiters[place]= create_and_get_sort_node(list, place,placeiters[parent])
              eval(" $campaign.#{klass.name.downcase}s").each do |char|
                if eval("char.related_#{sortklass.name.downcase}s.include?(place)")
                  create_and_get_node(list, placeiters[place],char)
                else
                  model.removeNodeFromParent(create_and_get_node(list, placeiters[place],char))
                end
              end
            else
              finished=false
            end
          end
        end
      else

        sortklasselements.each do |place|
          placeiters[place]= create_and_get_sort_node(list, place,nil)
          eval("$campaign.#{klass.name.downcase}s").each do |char|
            if eval("char.related_#{sortklass.name.downcase}s.include?(place)")
              create_and_get_node(list, placeiters[place],char)
            else
              model.removeNodeFromParent(create_and_get_node(list, placeiters[place],char))
            end
          end
        end
      end
    end

  end
  def handle_unknown(list,klass,sortklass)
    #deal with unrelated stuff
    model=list.model
    unknowniter=nil
    list.model.root.children.each do |node|
      if node.to_s==_("Unknown") and node.get_parent==list.model.root
        unknowniter=node
      end
    end
    if unknowniter==nil
      unknowniter=org.rubyforge.fudger.ExtraDataTreeNode.new(_("Unknown"))
      list.model.root.add(unknowniter)
    end
    tokeep=[]
    toremove=[]
    list.model.root.children.each do |parent_node|
      parent_node.children.each do |node|
        if parent_node==unknowniter
          item=node.get_extra_data
          if !eval("$campaign.#{klass.name.downcase}s.include?(item)") or eval("item.related_#{sortklass.name.downcase}s.length>0")
            toremove+=[node]
          else
            tokeep+=[item]
          end
        end
      end
    end
    toremove.each do |iter|
      model.removeNodeFromParent(iter)
    end
    eval("$campaign.#{klass.name.downcase}s").each() do |item|
      if eval("item.related_#{sortklass.name.downcase}s.empty?") and !tokeep.include?(item)
        node=org.rubyforge.fudger.ExtraDataTreeNode.new(item.name)
        node.setExtraData(item)
        unknowniter.add(node)
      end
    end
  end

  def find_sort_klass_elements(klass,sortklass)
    if $campaign==nil
      return
    end
    sortklasselements=eval("$campaign.#{sortklass.name.downcase}s.select() {|item| item.related_#{klass.name.downcase}s.length>0}")

    if sortklass.superclass==ElementWithParent
      add_items=[]
      #find places with correct parents that are not included
      finished=false
      while !finished
        finished=true
        sortklasselements.each do |item|
          if item.parent!=nil
            parent=eval("$campaign.#{sortklass.name.downcase}s.select() {|pl| pl.name==item.parent}[0]")
            if !sortklasselements.include?(parent) and !add_items.include?(parent)
              add_items<<parent
              finished=false
            end
          end
        end
        sortklasselements+=add_items
      end
    end
    return sortklasselements
  end

  def remove_recursively_from_model(iter, model)
    if(iter.get_parent==nil)
      return
    end
    iter.children.each do |child|
      remove_recursively_from_model(child, model)
    end
    model.removeNodeFromParent(iter)
  end
  def create_and_get_node(list,iter,char)
    iter.children.each do |node|
      if node.get_extra_data==char
        return node
      end
    end
    node=org.rubyforge.fudger.ExtraDataTreeNode.new(char.name)
    node.setExtraData(char)
    iter.add(node)
    return node
  end

  def create_and_get_sort_node(list,place,iter)
    if(iter==nil)
      iter=list.model.root
    end
    iter.children.each do |node|
      if node.to_s==place.name
        return node
      end
    end
    node=org.rubyforge.fudger.ExtraDataTreeNode.new(place.name)
    iter.add(node)
    return node
  end
  def get_all_nodes(model,node)
    nodes=[]
    node.children.each do |child_node|
      nodes<<child_node
      nodes+=get_all_nodes(model,child_node)
    end
    return nodes
  end
  def remove_old_stuff_from_model(model,klass,sortklass,places_with_characters)
    toremove=[]
    #remove outdated things
    nodes=get_all_nodes(model,model.root)
    nodes.each do |iter|
      name=iter.to_s
      char=iter.get_extra_data
      if char==nil #sortnode
        place=eval("$campaign.#{sortklass.name.downcase}s").select() {|pl| pl.name==name}[0]
        if name==_("Unknown")
          next
        end
        if (!places_with_characters.include?(place) or place==nil)
          toremove<<iter
        else
          if iter.get_parent==nil
            if place.is_a?(ElementWithParent)
              if place.parent!=nil
                toremove<<iter
              end
            end
          else
            if iter.get_parent.to_s!=place.parent
              toremove<<iter
            end
          end
        end
      else
        if iter.get_parent==nil
          toremove<<iter
          next
        end
        parent_name=iter.get_parent.to_s
        if parent_name==_("Unknown")
          next
        end
        if eval("char.related_#{sortklass.name.downcase}s").select {|place|place.name==parent_name}.length==0
          toremove<<iter
        end
        if !eval("$campaign.#{klass.name.downcase}s.include?(char)")
          toremove<<iter
        end
      end
    end
    toremove.each do |iter|
      remove_recursively_from_model(iter, model)
    end
  end

end
