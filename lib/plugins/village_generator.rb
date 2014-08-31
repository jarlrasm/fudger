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
class VillageGenerator < Plugin
  def initialize()
    super "Sveinung F.","0.2"
    require_fudger_version("0.2")
    plugin_require("TempleGenerator","0.1")
    plugin_require("InnGenerator","0.1")
  end
  def create
    $user_interface.add_generator("Fantasy Village") do
      generate
    end
  end
  def build_village_dialog
    begin
      dialog=Gtk::Dialog.new(_("Generate village"),nil,nil,[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
      areacombo=Gtk::ComboBox.new()
      areacombo.append_text("Plains")
      areacombo.append_text("Seaside")
      areacombo.append_text("Mountains")
      areacombo.append_text("Desert")
      areacombo.append_text("Forest")
      areacombo.active=0
      dialog.vbox.pack_start(areacombo,false,false)
      relcombo=Gtk::ComboBox.new()
      relcombo.append_text("Any")
      $campaign.religions.select{|rel|rel.illegal==false}.each do |religion|
        relcombo.append_text(religion.name)
      end
      relcombo.active=0
      dialog.vbox.pack_start(relcombo,false,false)
      dialog.vbox.show_all
      dialog.run
      area_type=areacombo.active_text
      religion=nil
      if relcombo.active_text!="Any"
        religion=$campaign.religions.select{|rel|rel.name==relcombo.active_text}[0]
      end
      dialog.destroy
    rescue
      religon=nil
      area_types=["Plains","Seaside","Mountains","Desert","Forest"]
      religions=$campaign.religions.select{|rel|rel.illegal==false}
      area_type=area_types[rand(area_types.length)]
      if religions.length>0
        religion=religions[rand(religions.length)]
      end
    end
    return area_type, religion
  end
  def get_economy(area_type)
    econ={}
    econ["Plains"]=[[95,"farming"],[5,"trading"]]
    econ["Seaside"]=[[20,"farming"],[5,"trading"],[75,"fishing"]]
    econ["Mountains"]=[[20,"farming"],[5,"trading"],[75,"mining"]]
    econ["Desert"]=[[100,"trading"]]
    econ["Forest"]=[[50,"forest"],[50,"fur-trapping"]]
    which=rand(100)
    econ[area_type].each do |eco|
      which-=eco[0]
      if which<1
        return eco[1]
      end
    end
  end
  def get_fame(econ)
    fame={}
    fame["farming"]=["giant watermelons","strong liquor","fine wine","beautiful scenery"]
    fame["mining"]=["strong steel","beautiful scenery","rich gold-mines"]
    fame["fishing"]=["shark-fins","shrimps","salmon","lobsters","beautiful scenery"]
    fame["trading"]=["pottery","rich traders","fine cloth","beautiful scenery"]
    fame["forest"]=["fine furniture","giant trees","beautiful scenery"]
    fame["fur-trapping"]=["fine coats","giant trees","beautiful scenery"]
    n_fame=rand(3)
    if n_fame==1
      return" Famous for its %s."%fame[econ][rand(fame[econ].length)]
    end
    if n_fame==2
      fame1=fame[econ][rand(fame[econ].length)]
      fame2=fame[econ][rand(fame[econ].length)]
      while fame2==fame1
        fame2=fame[econ][rand(fame[econ].length)]
      end
      return " Famous for its %s and %s."%[fame1,fame2]
    end
    return ""
  end
  def generate(update=true)
    area_type,religion=build_village_dialog
    village=Place.new
    village.type=_("Village")
    name=$place_name_generator.get_name
    if(name!=nil)
      village.name=name
    end
    econ=get_economy(area_type)
    population=rand(400)+100
    desc="[public]%s is a %s town of %i people.%s[/public]"%[village.name,econ,population,get_fame(econ)]
    village.description=desc
    $campaign.places<<village
    inn=Plugin.all_plugins["InnGenerator"].generate(false)
    inn.parent=village.name
    temple=Plugin.all_plugins["TempleGenerator"].generate(false,religion,true)
    temple.parent=village.name
    create_major(village)
    create_blacksmith(village,econ)
    create_store(village,econ)
    3.times do
      generate_attraction(village,econ)
    end
    create_gossipmonger(village)
    create_idiot(village)
    if update
      project_changed
      $user_interface.update_all
      $user_interface.select(village)
    end
    return village
  end
  def create_store(village,econ)
    likely={}
    likely["farming"]=20
    likely["trading"]=100
    likely["fishing"]=30
    likely["mining"]=20
    likely["forest"]=20
    likely["fur-trapping"]=20
    if rand(100)>likely[econ]
      return
    end
    place=Place.new
    place.type=_("Store")
    place.name=village.name+" General Store"
    place.description="Here anything can be bougth"
    place.parent=village.name
    $campaign.places<<place
    person=Character.new()
    name=$male_character_name_generator.get_name
    if(name!=nil)
      person.name=name
    end
    person.age=rand(30)+30
    person.description="Storekeeper of #{place.name}."
    $campaign.characters<<person
  end
  def create_blacksmith(village,econ)
    likely={}
    likely["farming"]=60
    likely["trading"]=30
    likely["fishing"]=50
    likely["mining"]=80
    likely["forest"]=50
    likely["fur-trapping"]=50
    if rand(100)>likely[econ]
      return
    end
    place=Place.new
    place.type=_("Blacksmith")
    place.name=village.name+" Hardware"
    place.description="A local blacksmith with a store."
    place.parent=village.name
    $campaign.places<<place
    person=Character.new()
    name=$male_character_name_generator.get_name
    if(name!=nil)
      person.name=name
    end
    person.age=rand(30)+30
    person.description="The blacksmith of #{place.name}."
    $campaign.characters<<person
  end
  def create_major(village)
    person=Character.new()
    #most likely not a female major. Will the feminists hate me for this?
    name=$male_character_name_generator.get_name
    if rand(3)==0
      person.gender=1
      name=$female_character_name_generator.get_name
    end
    if(name!=nil)
      person.name=name
    end
    person.age=rand(30)+40
    person.description="The major of #{village.name}."
    $campaign.characters<<person
  end
  def create_idiot(village)
    if rand(100)>20
      return
    end
    person=Character.new()
    name=$male_character_name_generator.get_name

    if(name!=nil)
      person.name=name
    end
    person.age=rand(50)+20
    person.description="The village idiot of #{village.name}."
    $campaign.characters<<person
  end
  def generate_attraction(village,econ)
    if rand(100)>30
      return
    end
    temple_name_generator=NameGenerator.new("temple")
    attr={}
    attr["farming"]=[[30,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [20,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [50,"Famous farmers market. Here you can get all your vegetables and meats.","#{village.name} market"]]
    attr["trading"]=[[30,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [20,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [50,"Famous market. Here you can get everything.","#{village.name} market"]]
    attr["mining"]=[[30,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [20,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [50,"Closed mine. Locals stay away...","#{$male_character_name_generator.get_name}'s mine"]]
    attr["fishing"]=[[30,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [20,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [50,"Famous fishers market. Here you can get all your seafood.","#{village.name} market"]]
    attr["forest"]=[[30,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [20,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [50,"Old hunting lodge.","#{$male_character_name_generator.get_name}'s Lodge"]]
    attr["fur-trapping"]=[[10,"An old temple ruin outside #{village.name}","Ruins of #{temple_name_generator.get_name_from_file("fantasy_temple.yml")}"],
      [10,"A statue a famous general","Statue of #{$male_character_name_generator.get_name}"],
      [40,"Old hunting lodge.","#{$male_character_name_generator.get_name}'s Lodge"],
      [40,"Fur market.","#{village.name} market"]]
    which=rand(100)
    attr[econ].each do |attraction|
      which-=attraction[0]
      if which<1
        place=Place.new
        place.type="Attraction"
        place.description=attraction[1]
        place.name=attraction[2]
        place.parent=village.name
        $campaign.places<<place
        return
      end
    end
  end
  def create_gossipmonger(village)
    if rand(100)>20
      return
    end
    rel_char=village.related_characters
    village.get_children.each do |child|
      rel_char+=child.related_characters
    end
    about=rel_char[rand(rel_char.length)]
    rumours=["the infidelity of #{about.name}",
      "the moral corruption of #{about.name}",
      "the lost love of #{about.name}",
      "marital problems of #{about.name}"
    ]
    person=Character.new()
    #I don't feel like being PC today. The gossipmonger is ALWAYS an old woman
    person.gender=1
    name=$female_character_name_generator.get_name
    if(name!=nil)
      person.name=name
    end
    person.age=rand(30)+60
    desc="Gossipmonger in #{village.name}. She can tell you all about #{rumours[rand(rumours.length)]}."

    person.description=desc
    $campaign.characters<<person
  end
end
