# To change this template, choose Tools | Templates
# and open the template in the editor.

class EventPanelHandler < WithParentPanelHandler
  def initialize(panel)
    super(panel)
  end
  def select(item)
		super(item)
		unless item==nil
      @panel.type_chooser.set_selected_item(item.type)
      @panel.start_spinner.set_value(java.util.Date.new(item.start.ctime))
      @panel.end_spinner.set_value(java.util.Date.new(item.end.ctime))
    end
  end
  def configure
		super
    type_listner=RubySwingActionListener.new do |evt|
      if @selected!=nil
          @selected.type=@panel.type_chooser.get_selected_item
      end
    end
    @panel.type_chooser.add_action_listener(type_listner)
    start_listner=RubySwingChangeListener.new do |evt|
      unless @selected==nil
        @selected.start=DateTime.parse(@panel.start_spinner.get_value.to_s)
      end
    end
    @panel.start_spinner.add_change_listener(start_listner)
    end_listner=RubySwingChangeListener.new do |evt|
      unless @selected==nil
        @selected.end=DateTime.parse(@panel.end_spinner.get_value.to_s)
      end
    end
    @panel.end_spinner.add_change_listener(end_listner)
  end
end
