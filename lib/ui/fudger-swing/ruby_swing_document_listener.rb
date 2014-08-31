# To change this template, choose Tools | Templates
# and open the template in the editor.

class RubySwingDocumentListener
  include javax.swing.event.DocumentListener
  def initialize(&func)
    @func=func
  end
  def insertUpdate(evt)
    @func.call(evt)
  end
  def removeUpdate(evt)
    @func.call(evt)
  end

  def changedUpdate(evt)
    @func.call(evt)
  end
end
