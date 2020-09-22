require "uuid"
require "yaml"

require "brs-cr"

module BRS::Islands
  struct AuthorConfig
    include YAML::Serializable

    getter username : String
    getter uuid : String

    def to_author
      BRS::User.new(username: @username, uuid: UUID.new(@uuid))
    end
  end

  class Config
    include YAML::Serializable

    property size : Int32 = 800
    property cell_size : Int32 = 2
    property simplex_scale : Float64 = 0.007
    property simplex_color_scale : Float64 = 0.014
    property terrain_scale : Int32 = 400
    property stone_threshold : Float64 = 0.01
    property falloff_height : Float64 = 0.02
    property fbm_octaves : Int32 = 7
    property author : AuthorConfig

    getter sand_color = [20]
    getter dirt_color = [17]
    getter grass_color = [24, 25, 25, 25, 26, 28, 28]
    getter stone_color = [4]
    getter mountain_stone_color = [4]
    getter snow_color = [1]

    property output_file : String = "island.brs"
  end
end
