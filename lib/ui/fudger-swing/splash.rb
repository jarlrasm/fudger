class Splash<javax.swing.JFrame
  def initialize
    super
    icon = javax.swing.ImageIcon.new(File.dirname(__FILE__)+"/../../images/splash.png")
    image=javax.swing.JLabel.new(icon)
    @label=javax.swing.JLabel.new("label")
    getContentPane().add(image, java.awt.BorderLayout::PAGE_START)
    getContentPane().add(@label, java.awt.BorderLayout::PAGE_END)
    setUndecorated(true)
    screen_size =java.awt.Toolkit.getDefaultToolkit().getScreenSize();
    splash_width = image.get_preferred_size().width
    splash_height= image.get_preferred_size().height+@label.get_preferred_size().height
    setLocation((screen_size.width-splash_width)/2,(screen_size.height-splash_height)/2 );
  end
  def show_all()
    pack()
    setVisible(true)

  end
	def progress(progress,s)
		@label.text=s
  end
  def destroy
    setVisible(false)
  end
end
