#    This file is part of Fudger.
#
#    Fudger is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Fudger is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Fudger.  If not, see <http://www.gnu.org/licenses/>.

class ReportGenerator
  include GetText
  def initialize
  end

  def set_up_generator
    begin
      return $user_interface.report_generator_dialog_run
    rescue
      return true,true,nil
    end
  end
  def generate()

    do_run,@gm_only,what=set_up_generator
    @allreadyreported=[]
    if do_run
      html="<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">"
      html<<"<html>\n"
      html<<"<head>\n"
      html<<"<title>"<<_("Report")<<"</title>\n"
      html<<"<meta name=\"generator\" content=\"Fudger\">\n"
      html<<"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n"
      html<<"<link rel=\"stylesheet\" type=\"text/css\" href=\"report.css\">\n"
      html<<"<link rel=\"stylesheet\" type=\"text/css\" href=\"printer_friendly_report.css\">\n"
      html<<"</head>\n"
      html<<"<body>\n"
      html<<generate_campaign_report(what)
      html<<"</body>\n"
      html<<"</html>\n"
      dir=Dir.tmpdir+"/fudger/"
      unless File.exists?(dir)
        Dir.mkdir(dir)
      end
      Dir[dir+"/*"].each do |file|
        File.delete(file)
      end
      $campaign.images.each do|image|
        file=File.new(dir+image.filename,"w")
        file<<image.image
        file.close
      end

      file=File.new(dir+"report.css","w")
      begin
        if $systems[$campaign.system].css==nil
          file<<File.new(File.dirname(__FILE__)<<"/stylesheets/report.css").read
        else
          infile=File.dirname(__FILE__)<<"/stylesheets/"<<$systems[$campaign.system].css
          if !File.exist?(infile)
            infile=File.expand_path("~/.fudger/stylesheets/"<<$systems[$campaign.system].css)
          end
          file<<File.new(infile).read
        end
      rescue Object=>s
        puts s
      end
      file.close
      file=File.new(dir+"printer_friendly_report.css","w")
      begin
        if $systems[$campaign.system].print_css==nil
          file<<File.new(File.dirname(__FILE__)<<"/stylesheets/printer_friendly_report.css").read
        else
          infile=File.dirname(__FILE__)<<"/stylesheets/"<<$systems[$campaign.system].print_css
          if !File.exist?(infile)
            infile=File.expand_path("~/.fudger/stylesheets/"<<$systems[$campaign.system].print_css)
          end
          file<<File.new(infile).read
        end
      rescue Object=>s
        puts s
      end
      file.close
      file=File.new(dir+"report.html","w")
      file<<html
      file.close
      view=HtmlViewer.get_html_viewer("file://"<<dir<<"report.html",html)
      view.run
      view.hide

  	end
    begin
      $user_interface.builder["report_dialog"].hide
    rescue
    end
  end

  def read_template(filename,object)
    content=""
    content<<File.new(filename).read
    read_reported(content,object)
    read_eaches(content,object)
    read_hash_eaches(content,object)
    read_table_eaches(content,object)
    read_children(content,object)
    read_ifs(content,object)
    read_includes(content, object)
    read_calculated(content,object)
    read_vars(content, object)
    return content
  end
  def read_eaches(content,current_object)
    continue=true
    while continue
      c=content.sub!(/<each id='([a-z]*?)'>(.*?)(?=\<\/each>)<\/each>/m) do |match|
        evalstring="$campaign.#{$1}"
        unless(current_object==nil)
          evalstring="current_object.related_#{$1}"
        end
        expanded=""
        eval(evalstring).each do |item|
          unless @reported.include?(item)
            if @gm_only or item.description.index("[public]")!=nil
              itemstring=$2.clone
              read_hash_eaches(itemstring,item)
              read_table_eaches(itemstring,item)
              read_vars(itemstring, item)
              read_calculated(itemstring,item)
              read_ifs(itemstring, item)
              read_reported(itemstring,item)
              read_includes(itemstring, item)
              expanded+=itemstring
            end
          end
        end
        expanded
      end
      continue=false if c==nil
    end
  end
  def read_hash_eaches(content,current_object)
    continue=true
    while continue
      c=content.sub!(/<hash-each id='([a-z]*?)'>(.*?)(?=\<\/hash-each>)<\/hash-each>/m) do |match|
        id=$1
        cont=$2
        evalstring="current_object.hash_tables['#{id}']"
        translator=$systems[$campaign.system].creature.get_hash_table(id).translate_value
        expanded=""
        h_table=eval(evalstring)
        unless h_table==nil
          h_table.each_pair do |key,value|
            if translator==nil
              expanded+=cont.sub("key",key).sub("value",value.to_s)
            else
              expanded+=cont.sub("key",key).sub("value",$systems[$campaign.system].get_translator(translator).translate(current_object,key,value))
            end
          end
        end
        expanded
      end
      continue=false if c==nil
    end
  end
  def read_table_eaches(content,current_object)
    continue=true
    while continue
      c=content.sub!(/<table-each id='([a-z]*?)'>(.*?)(?=\<\/table-each>)<\/table-each>/m) do |match|
        id=$1
        cont=$2
        evalstring="current_object.tables['#{id}']"
        expanded=""
        table=eval(evalstring)
        unless table==nil
          table.each do |value|
            expanded+=cont.sub("value",value.to_s)
          end
        end
        expanded
      end
      continue=false if c==nil
    end
  end
  def read_children(content,current_object)
    continue=true
    while continue
      c=content.sub!(/<children>(.*?)(?=\<\/children>)<\/children>/m) do |match|
        expanded=""
        current_object.get_children.each do |item|
          unless @reported.include?(item)
            if @gm_only or item.description.index("[public]")!=nil
              itemstring=$1.clone
              read_vars(itemstring, item)
              read_ifs(itemstring, item)
              read_reported(itemstring,item)
              read_includes(itemstring, item)
              expanded+=itemstring
            end
          end
        end
        expanded
      end
      continue=false if c==nil
    end
  end
  def modify_description(desc)
    if @gm_only
      return strip_public_tags(desc)
    else
      return extract_public_information(desc)
    end
  end
  def read_vars(content, current_object)
    continue=true
    while continue
      c=content.sub!(/<fudger>(.*?)(?=\<\/fudger>)<\/fudger>/) do |match|
        val=""
        if(current_object==nil)
          if $1=="overview"
            val=modify_description(eval("$campaign.#{$1}"))
          else
            val=eval("$campaign.#{$1}")
          end
        else
          if $1=="start"
            val=format_event_time(current_object.start, current_object.end)[0]
          elsif $1=="end"
            val=format_event_time(current_object.start,current_object.end)[1]
          elsif $1=="description"
            val=modify_description(eval("current_object.#{$1}"))
          else
            val=eval("current_object.#{$1}")
          end

        end
        val
      end
      continue=false if c==nil
    end
  end
  def read_calculated(content, current_object)
    continue=true
    while continue
      c=content.sub!(/<calculated>(.*?)(?=\<\/calculated>)<\/calculated>/) do |match|
        val=""
        statement=$1
        unless(current_object==nil)
          calc=eval("$systems[$campaign.system].#{current_object.class.name.downcase}.calculations").select {|ca|ca.name==statement}[0]
          trans=$systems[$campaign.system].get_translator(calc.translate_value)
          value=0
          if calc.attribute!=nil
            current_object.hash_tables.each_pair do |key2, values|
              values.each_pair do |key3,value2|
                if key3==calc.attribute
                  value=value2
                end
              end
            end
          end
          val=trans.translate(current_object,"default",value)
        end
        val
      end
      continue=false if c==nil
    end
  end
  def read_reported(content, current_object)
    c=content.sub!(/<reported>/) do |match|
      val=""
      @reported<<current_object
      val
    end
  end
  def read_ifs(content, current_object)
    continue=true
    while continue
      c=content.sub!(/<if statement='(.*?)(?=')'>(.*?)(?=\<\/if>)<\/if>/m) do |match|
        val=""
        statement=$1
        code=$2
        if(current_object==nil)
          statement.sub!("item","$campaign")
        else
          statement.sub!("item","current_object")
        end
        if eval(statement)
          val=code
        end
        val
      end
      continue=false if c==nil
    end
  end
  def read_includes(content, current_object)
    continue=true
    while continue
      c=content.sub!(/<include>(.*?)(?=\<\/include)<\/include>/) do |match|
        filename=$1.clone
        s=$1.split('_')
        puts s[0]
        puts filename
        read_template(File.dirname(__FILE__)+"/report templates/#{s[0]}/#{filename}",current_object)
      end
      continue=false if c==nil
    end
  end
  def format_event_time(start,stop)
    months=["",_("January"),_("February"),_("March"),_("April"),_("May"),_("June"),_("July"),
      _("August"),_("September"),_("October"),_("November"),_("December")]

    string=["#{months[start.month]} #{start.day.to_s}   %02d:%02d" % [start.hour,start.min],
      "#{months[stop.month]} #{stop.day.to_s}   %02d:%02d" % [stop.hour,stop.min]]
    if stop-start>2
      string=[start.year.to_s+" "+months[start.month]+" "+start.day.to_s,
        stop.year.to_s+" "+months[stop.month]+" "+stop.day.to_s]
    end
    if stop-start>365*2
      string=[start.year.to_s,stop.year.to_s]
    end
    return string
  end
  def generate_campaign_report(what)
    @reported=[]
    campaign=$campaign.system.downcase
    if what==nil
      filename=File.dirname(__FILE__)+"/report templates/#{campaign}/#{campaign}_campaign"
      unless File.exists?(filename)
        filename= filename=File.dirname(__FILE__)+"/report templates/default/default_campaign"
      end
    else
      filename=File.dirname(__FILE__)+"/report templates/#{campaign}/#{campaign}_#{what.class.name.downcase}"
      unless File.exists?(filename)
        filename= filename=File.dirname(__FILE__)+"/report templates/default/default_#{what.class.name.downcase}"

      end
    end
    return read_template(filename, what)
  end
end
