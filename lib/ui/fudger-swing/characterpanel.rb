require 'ui/fudger-swing/ruby_swing_document_listener'
require 'ui/fudger-swing/ruby_swing_tree_selection_listener'
require 'ui/fudger-swing/ruby_swing_change_listener'
require 'ui/fudger-swing/with_rules_panel'
require 'ui/fudger-swing/view_sorter'
class CharacterPanelHandler<WithRulesPanel
  include ViewSorter
	attr_accessor :panel, :selected
	def initialize(panel)
		super(panel)
	end
  def select(char)
		super(char)
		unless char==nil
      @panel.importance_chooser.set_selected_index(char.importance)
      @panel.age_chooser.set_value(char.age)
      if char.gender==0
        @panel.gender_button.set_label("Male")
      else
        @panel.gender_button.set_label("Female")
      end
		end
  end
  def do_update_tree()
    selected=@panel.sort_combo.get_selected_index
    if selected==0
      sort_by_related(@panel.item_tree,Character,Place)
    end
    if selected==1
      sort_by_related(@panel.item_tree,Character,Event)
    end
    if selected==2
      sort_by_related(@panel.item_tree,Character,Religion)
    end
    if selected==3
      sort_by_attribute(@panel.item_tree,Character,"importance",
        [_("Irrellevant"),_("Minor"),_("Important"),_("Major"),_("PC")])
    end
    @panel.item_tree.model.reload
  end
  def configure
    super
    importance_listner=RubySwingActionListener.new do |evt|
      unless @selected==nil
        @selected.importance=@panel.importance_chooser.get_selected_index
      end
    end
    @panel.importance_chooser.add_action_listener(importance_listner)
    @panel.sort_combo.add_action_listener() do |evt|
      update_tree()
    end
    age_listner=RubySwingChangeListener.new do |evt|
      unless @selected==nil
        @selected.age=@panel.age_chooser.get_value
      end
    end
    @panel.age_chooser.add_change_listener(age_listner)
    gender_listner=RubySwingActionListener.new do |evt|
      unless @selected==nil
        if @selected.gender==0
          @selected.gender=1
          @panel.gender_button.set_label("Female")
        else
          @selected.gender=0
          @panel.gender_button.set_label("Male")
        end
      end
    end
    @panel.gender_button.add_action_listener(gender_listner)
  end 

end
