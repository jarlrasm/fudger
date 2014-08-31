require 'gtk2'
require 'ui/fudger-gtk/html_viewer'
require 'ui/fudger-gtk/splash'
require 'ui/fudger-gtk/texttagger'
require 'ui/fudger-gtk/character_ui'
require 'ui/fudger-gtk/item_ui'
require 'ui/fudger-gtk/place_ui'
require 'ui/fudger-gtk/event_ui'
require 'ui/fudger-gtk/image_ui'
require 'ui/fudger-gtk/religion_ui'
require 'ui/fudger-gtk/creature_ui'
require 'ui/fudger-gtk/other_ui'
class UserInterface
  attr_reader :builder
  attr_accessor :character_ui,:place_ui,:item_ui,:event_ui,:image_ui,:creature_ui,:religion_ui,:other_ui
  def initialize()
    load_ui
    set_up_page_chooser
  end
  def run
    @builder["mainwindow"].show_all
    Gtk.main

  end
  def populate_system_chooser
    model=Gtk::ListStore.new(String)
    active=0
    i=0
    $systems.each_pair do |key,value|
      iter=model.append
      model.set_value(iter,0,key)
      if key==$campaign.system
        active=i
      end
      i+=1
    end
    chooser=@builder["system_chooser"]
    chooser.model=model
    cell_renderer=Gtk::CellRendererText.new
    chooser.clear
    chooser.pack_start(cell_renderer,true)
    chooser.set_attributes(cell_renderer,:text=>0)
    chooser.active=active

  end
  def reset_ui
    @character_ui.system_changed
    @creature_ui.system_changed
    @builder["overview"].buffer.text=$campaign.overview
    @character_ui.clean_chooser_list
    BaseUi.clean_all_views
    @builder["overview"].buffer.text=$campaign.overview
  
  end
  def update_and_select(item)
    eval("@#{item.class.name.downcase}_ui.update_chooser_list()")
    select(item)
  end
  def select(item)
    eval("@#{item.class.name.downcase}_ui.select(item)")
    eval("@builder['#{item.class.name.downcase}_name_input'].grab_focus")
  end
  def open_file()
    dialog = Gtk::FileChooserDialog.new(_("Open File"),
      @builder["mainwindow"],
      Gtk::FileChooser::ACTION_OPEN,
      nil,
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    filter=Gtk::FileFilter.new
    filter.name=_("Fudger files")
    filter.add_pattern("*.fudger")
    dialog.add_filter(filter)
    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      Gtk::RecentManager.default.add_item(dialog.uri)
      load_file(dialog.filename)
    end
    dialog.destroy
  end
  def keep_stuff_in_front_and_active
    @builder["main_notebook"].page=1
    @builder["close_action"].sensitive=true
    @builder["save_action"].sensitive=true
    @builder["save_as_action"].sensitive=true
    @builder["report_action"].sensitive=true
    @builder["properties_action"].sensitive=true
    @builder["generator_menu_item"].sensitive=true
  end
  def do_project_changed(changed=true)
    keep_stuff_in_front_and_active

    if changed
      @builder["save_action"].sensitive=true
    else
      @builder["save_action"].sensitive=false

    end
    if($campaign.is_a?(Campaign))
      n_elements=$campaign.characters.length+$campaign.places.length+$campaign.items.length+$campaign.events.length+$campaign.images.length+$campaign.others.length
      @builder["campaign_name_label"].text=_("Campaign: %s, Characters: %i, Total Elements: %i")% [$campaign.name,$campaign.characters.length,n_elements]

    end
  end
  def save_as
    dialog = Gtk::FileChooserDialog.new(_("Save File"),
      @builder["mainwindow"],
      Gtk::FileChooser::ACTION_SAVE,
      nil,
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT])
    filter=Gtk::FileFilter.new
    filter.name=_("Fudger files")
    filter.add_pattern("*.fudger")
    dialog.add_filter(filter)
    dialog.current_name=$campaign.name+".fudger"
    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      save_file(dialog.filename)
      Gtk::RecentManager.default.add_item(dialog.uri)
    end
    dialog.destroy
  end
  def load_ui
    @builder=Gtk::Builder.new
    @builder.set_translation_domain("fudger_ui")
    @builder<<File.dirname(__FILE__)+"/fudger.ui"
    @builder["mainwindow"].signal_connect("delete_event") do
      window_closed
    end
    @builder["mainwindow"].signal_connect("destroy") do
      Gtk.main_quit
    end
  end
  def configure_ui
    create_properties_dialog()
    build_uis
    build_recent_chooser
    connect_signals
  end
  def build_recent_chooser
    recent_chooser_menu=Gtk::RecentChooserMenu.new()
    filter=Gtk::RecentFilter.new
    filter.add_pattern("*.fudger")
    recent_chooser_menu.add_filter(filter)
    @builder["recent_menu"].submenu=recent_chooser_menu
    recent_chooser_menu.signal_connect("item-activated") do |chooser|
      recent_chooser_activated(chooser)
    end
  end
def overview_changed()
  unless $campaign.overview==@overviewtagger.serialize()
    $campaign.overview=@overviewtagger.serialize()
    project_changed
  end
end

  def show_preferences
    @builder["generate_place_name_button"].active=$use_place_name_generator
    @builder["generate_character_name_button"].active=$use_character_name_generator
    @builder["public_tag_colorbutton"].color=Gdk::Color.parse($public_tag_color)
    @builder["link_colorbutton"].color=Gdk::Color.parse($link_color)
    if @builder["preferences_dialog"].run == Gtk::Dialog::RESPONSE_OK
      $use_place_name_generator=@builder["generate_place_name_button"].active?
      $use_character_name_generator=@builder["generate_character_name_button"].active?
      $public_tag_color=@builder["public_tag_colorbutton"].color.to_s
      $link_color=@builder["link_colorbutton"].color.to_s
      @overviewtagger.update_tag_colors
      BaseUi.all_views.each_pair do |key,view|
        view.tagger.update_tag_colors
      end
      save_settings
    end
    @builder["preferences_dialog"].hide
  end
  def populate_name_generators_chooser(name_type)
    model=Gtk::ListStore.new(String)
    iter=model.append()
    model.set_value(iter,0,name_type.capitalize+" names")
    i=1
    chosen=0
    gens=get_name_generators(name_type)
    gens.each  do |generator|
      iter=model.append()
      model.set_value(iter,0,generator)
      if(generator==eval("$campaign."+name_type+"_name_generator"))
        chosen=i
      end
      i+=1
    end

    chooser=  @builder[name_type+"_name_box"]
    chooser.model=model
    cell_renderer=Gtk::CellRendererText.new
    chooser.clear
    chooser.pack_start(cell_renderer,true)
    chooser.set_attributes(cell_renderer,:text=>0)
    chooser.active=chosen

  end
  def campaign_closed
    @builder["main_notebook"].page=0
    @builder["close_action"].sensitive=false
    @builder["save_action"].sensitive=false
    @builder["save_as_action"].sensitive=false
    @builder["report_action"].sensitive=false
    @builder["generator_menu_item"].sensitive=false
    @builder["properties_action"].sensitive=false
    @builder["campaign_name_label"].text="None"
  end
  #move to religion_ui?
  def load_temple_name_generators
    model=Gtk::ListStore.new(String)
    iter=model.append
    model.set_value(iter,0,"None")
    $temple_name_generator=NameGenerator.new("temple")
    $temple_generators={}
    get_name_generators("temple").each do |gen|
      $temple_generators[gen]=gen+"_temple.yml"
      iter=model.append
      model.set_value(iter,0,gen)
    end
    @builder["temple_name_generator_chooser"].model=model
    cell_renderer=Gtk::CellRendererText.new
    @builder["temple_name_generator_chooser"].clear
    @builder["temple_name_generator_chooser"].pack_start(cell_renderer,true)
    @builder["temple_name_generator_chooser"].set_attributes(cell_renderer,:text=>0)

  end
  def add_generator(name)

    menu_item=Gtk::MenuItem.new(name)
    menu_item.signal_connect("activate") do
      yield
    end
    $user_interface.builder["generator_menu"].append(menu_item)
  end
  def new_action_activated()
    if $changed
      dialog = Gtk::MessageDialog.new(nil,
        Gtk::Dialog::DESTROY_WITH_PARENT,
        Gtk::MessageDialog::QUESTION,
        Gtk::MessageDialog::BUTTONS_OK_CANCEL,
        _("You have unsaved changes. Do you really want to create a new campaign?"))
      if dialog.run==Gtk::Dialog::RESPONSE_OK
        new_campaign
        @character_ui.system_changed
        @creature_ui.system_changed
      end
      dialog.destroy
    else
      new_campaign
      @character_ui.system_changed
      @creature_ui.system_changed
    end
  end
  def quit_action_activated()
    if $changed
      dialog = Gtk::MessageDialog.new(nil,
        Gtk::Dialog::DESTROY_WITH_PARENT,
        Gtk::MessageDialog::QUESTION,
        Gtk::MessageDialog::BUTTONS_OK_CANCEL,
        _("You have unsaved changes. Do you really want to quit?"))
      if dialog.run==Gtk::Dialog::RESPONSE_OK
        Gtk::main_quit
      end
      dialog.destroy
    else
      Gtk::main_quit
    end
  end
  def recent_chooser_activated(chooser)
    file=URI.split(chooser.current_uri)[5]
    load_file(file)
  end
  def campaign_properties()
    populate_name_generators_chooser("male")
    populate_name_generators_chooser("female")
    populate_name_generators_chooser("place")
    populate_system_chooser
    create_array_selectors($systems[$campaign.system])
    @builder["campaign_name_entry"].text=$campaign.name
    if @builder["properties_dialog"].run == Gtk::Dialog::RESPONSE_OK
      $campaign.name=@builder["campaign_name_entry"].text
      chooser=@builder["system_chooser"]
      $campaign.system=value=chooser.model.get_value(chooser.active_iter,0)
      @array_lists.each_pair do |array,list|
        array.keys=[]
        list.model.each do |model,path,iter|
          array.keys<<model.get_value(iter,0)
        end
        $campaign.update_array(array)
      end
      $campaign.male_name_generator=@builder["male_name_box"].model.get_value(@builder["male_name_box"].active_iter,0)
      $campaign.female_name_generator=@builder["female_name_box"].model.get_value(@builder["female_name_box"].active_iter,0)
      $campaign.place_name_generator=@builder["place_name_box"].model.get_value(@builder["place_name_box"].active_iter,0)

      BaseUi.clean_all_views
      project_changed
    end
    @builder["properties_dialog"].hide
  end
  def connect_signals
    @builder["overview"].buffer.signal_connect("end-user-action") do
      overview_changed
    end
    @builder["save_as_action"].signal_connect("activate") do
      save_as()
    end
    @builder["open_action"].signal_connect("activate") do
      open_file
    end
    @builder["new_action"].signal_connect("activate") do
      new_action_activated()
    end
    @builder["save_action"].signal_connect("activate") do
      save
    end
    @builder["view_main_toolbar_action"].signal_connect("activate") do
      @builder["main_toolbar"].visible=@builder["view_main_toolbar_action"].active?
    end
    @builder["close_action"].signal_connect("activate") do
      close_campaign
    end
    @builder["report_action"].signal_connect("activate") do
      gen=ReportGenerator.new()
      gen.generate
    end
    @builder["quit_action"].signal_connect("activate") do
      quit_action_activated()
    end
    @builder["preferences_action"].signal_connect("activate") do
      show_preferences
    end
    @builder["properties_action"].signal_connect("activate") do
      campaign_properties()
    end
    @builder["help_action"].signal_connect("activate") do
      help("index.html")
    end
    @builder["about_action"].signal_connect("activate") do
      Gtk::AboutDialog.show(nil,:authors=>["Sveinung F"], :copyright=>"Copyright 2009 Sveinung F", :program_name=>"Fudger", :translator_credits=>_("translator-credits"), :version=>FUDGER_VERSION)
    end
  end
  def system_changed
      @character_ui.system_changed
      @creature_ui.system_changed
  end
  def populate_chooser(array,type,chooser)
    model=Gtk::ListStore.new(String,type)
    array.each() do |item|
      iter=model.append()
      model.set_value(iter,0,item.name)
      model.set_value(iter,1,item)
    end
    chooser.model=model
    cell_renderer=Gtk::CellRendererText.new
    chooser.clear
    chooser.pack_start(cell_renderer,true)
    chooser.set_attributes(cell_renderer,:text=>0)
    chooser.active=0
  end
  def report_generator_dialog_run()
    populate_chooser($campaign.characters,Character,@builder["character_chooser"])
    populate_chooser($campaign.events,Event,@builder["event_chooser"])
    populate_chooser($campaign.places,Place,@builder["location_chooser"])
    populate_chooser($campaign.items,Item,@builder["item_chooser"])
    do_run=@builder["report_dialog"].run == Gtk::Dialog::RESPONSE_OK
    gm_only=@builder["gm_only_check_button"].active?
    what=nil
    if @builder["character_report_button"].active?
      what=$user_interface.builder["character_chooser"].model.get_value($user_interface.builder["character_chooser"].active_iter,1)
    end
    if @builder["location_report_button"].active?
      what=$user_interface.builder["location_chooser"].model.get_value($user_interface.builder["location_chooser"].active_iter,1)
    end
    if @builder["event_report_button"].active?
      what=$user_interface.builder["event_chooser"].model.get_value($user_interface.builder["event_chooser"].active_iter,1)
    end
    if @builder["item_report_button"].active?
      what=$user_interface.builder["item_chooser"].model.get_value($user_interface.builder["item_chooser"].active_iter,1)
    end
    return do_run,gm_only,what
  end
  def build_uis

    @character_ui=CharacterUi.new()
    @place_ui=PlaceUi.new
    @item_ui=ItemUi.new
    @event_ui=EventUi.new
    @image_ui=ImageUi.new
    @creature_ui=CreatureUi.new
    @religion_ui=ReligionUi.new
    @other_ui=OtherUi.new
    @overviewtagger=TextTagger.new(@builder["overview"])
  end
  def create_properties_dialog()
    chooser=@builder["system_chooser"]
    chooser.signal_connect("changed") do
      value=chooser.model.get_value(chooser.active_iter,0)
      create_array_selectors($systems[value])
    end
  end
  def create_array_selectors(system)
    @builder["array_vbox"].each do |child|
      @builder["array_vbox"].remove(child)
    end
    @array_lists={}
    arrays=system.arrays
    if system==$systems[$campaign.system]
      arrays=$campaign.arrays
    end
    arrays.each do |array|
      if array.modify_keys
        tree=Gtk::TreeView.new
        @array_lists[array]=tree
        tree.model=Gtk::ListStore.new(String)
        render=Gtk::CellRendererText.new
        render.editable=true
        render.signal_connect("edited") do |renderer,path, text|
          tree.model.set_value(tree.model.get_iter(path),0,text)
        end

        col=Gtk::TreeViewColumn.new(array.name.capitalize,render,:text=>0)
        tree.append_column(col)
        array.keys.each do|key|
          iter=tree.model.append
          tree.model.set_value(iter,0,key)
        end
        add_button=Gtk::Button.new(Gtk::Stock::ADD)
        add_button.signal_connect("clicked") do
          iter=tree.model.append()
          tree.model.set_value(iter,0,_("something"))
        end
        remove_button=Gtk::Button.new(Gtk::Stock::REMOVE)
        remove_button.signal_connect("clicked") do
          sel=tree.selection.selected
          if sel!=nil
            tree.model.remove(sel)
          end
        end
        hbox=Gtk::HBox.new
        hbox.pack_start(add_button,false,false)
        hbox.pack_start(remove_button,false,false)

        @builder["array_vbox"].pack_start(tree,true,true)
        @builder["array_vbox"].pack_start(hbox,false,false)
        @builder["array_vbox"].show_all
      end
    end
  end
  def update_all
    BaseUi.clean_all_views
  end
  def set_up_page_chooser
    scale=26
    @last_page=Gtk::TreePath.new('0')
    model=Gtk::ListStore.new(String,Gdk::Pixbuf)
    iter=model.append()
    model.set_value(iter,0,_("Overview"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/overview.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Characters"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/characters.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Places"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/places.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Events"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/events.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Items"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/items.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Images"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/images.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Creatures"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/creatures.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Religions"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/religions.png").scale(scale,scale))
    iter=model.append()
    model.set_value(iter,0,_("Other"))
    model.set_value(iter,1,Gdk::Pixbuf.new(File.dirname(__FILE__)+"/../../images/other.png").scale(scale,scale))
    @builder["page_chooser"].model=model
    @builder["page_chooser"].text_column=0
    @builder["page_chooser"].pixbuf_column=1
    @builder["page_chooser"].select_path(@last_page)
    @builder["page_chooser"].signal_connect("selection_changed") do
      if @builder["page_chooser"].selected_items.length>0
        @last_page=@builder["page_chooser"].selected_items[0]
        @builder["notebook"].page= @last_page.indices[0]
      else
        @builder["page_chooser"].select_path(@last_page)
      end
    end
  end
end
def check_dependency_versions()
  unless Gtk::check_version?(REQUIRED_GTK_MAJOR,REQUIRED_GTK_MINOR,REQUIRED_GTK_MICRO)
    dialog = Gtk::MessageDialog.new(nil,
      Gtk::Dialog::DESTROY_WITH_PARENT,
      Gtk::MessageDialog::ERROR,
      Gtk::MessageDialog::BUTTONS_OK,
      _("Gtk version too old. Fudger require at least version %i.%i.%i. Installed version is %i.%i.%i!")%[REQUIRED_GTK_MAJOR,REQUIRED_GTK_MINOR,REQUIRED_GTK_MICRO,Gtk::MAJOR_VERSION,Gtk::MINOR_VERSION,Gtk::MICRO_VERSION])
    dialog.run
    dialog.destroy
    exit
  end
end
check_dependency_versions()
