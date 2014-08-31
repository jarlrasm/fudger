
class CampaignElement
  include GetText
  def self.fudger_campaign_accessor(varnames)
    varnames.each do |var|
      _fudger_campaign_accessor(var)
    end
  end
  def self._fudger_campaign_accessor(varname)
    self.class_eval("def #{varname}
      return @#{varname}
      end")
    self.class_eval("def #{varname}=(var)
      unless @#{varname}==var
      @#{varname}=var
      project_changed(true)
      end
      end")

  end
	fudger_campaign_accessor [:type, :description]
  def check_if_name_exist?(n)
    @@all_classes.each do|klass|
      if eval("$campaign.#{klass.name.downcase}s").select{|item|item.name==n}.length>0
        return true unless eval("$campaign.#{klass.name.downcase}s").select{|item|item.name==n}[0]==self
      end
    end
    false
  end
  def self.create(klass)
    if klass==Character
      char=Character.new($campaign.system)
      if FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_QUESTION,_("Male character?"))
        name=$male_character_name_generator.get_name
      else
        name=$female_character_name_generator.get_name
        char.gender=1
      end
      if(name!=nil)
        char.name=name
      end
      return char
    end
    if klass==Place
      place=Place.new()
      if $use_place_name_generator
        name=$place_name_generator.get_name
        if(name!=nil)
          place.name=name
        end
      end
      return place
    end
    return klass.new()
  end
  def set_name(n)
    if $campaign==nil
      return n
    end
    if check_if_name_exist?(n)
      n=n+"1"
      while check_if_name_exist?(n)
        n=n.next
      end
    end
    @name=n
    project_changed
  end
  def name=(n)
    set_name(n)
  end
  def name
    @name
  end
  @@all_classes=[]
  def initialize
    unless @@all_classes.include?self.class
      load_class
    end
    @description=_("Add description here")
    set_name _("noname")
    
  end
  def load_class
    #witness the power of ruby!
    @@all_classes<<self.class
    @@all_classes.each() do|klass|
      if(!self.class.method_defined?("related_"+klass.name.downcase+"s"))
        self.class.class_eval("def related_"+klass.name.downcase+"s
            elements=[]
            $campaign."+klass.name.downcase+"s.each() do |elem|
              if elem!=self
                if @description.slice(elem.name)!=nil
                  elements+=[elem]
                else
                  if elem.description.slice(@name)!=nil
                    elements+=[elem]
                  end
                end
              end
            end
            return elements
            end
          ")
      end
      if(!klass.method_defined?("related_"+self.class.name.downcase+"s"))
        klass.class_eval("def related_"+self.class.name.downcase+"s
            elements=[]
            $campaign."+self.class.name.downcase+"s.each() do |elem|
              if elem!=self
                if @description.slice(elem.name)!=nil
                  elements+=[elem]
                else
                  if elem.description.slice(@name)!=nil
                    elements+=[elem]
                  end
                end
              end
            end
            return elements
            end
          ")
      end

    end
  end
end
