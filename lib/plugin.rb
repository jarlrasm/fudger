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
class Plugin
  attr_reader :name,:author,:version,:description
  attr_accessor :valid,:global
  def initialize(author,version,description=self.class.to_s)
    @author=author
    @version=version
    @name=self.class.to_s
    @description=description
    @valid = true
    @global=true
  end
  def plugin_require(klass,version='0')
    begin
      @valid=!(eval(klass).new.version<version)
    rescue Object=>s
      @valid=false
    end
  end
  def require_fudger_version(version)
    if FUDGER_VERSION<version
      @valid=false
    end
  end
  def self.inherited(child)
    @@new_plugins << child
  end
  @@new_plugins = []
  @@all_plugins = {}
  def self.all_plugins
    @@all_plugins
  end
  def self.load_plugins(plugin_dir)
    @@new_plugins = []
    Dir[plugin_dir+"/*.rb"].each do |plugin|
      puts "Loading "+plugin
      begin
        load plugin
      rescue Object=>s
        puts "Error loading plugin #{plugin}:#{s}"
      end
    end
    @@new_plugins.each do|plugin|
      instance=plugin.new
      if instance.valid
        instance.create
        #TODO maybe some better way of checking for global?
        instance.global=plugin_dir==File.expand_path("~/.fudger/plugins")
        @@all_plugins[instance.name]=instance
      end
    end
  end
end
