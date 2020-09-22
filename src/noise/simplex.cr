module Noise
	
	# from doughsay/crystal-open-simplex-noise
	
	class SimplexLayer < NoiseLayer
		STRETCH = (1 / Math.sqrt(2 + 1) - 1) / 2
		SQUISH = (Math.sqrt(2 + 1) - 1) / 2
		NORM = 47
		GRADIENTS = [5, 2, 2, 5, -5, 2, -2, 5, 5, -2, 2, -5, -5, -2, -2, -5]
		
		def extrapolate(xsb : Int32, ysb : Int32, dx : Float64, dy : Float64)
			index = @perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] & 0x0E
			g1, g2 = GRADIENTS[(index..index + 1)]
			g1 * dx + g2 * dy
		end

		def new_seed(seed : Int64) : Int64
			seed &* 6364136223846793005 &+ 1442695040888963407
		end
		
		def initialize(seed : Int64 = 0)
			@perm = Array(Int32).new(256, 0)
			
			source = (0...256).to_a
			3.times { seed = new_seed seed }
			
			source.reverse.each do |i|
				seed = new_seed seed
				r = (seed + 31) % (i + 1)
				r += i + 1 if r < 0
				@perm[i] = source[r]
				source[r] = source[i]
			end
		end
		
		def at(x : Float64, y : Float64) : Float64
			stretch_offset = (x + y) * STRETCH
			xs = x + stretch_offset
			ys = y + stretch_offset
			
			xsb = xs.floor.to_i
			ysb = ys.floor.to_i
			
			squish_offset = (xsb + ysb) * SQUISH
			xb = xsb + squish_offset
			yb = ysb + squish_offset
			
			xins = xs - xsb
			yins = ys - ysb
			
			in_sum = xins + yins
			
			dx0 = x - xb
			dy0 = y - yb
			
			value = 0_f64
			
			dx1 = dx0 - 1 - SQUISH
			dy1 = dy0 - 0 - SQUISH
			attn1 = 2 - dx1 * dx1 - dy1 * dy1
			if attn1 > 0
				attn1 *= attn1
				value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, dx1, dy1)
			end
			
			dx2 = dx0 - 0 - SQUISH
			dy2 = dy0 - 1 - SQUISH
			attn2 = 2 - dx2 * dx2 - dy2 * dy2
			if attn2 > 0
				attn2 *= attn2
				value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, dx2, dy2)
			end
			
			if in_sum <= 1 # We're inside the triangle (2-Simplex) at (0,0)
				zins = 1 - in_sum
				if zins > xins || zins > yins # (0,0) is one of the closest two triangular vertices
					if xins > yins
						xsv_ext = xsb + 1
						ysv_ext = ysb - 1
						dx_ext = dx0 - 1
						dy_ext = dy0 + 1
					else
						xsv_ext = xsb - 1
						ysv_ext = ysb + 1
						dx_ext = dx0 + 1
						dy_ext = dy0 - 1
					end
				else # (1,0) and (0,1) are the closest two vertices.
					xsv_ext = xsb + 1
					ysv_ext = ysb + 1
					dx_ext = dx0 - 1 - 2 * SQUISH
					dy_ext = dy0 - 1 - 2 * SQUISH
				end
			else # We're inside the triangle (2-Simplex) at (1,1)
				zins = 2 - in_sum
				if zins < xins || zins < yins # (0,0) is one of the closest two triangular vertices
					if xins > yins
						xsv_ext = xsb + 2
						ysv_ext = ysb + 0
						dx_ext = dx0 - 2 - 2 * SQUISH
						dy_ext = dy0 + 0 - 2 * SQUISH
					else
						xsv_ext = xsb + 0
						ysv_ext = ysb + 2
						dx_ext = dx0 + 0 - 2 * SQUISH
						dy_ext = dy0 - 2 - 2 * SQUISH
					end
				else # (1,0) and (0,1) are the closest two vertices.
					dx_ext = dx0
					dy_ext = dy0
					xsv_ext = xsb
					ysv_ext = ysb
				end
				xsb += 1
				ysb += 1
				dx0 = dx0 - 1 - 2 * SQUISH
				dy0 = dy0 - 1 - 2 * SQUISH
			end
			
			# Contribution (0,0) or (1,1)
			attn0 = 2 - dx0 * dx0 - dy0 * dy0
			if attn0 > 0
				attn0 *= attn0
				value += attn0 * attn0 * extrapolate(xsb, ysb, dx0, dy0)
			end
			
			attn_ext = 2 - dx_ext * dx_ext - dy_ext * dy_ext
			if attn_ext > 0
				attn_ext *= attn_ext
				value += attn_ext * attn_ext * extrapolate(xsv_ext, ysv_ext, dx_ext, dy_ext)
			end
			
			value / NORM / 2 + 0.5
		end
	end
end
