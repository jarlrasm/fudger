
class TempleGenerator<Plugin
  def initialize()
    super "Sveinung F.","0.2"
    require_fudger_version("0.2")
  end
  def create
    $user_interface.add_generator("Temple") do
      generate
    end
    $user_interface.add_generator("Illegal Temple") do
      generate(true,nil,false)
    end
  end
  def pick_religion(religion,legal)
    if religion==nil
      array=$campaign.religions.select{|rel|rel.illegal!=legal}
      if array.length==0
        return nil
      end
      return array[rand(array.length)]
    end
    legalchildren=religion.get_children.select{|rel|rel.illegal!=legal}
    if rand(100)<30 or legalchildren.length==0
      return religion
    end
    return pick_religion(legalchildren[rand(legalchildren.length)],legal)
  end
  def generate(update=true,religion=nil,legal=true)
    religion=pick_religion(religion,legal)
    place=Place.new
    place.type=_("Temple")
    place.name="Unnamed Temple"
    unless religion==nil
      place.name=religion.get_temple_name
    end
    place.description="The local temple"
    if religion!=nil
      place.description<<" of "+religion.name
    end
    place.description<<"."
    $campaign.places<<place
    (rand(2)+1).times do
      person=Character.new()
      #most likely not a female priest.
      name=$male_character_name_generator.get_name
      if rand(3)==0
        person.gender=1
        name=$female_character_name_generator.get_name
      end
      if(name!=nil)
        person.name=name
      end
      person.age=rand(30)+30
      person.description="Priest at #{place.name}."
      if religion!=nil
        person.description="Priest of #{religion.name} at #{place.name}."
      else
        person.description="Priest at #{place.name}."
      end
      $campaign.characters<<person
    end
    if update
      project_changed
      $user_interface.update_all
      $user_interface.select(place)
    end
    return place
  end
end