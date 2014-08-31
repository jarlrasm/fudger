# To change this template, choose Tools | Templates
# and open the template in the editor.

class OtherPanelHandler < BasePanelHandler
  def initialize(panel)
    super(panel)
  end
  def select(item)
		super(item)
		unless item==nil
      @panel.type_chooser.set_selected_item(item.type)
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
  end
end
