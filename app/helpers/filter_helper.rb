module FilterHelper
  def format_datetime(dt)
    return dt if dt.nil?
    dt.to_datetime.to_s(:longest_with_zone)
  end  
end

