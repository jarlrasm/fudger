# To change this template, choose Tools | Templates
# and open the template in the editor.

class FudgerMessage
  def initialize
    
  end
  def self.Message(type,message)
    if type==FUDGER_MESSAGE_BOX_TYPE_MESSAGE
      m_type=Gtk::MessageDialog::MESSAGE
      buttons=Gtk::MessageDialog::BUTTONS_CLOSE
    end
    if type==FUDGER_MESSAGE_BOX_TYPE_ERROR
      m_type=Gtk::MessageDialog::ERROR
      buttons=Gtk::MessageDialog::BUTTONS_CLOSE
    end
    if type==FUDGER_MESSAGE_BOX_TYPE_QUESTION
      m_type=Gtk::MessageDialog::QUESTION
      buttons=Gtk::MessageDialog::BUTTONS_OK_CANCEL
    end

    dialog = Gtk::MessageDialog.new(nil,
      Gtk::Dialog::DESTROY_WITH_PARENT,
      m_type,
      buttons,
      message)
    retv=dialog.run==Gtk::Dialog::RESPONSE_OK
    dialog.destroy
    return retv
  end
end
