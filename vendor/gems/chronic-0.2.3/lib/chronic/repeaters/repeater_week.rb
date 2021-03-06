class Chronic::RepeaterWeek < Chronic::Repeater #:nodoc:
  WEEK_SECONDS = 604800 # (7 * 24 * 60 * 60)
  
  def next(pointer)
    super
    
    if !@current_week_start
      case pointer
      when :future
        sunday_repeater = Chronic::RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        next_sunday_span = sunday_repeater.next(:future)
        @current_week_start = next_sunday_span.begin
      when :past
        sunday_repeater = Chronic::RepeaterDayName.new(:sunday)
        sunday_repeater.start = (@now + Chronic::RepeaterDay::DAY_SECONDS)
        sunday_repeater.next(:past)
        last_sunday_span = sunday_repeater.next(:past)
        @current_week_start = last_sunday_span.begin
      end
    else
      direction = pointer == :future ? 1 : -1
      @current_week_start += direction * WEEK_SECONDS
    end
    
    Chronic::Span.new(@current_week_start, @current_week_start + WEEK_SECONDS)
  end
  
  def this(pointer = :future)
    super
    
    case pointer
    when :future
      this_week_start = Time.local(@now.year, @now.month, @now.day, @now.hour) + Chronic::RepeaterHour::HOUR_SECONDS
      sunday_repeater = Chronic::RepeaterDayName.new(:sunday)
      sunday_repeater.start = @now
      this_sunday_span = sunday_repeater.this(:future)
      this_week_end = this_sunday_span.begin
      Chronic::Span.new(this_week_start, this_week_end)
    when :past
      this_week_end = Time.local(@now.year, @now.month, @now.day, @now.hour)
      sunday_repeater = Chronic::RepeaterDayName.new(:sunday)
      sunday_repeater.start = @now
      last_sunday_span = sunday_repeater.next(:past)
      this_week_start = last_sunday_span.begin
      Chronic::Span.new(this_week_start, this_week_end)
    when :none
      sunday_repeater = Chronic::RepeaterDayName.new(:sunday)
      sunday_repeater.start = @now
      last_sunday_span = sunday_repeater.next(:past)
      this_week_start = last_sunday_span.begin
      Chronic::Span.new(this_week_start, this_week_start + WEEK_SECONDS)
    end
  end
  
  def offset(span, amount, pointer)
    direction = pointer == :future ? 1 : -1
    span + direction * amount * WEEK_SECONDS
  end
  
  def width
    WEEK_SECONDS
  end
  
  def to_s
    super << '-week'
  end
end