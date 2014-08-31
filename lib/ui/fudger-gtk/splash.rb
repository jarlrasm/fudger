
class Splash < Gtk::Window
  def initialize
    super("splash")
	 	vbox=Gtk::VBox.new()
    image=Gtk::Image.new(File.dirname(__FILE__)+"/../../images/splash.png")
    vbox.pack_start(image,false,false)
    @splashprogress=Gtk::ProgressBar.new()
    vbox.pack_start(@splashprogress,false,false)
    self.add(vbox)
    self.type_hint=Gdk::Window::TypeHint::SPLASHSCREEN
    self.window_position=Gtk::Window::Position::CENTER
  end
	def progress(progress,s)
		@splashprogress.fraction=progress.to_f/100.to_f
		@splashprogress.text=s
		while Gtk::events_pending?
			Gtk::main_iteration()
    end
  end
end
