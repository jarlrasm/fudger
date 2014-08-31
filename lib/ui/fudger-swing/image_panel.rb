# To change this template, choose Tools | Templates
# and open the template in the editor.

class ImagePanelHandler < BasePanelHandler
  def initialize(panel)
    super(panel)
  end
  def get_image()
    file=Tempfile.new(@selected.filename)
    file<<@selected.image
    file.close
    icon = javax.swing.ImageIcon.new(file.path)
    return icon
  end
  def select(item)
		super(item)
		unless item==nil
      @panel.image_label.set_icon(get_image)
		end
  end
end
