module Noise
    abstract class NoiseLayer
        abstract def at(x : Float64, y : Float64) : Float64

        def at(x : Int32, y : Int32) : Float64
            at(x.to_f64, y.to_f64)
        end

        def *(other : NoiseLayer)
            BlockLayer.new { |x, y| at(x, y) * other.at(x, y) }
        end

        def scale(scale : Float64)
            ScaleLayer.new(self, scale)
        end

        def remap(from_min : Float64, to_min : Float64, from_max : Float64, to_max : Float64)
            RemapLayer.new(self, from_min, to_min, from_max, to_max)
        end
    end

    class BlockLayer < NoiseLayer
        def initialize(&block : (Float64, Float64) -> Float64)
            @block = block
        end

        def at(x : Float64, y : Float64) : Float64
            @block.call(x, y)
        end
    end
end
