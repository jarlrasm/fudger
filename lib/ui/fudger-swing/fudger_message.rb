# To change this template, choose Tools | Templates
# and open the template in the editor.

class FudgerMessage
  def initialize
    
  end
  def self.Message(type,message)
    if type==FUDGER_MESSAGE_BOX_TYPE_MESSAGE
      javax.swing.JOptionPane::show_message_dialog(nil, message, "Fudger", javax.swing.JOptionPane::INFORMATION_MESSAGE)
    end
    if type==FUDGER_MESSAGE_BOX_TYPE_ERROR
      javax.swing.JOptionPane::show_message_dialog(nil, message, "Error", javax.swing.JOptionPane::ERROR_MESSAGE)
    end
    if type==FUDGER_MESSAGE_BOX_TYPE_QUESTION
      options=["OK","Cancel"]
      return javax.swing.JOptionPane::show_option_dialog(nil, message, "Fudger",javax.swing.JOptionPane::DEFAULT_OPTION, javax.swing.JOptionPane::INFORMATION_MESSAGE,nil,options.to_java,nil)==0
    end
    return true
  end
end
