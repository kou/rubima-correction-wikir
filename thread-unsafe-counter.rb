class Counter
  attr_reader :count
  def initialize
    @count = 0
  end

  def up
    count = @count
    sleep 0.00000001
    @count = count + 1
  end
end

counter = Counter.new

threads = []
100.times do
  threads << Thread.new do
    100.times do
      counter.up
    end
  end
end
threads.each(&:join)

p counter.count
