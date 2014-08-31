# To change this template, choose Tools | Templates
# and open the template in the editor.

class RubySwingActionListener
  include java.awt.event.ActionListener
  def initialize(&func)
    @func=func
  end
    def actionPerformed(event)
      @func.call(event)
    end
end
