require 'masyu'
require 'ruby-processing'

class MasyuNode
  def pcenter
    [P.withinX(P.left + (P.unit_col / 2) + (col * P.unit_col)), P.withinY(P.top + (P.unit_row / 2) + (row * P.unit_row))]
  end

  def pdraw
    pillar.pdraw
  end
end

class MasyuEdge
  def pdraw
    if drawn? or possible?
      color = drawn? ? P.edgeline : P.possibleline
      xweight = P.withinX(P.unit_col / 7)
      yweight = P.withinY(P.unit_row / 7)

      P.fill(*color)
      P.stroke(*color)
      P.stroke_weight(up? ? yweight : xweight)
      P.stroke_join(10)
      P.stroke_cap(10)

      ax, ay = a.pcenter
      bx, by = b.pcenter
      P.line(ax, ay, bx, by)

      P.no_stroke
      P.ellipse(ax, ay, xweight, yweight)
      P.ellipse(bx, by, xweight, yweight)

      P.stroke_weight(2)
    end
  end
end

class MasyuPillar
  def pillar_radius
    [P.withinX(P.unit_col * 0.6), P.withinY(P.unit_row * 0.6)]
  end
  
  def pdraw
  end
end

class NoPillar
  def pdraw
  end
end

class BlackPillar
  def pdraw
    P.fill(*P.black)
    P.stroke(*P.black)

    x, y = node.pcenter
    rx, ry = pillar_radius

    P.ellipse(x, y, rx, ry)
  end
end

class WhitePillar
  def pdraw
    P.fill(*P.white)
    P.stroke(*P.black)

    x, y = node.pcenter
    rx, ry = pillar_radius

    P.ellipse(x, y, rx, ry)
  end
end

class MasyuProcessing < Processing::App
  attr_accessor :grid, :pillars
  attr_accessor :background, :gridline, :edgeline, :possibleline, :white, :black
  attr_accessor :left, :top, :right, :bottom
  attr_accessor :unit_col, :unit_row
  attr_accessor :solve_delay

  def setup
    @spec = OriginalCollection.new.wolf
    @grid = MasyuGrid.new(@spec.cols, @spec.rows)
    @pillars = @spec.pillars

    @grid.set_pillars(@pillars)

    @background = [100, 120, 110, 255]
    @gridline = [0, 0, 0, 255]
    @edgeline = [0, 0, 0, 255]
    @possibleline = [210, 40, 30, 255]
    @white = [240, 240, 240, 255]
    @black = [15, 15, 15, 255]

    @left, @top, @right, @bottom = 0.05, 0.05, 0.95, 0.95
    @unit_col = (@right - @left) / @grid.cols
    @unit_row = (@bottom - @top) / @grid.rows

    @solve_delay = 3
    @now = Time.now

    smooth
    frame_rate 50
    rect_mode RADIUS
  end

  def within(vf)
    [vf.first * width, vf.last * height]
  end

  def withinX(f)
    f * width
  end

  def withinY(f)
    f * height
  end

  def draw
    fill *@background
    rect 0, 0, width, height

    fill *@gridline
    stroke_weight 1
    (0..@grid.cols).each do |col|
      vert = withinX((col*@unit_col) + @left)
      line(vert, withinY(@top), vert, withinY(@bottom))
    end
    (0..@grid.rows).each do |row|
      horz = withinY((row*@unit_row) + @top)
      line(withinX(@left), horz, withinX(@right), horz)
    end

    @grid.edges.each do |edge|
      edge.pdraw
    end

    @grid.nodes.flatten.each do |node|
      node.pdraw
    end

    if (Time.now - @now) > @solve_delay
      @grid.iterate
      @now = Time.now
    end
  end
end

P = MasyuProcessing.new(:width => 500, :height => 500, :title => "masyu")

