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

require 'ui/fudger-gtk/base_ui'
class ImageUi < BaseUi
  def initialize
    super
    @zoom=100
    $user_interface.builder["image_file_chooser"].signal_connect("file_set") do
      unless @selected.filename==$user_interface.builder["image_file_chooser"].filename
        @selected.filename=$user_interface.builder["image_file_chooser"].filename
      end
      image=get_pixbuf()
      $user_interface.builder["image"].pixbuf=image.scale((image.width*@zoom)/100,(image.height*@zoom)/100)
    end
    $user_interface.builder["image_fit_button"].signal_connect("clicked") do
      alloc=$user_interface.builder["image_scrolledwindow"].allocation
      image=get_pixbuf()
      bestx=(alloc.width*100)/image.width
      besty=(alloc.height*100)/image.height
      if bestx>besty
        @zoom=besty
      else
        @zoom=bestx
      end
      $user_interface.builder["image"].pixbuf=image.scale((image.width*@zoom)/100,(image.height*@zoom)/100)
    end
    $user_interface.builder["image_normal_button"].signal_connect("clicked") do
      @zoom=100
      image=get_pixbuf()
      $user_interface.builder["image"].pixbuf=image.scale((image.width*@zoom)/100,(image.height*@zoom)/100)
    end
    $user_interface.builder["image_zoom_in_button"].signal_connect("clicked") do
      @zoom=@zoom+(@zoom/10)
      image=get_pixbuf()
      $user_interface.builder["image"].pixbuf=image.scale((image.width*@zoom)/100,(image.height*@zoom)/100)
    end
    $user_interface.builder["image_zoom_out_button"].signal_connect("clicked") do
      @zoom=@zoom-(@zoom/10)
      image=get_pixbuf()
      $user_interface.builder["image"].pixbuf=image.scale((image.width*@zoom)/100,(image.height*@zoom)/100)
    end
  end
  def get_pixbuf()
    file=Tempfile.new(@selected.filename)
    file<<@selected.image
    file.close
    pixbuf=Gdk::Pixbuf.new(file.path)
    return pixbuf
  end
  def do_select()
    super
    if @selected==nil
      return
    end
    $user_interface.builder["image_file_chooser"].select_filename(@selected.filename)
    $user_interface.builder["image"].pixbuf=get_pixbuf()
  end

end