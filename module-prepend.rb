# -*- coding: utf-8 -*-

module MonitorMixin
  def initialize
    p :monitor_mixin
    super # これは必要。これがないと:bookが出力されない
  end
end

class Book
  prepend MonitorMixin
  def initialize
    p :book
  end
end

Book.new # => :monitor_mixin
         #    :book
