module Noise
    class ScaleLayer < NoiseLayer
        def initialize(@layer : NoiseLayer, @scale : Float64)
        end

        def at(x : Float64, y : Float64) : Float64
            @layer.at(x * @scale, y * @scale)
        end
    end
end
