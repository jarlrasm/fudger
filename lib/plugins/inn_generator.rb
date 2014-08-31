class InnGenerator<Plugin
  def initialize()
    super "Sveinung F.","0.2"
    require_fudger_version("0.2")
  end
  def create
    $user_interface.add_generator("Inn") do
      generate
    end
    @name_generator=NameGenerator.new("inn")
  end
  def generate(update=true)
    fame=["cheap beer", "rowdy crowds", "soft beds", "good food","lousy service","late nights"]
    place=Place.new
    place.type=_("Bar")
    name=@name_generator.get_name_from_file("fantasy_inn.yml")
    unless name==nil
      place.name=name
    end
    desc="A place for locals to drink and travelers to rest."
    n_fame=rand(3)
    if n_fame==1
      desc+=" Famous for its %s."%fame[rand(fame.length)]
    end
    if n_fame==2
      fame1=fame[rand(fame.length)]
      fame2=fame[rand(fame.length)]
      while fame2==fame1
        fame2=fame[rand(fame.length)]
      end
      desc+=" Famous for its %s and %s."%[fame1,fame2]
    end
    place.description=desc
    $campaign.places<<place
    person=Character.new()
    #most likely not a female innkeeper.
    name=$male_character_name_generator.get_name
    if rand(4)==0
      person.gender=1
      name=$female_character_name_generator.get_name
    end
    if(name!=nil)
      person.name=name
    end
    person.age=rand(30)+30
    person.description="The innkeeper at #{place.name}."
    $campaign.characters<<person
    if update
      project_changed
      $user_interface.update_all
      $user_interface.select(place)
    end
    return place
  end
end
