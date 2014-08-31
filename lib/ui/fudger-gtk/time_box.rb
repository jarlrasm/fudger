#This class is a hack to implement a time entry from builder. Why don't gtk have this?
require 'date'
class TimeBox
  def initialize(time_box)
    @time=DateTime.new
    @min=DateTime.new(-50000)
    @max=DateTime.new(50000)
    @year_entry=time_box.children[0]
    @year_entry.set_range(-50000,50000)
    @year_entry.set_increments(1,30)
    @month_entry=time_box.children[1]
    @month_entry.set_range(1,12)
    @month_entry.set_increments(1,10)
    @day_entry=time_box.children[2]
    @day_entry.set_range(1,31)
    @day_entry.set_increments(1,10)
    @hour_entry=time_box.children[3]
    @hour_entry.set_range(0,23)
    @hour_entry.set_increments(1,10)
    @minute_entry=time_box.children[4]
    @minute_entry.set_range(0,59)
    @minute_entry.set_increments(1,10)
  end
  def min=(time)
    if time>@max
      @max=@min
    else
      @min=time
    end
    check_time
  end
  def max=(time)
    if time<@min
      @min=@max
    else
      @max=time
    end
    check_time
  end
  def emit_changed()
    @year_entry.signal_connect("changed") do
      set_time
      yield(@time)
    end
    @month_entry.signal_connect("changed") do
      set_time
      yield(@time)
    end
    @day_entry.signal_connect("changed") do
      set_time
      yield(@time)
    end
    @minute_entry.signal_connect("changed") do
      set_time
      yield(@time)
    end
    @hour_entry.signal_connect("changed") do
      set_time
      yield(@time)
    end
  end
  def check_time
    if @time<@min
      @time=@min
      update_entries()
    end
    if @time>@max
      @time=@max
      update_entries()
    end
  end
  def set_time()
    begin
      datetime=DateTime.new(@year_entry.value.to_i,@month_entry.value.to_i,@day_entry.value.to_i,@hour_entry.value.to_i,@minute_entry.value.to_i)
      @time=datetime
    rescue
      update_entries
    end
    check_time
  end
  def update_entries()
    @year_entry.value=@time.year
    @month_entry.value=@time.month
    @day_entry.value=@time.day
    @hour_entry.value=@time.hour
    @minute_entry.value=@time.min
  end
  def time=(newtime)
    @time=newtime
    update_entries
  end
  def time
    return @time
  end
end
