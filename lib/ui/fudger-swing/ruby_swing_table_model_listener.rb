# To change this template, choose Tools | Templates
# and open the template in the editor.

class RubySwingTableModelListener
  def initialize(&func)
    @func=func
  end
  def tableChanged(event)
    @func.call(event)
  end
end