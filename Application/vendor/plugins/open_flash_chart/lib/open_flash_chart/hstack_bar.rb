module OpenFlashChart
  class HBarStackValue < Base
    def initialize(left, right=nil, args={})
      super args
      @left = left if right
      @right = right || left
    end
  end
  class HBarStack < Base
    def initialize(colour="#9933CC", args={})
      super args
      @type = "hbar_stack"
      @colour = colour
      @values = []
    end
    def set_values(v)
      v.each do |val|
        append_value(HBarStackValue.new(val))
      end
    end
  end
end
