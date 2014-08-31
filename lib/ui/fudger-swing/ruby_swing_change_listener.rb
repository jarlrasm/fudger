# To change this template, choose Tools | Templates
# and open the template in the editor.

class RubySwingChangeListener
  include javax.swing.event.ChangeListener
  def initialize(&func)
    @func=func
  end
    def stateChanged(event)
      @func.call(event)
    end
end
