require 'ui/fudger-swing/with_parent_panel_handler'
class ReligionPanelHandler < WithParentPanelHandler
  def initialize(panel)
    super(panel)
    load_temple_name_generators
  end
  def select(char)
		super(char)
		unless char==nil
        @panel.illegal_button.selected=@selected.illegal
      @panel.temple_names.set_selected_item(@selected.name_generator)
		end
  end
  def load_temple_name_generators
    @panel.temple_names.add_item("None")
    $temple_name_generator=NameGenerator.new("temple")
    $temple_generators={}
    get_name_generators("temple").each do |gen|
      $temple_generators[gen]=gen+"_temple.yml"
      @panel.temple_names.add_item(gen)
    end
  end
  def configure
    super
    illegal_listner=RubySwingActionListener.new do |evt|
      unless @selected==nil
        @selected.illegal=@panel.illegal_button.selected
      end
    end
    @panel.illegal_button.add_action_listener(illegal_listner)
    name_listner=RubySwingActionListener.new do |evt|
      unless @selected==nil
        @selected.name_generator=@panel.temple_names.get_selected_item
      end
    end
    @panel.temple_names.add_action_listener(name_listner)
  end
end
