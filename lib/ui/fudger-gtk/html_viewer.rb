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

# TODO: Replace this with opening in  GIO..

#require 'gtkmozembed'
class HtmlViewer<Gtk::Dialog
  include GetText
  attr_accessor :html, :uri
  def initialize(uri,html)
    @uri=uri
    launch
  end
  def launch
    begin
        system('xdg-open',@uri)
    rescue Object=>s
      puts "Unable to load browser"
      puts s
    end
  end
  @@viewer=nil
  def self.get_html_viewer(uri,html)
    if(@@viewer==nil)
      @@viewer=HtmlViewer.new(uri,html)
    else
      @@viewer.html=(html)
      @@viewer.uri=(uri)
      @@viewer.launch
    end
    return @@viewer
  end
  def run

  end
  def hide

  end
end
