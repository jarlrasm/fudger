require 'campaign_element'
class ElementWithParent<CampaignElement
	fudger_campaign_accessor [:parent]
  def initialize
    super
    @parent=nil
    
  end
  def get_children()
    return eval("$campaign.#{self.class.name.downcase}s.select{|item|item.parent==self.name}")
  end
  def is_ancestor_of?(item)
    get_children.each do |child|
      if child==item
        return true
      end
      if child.is_ancestor_of?(item)
        return true
      end
    end
    return false
  end
end
