module Noise
    class RemapLayer < NoiseLayer
        def initialize(@layer : NoiseLayer, @from_min : Float64, @from_max : Float64, @to_min : Float64, @to_max : Float64)
        end

        def at(x : Float64, y : Float64) : Float64
            value = @layer.at(x, y)
            (value - @from_min) / (@from_max - @from_min) * (@to_max - @to_min) + @to_min
        end
    end
end
