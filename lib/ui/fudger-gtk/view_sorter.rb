module ViewSorter
  def sort_by_attribute(list,klass,attr,translator_array)
    iters = set_up_parent_iters(list, translator_array)
    put_characters_to_attributes(attr, iters, klass, list)
  end
  private
  def put_characters_to_attributes(attr, iters, klass, list)
    toremove=[]
    eval("$campaign.#{klass.name.downcase}s").each do |item|
      allready=false
      list.model.each do |model,path,iter|
        if model.get_value(iter,0)==item.name
          if iter.parent!=iters[eval("item.#{attr}")]
            toremove<<iter
          else
            allready=true
          end
        end
      end
      unless allready
        iter=list.model.append(iters[eval("item.#{attr}")])
        list.model.set_value(iter,0,item.name)
        list.model.set_value(iter,1,item)
      end

    end
    toremove.each do |iter|
      list.model.remove(iter)
    end
  end

  def set_up_parent_iters(list, translator_array)
    iters=[]
    i=0
    translator_array.each do |translated|
      iters[i]=nil
      list.model.each do |model,path,iter|
        if model.get_value(iter,0)==_(translated) and iter.parent==nil
          iters[i]=iter
        end
      end
      if iters[i]==nil
        iters[i]=list.model.prepend(nil)
        list.model.set_value(iters[i],0,translated)
        list.model.set_value(iters[i],1,nil)
      end
      i+=1
    end
    return iters
  end
  public
  def sort_by_related(list,klass,sortklass)
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
                model.remove(create_and_get_node(list, placeiters[place],char))
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
                  model.remove(create_and_get_node(list, placeiters[place],char))
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
              model.remove(create_and_get_node(list, placeiters[place],char))
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
    list.model.each do |model,path,iter|
      if model.get_value(iter,0)==_("Unknown") and iter.parent==nil
        unknowniter=iter
      end
    end
    tokeep=[]
    toremove=[]
    list.model.each do |model,path,iter|
      if iter.parent==unknowniter
        item=list.model.get_value(iter,1)
        if !eval("$campaign.#{klass.name.downcase}s.include?(item)") or eval("item.related_#{sortklass.name.downcase}s.length>0")
          toremove+=[iter]
        else
          tokeep+=[item]
        end
      end
    end
    toremove.each do |iter|
      model.remove(iter)
    end
    eval("$campaign.#{klass.name.downcase}s").each() do |item|
      if eval("item.related_#{sortklass.name.downcase}s.empty?") and !tokeep.include?(item)
        iter=model.append(unknowniter)
        model.set_value(iter,0,item.name)
        model.set_value(iter,1,item)
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
    unless model.iter_is_valid?(iter)
      return
    end
    while iter.has_child?
      remove_recursively_from_model(iter.first_child, model)
    end
    model.remove(iter)
  end
  def create_and_get_node(list,iter,char)
    list.model.each do |model,path,iter2|
      if iter2.parent==iter
        if model.get_value(iter2,1)==char
          return iter2
        end
      end
    end
    iter=list.model.append(iter)
    list.model.set_value(iter,0,char.name)
    list.model.set_value(iter,1,char)
    return iter
  end
  def create_and_get_sort_node(list,place,iter)
    list.model.each do |model,path,iter2|
      if iter2.parent==iter
        if model.get_value(iter2,0)==place.name
          return iter2
        end
      end
    end
    iter2=list.model.append(iter)
    list.model.set_value(iter2,0,place.name)
    list.model.set_value(iter2,1,nil)
    return iter2
  end
  def remove_old_stuff_from_model(model,klass,sortklass,places_with_characters)
    toremove=[]
    #remove outdated things
    model.each do |model,path,iter|
      name=model.get_value(iter,0)
      char=model.get_value(iter,1)
      if char==nil #sortnode
        place=eval("$campaign.#{sortklass.name.downcase}s").select() {|pl| pl.name==name}[0]
        if name==_("Unknown")
          next
        end
        if (!places_with_characters.include?(place) or place==nil)
          toremove<<iter
        else
          if iter.parent==nil
            if place.is_a?(ElementWithParent)
              if place.parent!=nil
                toremove<<iter
              end
            end
          else
            if model.get_value(iter.parent,0)!=place.parent
              toremove<<iter
            end
          end
        end
      else
        if iter.parent==nil
          toremove<<iter
          next
        end
        parent_name=model.get_value(iter.parent,0)
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
