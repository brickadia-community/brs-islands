module Noise
    class FractalBrownianMotionLayer < NoiseLayer
        def initialize(@noise : NoiseLayer, @octaves : Int32 = 6)
        end

        def at(x : Float64, y : Float64) : Float64
            value = 0_f64
            amplitude = 0.5
            frequency = 0_f64
            st = 1

            @octaves.times do |i|
                value += amplitude * @noise.at(x * st, y * st)
                st *= 2
                amplitude *= 0.5
            end

            value
        end
    end
end
