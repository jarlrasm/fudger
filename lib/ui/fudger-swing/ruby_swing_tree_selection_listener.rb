# To change this template, choose Tools | Templates
# and open the template in the editor.

class RubySwingTreeSelectionListener
    include javax.swing.event.TreeSelectionListener
  def initialize(&func)
    @func=func
  end
    def valueChanged(evt)
      @func.call(evt)
    end
end
