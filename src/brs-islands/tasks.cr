module BRS::Islands
  class Task
    property name : String
    property complete : Bool = false

    def initialize(@name, @complete = false)
    end
  end

  class TaskList
    getter list = [] of Task
    getter complete = 0

    def <<(name : String)
      list << Task.new(name)
    end

    def complete_next_task
      last_incomplete_task = @list.select { |task| !task.complete }[0]
      last_incomplete_task.complete = true
      @complete += 1
      puts "[#{@complete}/#{@list.size}] #{last_incomplete_task.name}"
    end

    def initialize
    end
  end
end