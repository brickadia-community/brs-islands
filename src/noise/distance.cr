module Noise
    class DistanceLayer < NoiseLayer
        def initialize(@dx : Float64, @dy : Float64)
        end

        def at(x : Float64, y : Float64) : Float64
            px = x / @dx
            py = y / @dy
            Math.max(0_f64, 1_f64 - Math.sqrt(px * px + py * py))
        end
    end

    class MaxDimensionLayer < NoiseLayer
        def initialize(@dx : Float64, @dy : Float64)
        end

        def at(x : Float64, y : Float64) : Float64
            px = (x / @dx).abs
            py = (y / @dy).abs
            Math.max(0_f64, 1_f64 - Math.max(px, py))
        end
    end
end
