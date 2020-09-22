require "./noise.cr"
require "brs-cr"

require "./brs-islands/config.cr"
require "./brs-islands/tasks.cr"

include BRS::Islands

task_list = TaskList.new
task_list << "Initialized noisemap"
task_list << "Baked noisemap"
task_list << "Reduced neighbor brick heights"
task_list << "Wrote bricks to memory"
task_list << "Wrote bricks to save, done"

config = Config.from_yaml File.read("config.yml")

me = config.author.to_author

save = BRS::Save.new(
  author: me,
  description: "islands"
)

save.brick_assets = ["PB_DefaultBrick", "PB_DefaultTile"]
save.brick_owners << me

# this layer controls the distance from the center of the island
distance_layer = Noise::DistanceLayer.new(config.size / 2 - 4, config.size / 2 - 4)

# this layer controls the actual terrain heightmap (not island)
mixed_noise_layer = Noise::FractalBrownianMotionLayer.new(Noise::SimplexLayer.new(Random.rand(Int64)), config.fbm_octaves).scale(config.simplex_scale)

# this layer controls the offset at which certain terrain colors (sand, grass, stone, snow) can begin appearing
terrain_color_offset_layer = Noise::SimplexLayer.new(Random.rand(Int64)).scale(config.simplex_color_scale).remap(0.0, 1.0, -0.1, 0.1)

island_layer = distance_layer * mixed_noise_layer

task_list.complete_next_task

struct TerrainCell
  property noise_value : Float64
  property value : Int32
  property brick_height : Int32

  def initialize(@noise_value, @value, @brick_height)
  end
end

terrain_cells = [] of Array(TerrainCell)

# bake heights
config.size.times do |yi|
  terrain_cells << [] of TerrainCell
  config.size.times do |xi|
    x = xi + yi % 2 / 2
    y = yi
    nx, ny = x - config.size / 2, y - config.size / 2
    noise_height = island_layer.at(nx, ny)
    height = (noise_height * config.terrain_scale * 10 / 4).floor * 4

    cell = TerrainCell.new(noise_height, noise_height < config.falloff_height ? 0 : height.to_i32, 0)
    terrain_cells[-1] << cell
  end
end

task_list.complete_next_task

# check neighbors and change brick height
terrain_cells.each_with_index do |y_cells, y|
  y_cells.each_with_index do |x_cell, x|
    neighbor_ids = [{x + 1, y}, {x - 1, y}, {x + y % 2, y + 1}, {x + y % 2, y - 1}, {x - 1 + y % 2, y + 1}, {x - 1 + y % 2, y - 1}]
    neighbors = [] of TerrainCell
    neighbor_ids.not_nil!.each do |(nx, ny)|
      if nx < 0 || ny < 0 || ny >= terrain_cells.size || nx >= terrain_cells[ny].size
        neighbors << TerrainCell.new(0_f64, 0, 0)
        next
      end
      n = terrain_cells[ny][nx]
      neighbors << n unless n.value > x_cell.value
    end
    max = neighbors.map { |n| (n.value - x_cell.value).abs }.max? || 0
    terrain_cells[y][x] = TerrainCell.new(x_cell.noise_value, x_cell.value, Math.max(4, max // 2))
  end
end

task_list.complete_next_task

config.size.times do |yi|
  config.size.times do |xi|
    x = xi + yi % 2 / 2
    y = yi

    cell = terrain_cells[yi][xi]
    noise_height = cell.noise_value

    nx, ny = x - config.size / 2, y - config.size / 2

    position = BRS::Vector3.new((x * 10 * config.cell_size).floor.to_i32, (y * 10 * config.cell_size).floor.to_i32, cell.value - cell.brick_height)

    next if noise_height < config.falloff_height

    # roughly determine the gradient of the point (this is bad lol)
    grad_points = [island_layer.at(nx + 1, ny), island_layer.at(nx, ny + 1), island_layer.at(nx - 1, ny), island_layer.at(nx, ny - 1)]
    grad = grad_points.map { |point| (noise_height - point).abs }.max

    if noise_height < 0.08 + terrain_color_offset_layer.at(nx, ny) * 0.35
      # render as sand
      save.bricks << BRS::Brick.new(
        size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, cell.brick_height),
        position: position,
        color_index: config.sand_color.sample,
        asset_name_index: 1,
        owner_index: 0_u32
      )
    elsif noise_height < 0.49 + terrain_color_offset_layer.at(nx, ny)
      # render as grass (or stone)

      if grad > config.stone_threshold
        # render as stone
        save.bricks << BRS::Brick.new(
          size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, cell.brick_height),
          position: position,
          color_index: config.stone_color.sample,
          owner_index: 0_u32
        )
      else
        # render as grass
        save.bricks << BRS::Brick.new(
          size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, cell.brick_height - 2),
          position: position + BRS::Vector3.new(0, 0, -2),
          color_index: config.dirt_color.sample,
          owner_index: 0_u32
        )
    
        save.bricks << BRS::Brick.new(
          size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, 2),
          position: save.bricks[-1].position + BRS::Vector3.new(0, 0, 2 + save.bricks[-1].size.z),
          color_index: config.grass_color.sample,
          asset_name_index: 1,
          owner_index: 0_u32
        )
      end

    elsif noise_height < 0.52 + terrain_color_offset_layer.at(nx, ny)
      save.bricks << BRS::Brick.new(
        size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, cell.brick_height),
        position: position,
        color_index: config.mountain_stone_color.sample,
        asset_name_index: 1,
        owner_index: 0_u32
      )
    else
      # render as snow
      save.bricks << BRS::Brick.new(
        size: BRS::UVector3.new(5 * config.cell_size, 5 * config.cell_size, cell.brick_height),
        position: position,
        color_index: config.snow_color.sample,
        asset_name_index: 1,
        owner_index: 0_u32
      )
    end
  end
end

task_list.complete_next_task

save.write(File.new(config.output_file, mode: "w"))

task_list.complete_next_task
