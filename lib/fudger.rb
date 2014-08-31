#!/usr/bin/env ruby
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
require 'fudger_version'
require 'fudger_constants'
begin
  require 'gettext'
rescue Object=>s
  puts "Unable to load Gettext"
  module GetText
    def _(s)
      return s
    end
    def bindtextdomain(s)
      return s
    end
  end
end
["fudger-gtk","fudger-swing"].each  do |f_name|
  filename=File.dirname(__FILE__)+"/ui/"+f_name+"/userinterface.rb"
  messagefilename=File.dirname(__FILE__)+"/ui/"+f_name+"/fudger_message.rb"
  if(File.exists?(filename))
    begin
      load filename
      load messagefilename

      puts "Frontend: #{f_name}"
      break
    rescue Object=>o
      puts o
    end
  end
end
require 'rule_system'
require 'uri'
require 'campaign'
require 'name_generator'
require 'zip/zip'
require 'report_generator'
require 'plugin'
def dummy_for_gettext_translation
  _("Character")
  _("Place")
  _("Event")
  _("Item")
  _("Image")
  _("Creature")
  _("Religion")
  _("Other")
end
def extract_public_information(text)
  s=text.scan(/\[public\](.*?)(?=\[\/public\])/m)
  public_string=""
  s.each() do |str|
    public_string+=str[0]
  end
  return public_string
end
def strip_public_tags(text)
  while text.index("[public]")!=nil
    text=text.sub("[public]","")
  end
  while text.index("[/public]")!=nil
    text=text.sub("[/public]","")
  end
  return text
end
def create_paths
  begin
    if !File.exists?(File.expand_path("~/.fudger"))
      Dir.mkdir(File.expand_path("~/.fudger"))
    end
    if !File.exists?(File.expand_path("~/.fudger/rules"))
      Dir.mkdir(File.expand_path("~/.fudger/rules"))
    end
    if !File.exists?(File.expand_path("~/.fudger/plugins"))
      Dir.mkdir(File.expand_path("~/.fudger/plugins"))
    end
    if !File.exists?(File.expand_path("~/.fudger/names"))
      Dir.mkdir(File.expand_path("~/.fudger/names"))
    end
    if !File.exists?(File.expand_path("~/.fudger/stylesheets"))
      Dir.mkdir(File.expand_path("~/.fudger/stylesheets"))
    end
  rescue Object=>s
    puts s
  end
end

def save_file(filename)
  begin
    Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zipfile|
      zipfile.each do |entry|
        zipfile.remove(entry)
      end
      zipfile.get_output_stream("campaign.yml") do |stream|
        stream.puts $campaign.to_yaml
      end
      $campaign.images.each do|image|
        zipfile.get_output_stream(image.filename) do |stream|
          stream<<image.image
        end
      end

    end
    $last_file=filename
    project_changed(false)
  rescue Object=>s
    puts s
    FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_ERROR,_("Error saving file"))
  end
end
def save
	if $last_file==nil
    $user_interface.save_as()
	else
    save_file($last_file)
	end
end

def load_settings
	$link_color="blue"
	$public_tag_color="green"
	$use_character_name_generator=true
	$use_place_name_generator=true
	begin
		file=File.new(File.expand_path("~/.fudger/config"), "r")
		file.each_line do |line|
			if (line.lstrip).index('#') == 0
				next
			end 
			if line.lstrip.rstrip.eql? ""
				next
			end 
			if line.include?("=")
				key, value = line.split("=")
				if key.lstrip.rstrip=="use_character_name_generator" and value.lstrip.rstrip=="false"
					$use_character_name_generator=false
				end
				if key.lstrip.rstrip=="use_place_name_generator" and value.lstrip.rstrip=="false"
					$use_place_name_generator=false
				end
				if key.lstrip.rstrip=="link_color"
					$link_color=value.lstrip.rstrip
				end
				if key.lstrip.rstrip=="public_tag_color"
					$public_tag_color=value.lstrip.rstrip
				end
			end 
		end 
		file.close
	rescue
	end
end
def save_settings
	begin
		file=File.new(File.expand_path("~/.fudger/config"), "w")
		file<<"use_character_name_generator="+$use_character_name_generator.to_s+"\n"
		file<<"use_place_name_generator="+$use_place_name_generator.to_s+"\n"
		file<<"link_color="+$link_color.to_s+"\n"
		file<<"public_tag_color="+$public_tag_color.to_s+"\n"
		file.close
	rescue
	end
end

def new_campaign()
	$campaign=Campaign.new()
 $user_interface.campaign_properties
  $user_interface.reset_ui
end
def project_changed(changed=true)
    $changed=changed
  $user_interface.do_project_changed(changed)
end

def load_file(filename)
  begin
    Zip::ZipFile.open(filename) do |zipfile|
      $campaign=YAML::load( zipfile.read("campaign.yml"))
      $campaign.legacy
      $campaign.images.each do|image|
        image.image = zipfile.read(image.filename)
      end
    end
    project_changed(false)
    $user_interface.reset_ui
    $last_file=filename
  rescue Object=>s
    puts s
    FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_ERROR,_("Error loading file"))
    project_changed(false)
    close_campaign
  end

end
def load_systems_from_dir(dir)
  dir.each  do |filename|
    if filename[0-4..-1]==".xml"
      begin
        puts "Loading #{filename}"
        sys=RuleSystem.new(File.new(File.dirname(__FILE__)+"/rules/"+filename))
        $systems[sys.name]=sys
      rescue Object=>s
        puts s
      end
    end
  end
end
def load_systems
  $systems={}
  dir = Dir.new(File.dirname(__FILE__)+"/rules")
  load_systems_from_dir(dir)
  dir = Dir.new(File.expand_path("~/.fudger/rules"))
  load_systems_from_dir(dir)
end
def get_name_generators(name_type)
  gens=[]
  dir = Dir.new(File.dirname(__FILE__)+"/names")
  dir.each  do |filename|
    extension="_"+name_type+".yml"
    if filename[0-extension.length..-1]==extension
      gens+=[filename[0,filename.length-extension.length]]
    end
  end
  return gens
end

def close_campaign
  if $changed
    puts 1
    if FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_QUESTION,_("You have unsaved changes. Do you really want to close document?"))
      return
    end
  end
  $campaign=nil
  $user_interface.campaign_closed
end
def help(filename)
	file = File.new(File.dirname(__FILE__)+"/doc/"+filename)
  html=file.read
  file.close
  view=HtmlViewer.get_html_viewer("file://"+File.dirname(__FILE__)+"/doc/"+filename,html)
  view.run
  view.hide
end

def load_name_generators
  $male_character_name_generator=NameGenerator.new("male")
  $female_character_name_generator=NameGenerator.new("female")
  $place_name_generator=NameGenerator.new("place")
  $user_interface.load_temple_name_generators
end
def window_closed
  if $changed
    if FudgerMessage.Message(FUDGER_MESSAGE_BOX_TYPE_QUESTION,_("You have unsaved changes. Do you really want to quit?"))
      return false
    else
      return true
    end
  else
    return false
  end
end



#program start
puts "Loading Fudger version %s"%[FUDGER_VERSION]
include GetText
bindtextdomain("fudger")
splash=Splash.new()
splash.show_all
splash.progress(0,_("Checking for folders"))
create_paths
splash.progress(4,_("Loading systems"))
load_systems
splash.progress(20,_("Loading ui"))
$user_interface=UserInterface.new
splash.progress(40,_("Loading settings"))
load_settings
#dummy campaign neccesarry for som init stuff?
$campaign=Campaign.new()
splash.progress(45,_("Loading name generators"))
load_name_generators
splash.progress(60,_("Configuring ui"))
$user_interface.configure_ui
splash.progress(80,_("Loading plugins"))
begin
  Plugin.load_plugins(File.dirname(__FILE__)+"/plugins")
  Plugin.load_plugins(File.expand_path("~/.fudger/plugins"))
rescue Object=>s
  puts s
end
#file given in arguments?
if(ARGV.length>0)
  splash.progress(90,_("Loading %s")%ARGV[0])
  load_file(ARGV[0])
else
  project_changed(false)
  close_campaign
end
splash.progress(100,_("Ready"))
splash.destroy
$user_interface.run


