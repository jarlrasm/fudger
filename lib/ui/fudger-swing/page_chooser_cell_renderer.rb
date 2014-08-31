
class PageChooserCellRenderer <javax.swing.JLabel
  include javax.swing.ListCellRenderer
  def initialize
    @image={}
  end
  def getListCellRendererComponent(list, value,index,is_selected,cell_has_focus)
    if @image[value]==nil
      #a small hack to make sure that other.png is loaded instead of non-existant others.png
      if value.to_s!="Others"
        @image[value] = javax.swing.ImageIcon.new(File.dirname(__FILE__)+"/../../images/#{value.to_s.downcase}.png")
      else
        @image[value] = javax.swing.ImageIcon.new(File.dirname(__FILE__)+"/../../images/other.png")
      end
    end
    set_text(value.to_s)
    set_icon(@image[value])
    if (is_selected)
      set_background(list.get_selection_background())
      set_foreground(list.get_selection_foreground())
    else
      set_background(list.get_background())
      set_foreground(list.get_foreground())
    end
    set_enabled(list.is_enabled())
    set_font(list.get_font())
    set_opaque(true)
    return self
  end
end
