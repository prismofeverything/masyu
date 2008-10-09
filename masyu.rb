def implies(a, b)
  !a or (a and b)
end

class MasyuNode
  attr_reader :col, :row, :grid, :edges

  def initialize(grid, col, row)
    @grid = grid
    @col = col
    @row = row
    @edges = {}
    @pillar = NoPillar.new(self)
  end

  def pillar
    @pillar
  end

  def pillar=(pillar_type)
    @pillar = pillar_type.new(self)
  end

  def preceding
    before = []

    if col > 0
      precol = relative(-1, 0)
      before << edges[precol] ||= MasyuEdge.new(self, precol, true)
    end
    if row > 0
      prerow = relative(0, -1)
      before << edges[prerow] ||= MasyuEdge.new(self, prerow, false)
    end

    before
  end

  def direction(other)
    [other.col - col, other.row - row]
  end

  def relative(c, r)
    grid.node(col+c, row+r)
  end

  def tell_about(edge)
    edges[edge.other(self)] = edge
  end

  def drawn_edges
    edges.select{|other, edge| edge.drawn?}.map{|other, edge| edge}
  end

  def possible_edges
    edges.select{|other, edge| edge.possible?}.map{|other, edge| edge}
  end

  def draw
    pillar.draw
  end

  def to_s
    "#{pillar.to_s}: #{col},#{row}"
  end
end

class MasyuEdge
  attr_reader :a, :b
  attr_accessor :possible

  def initialize(a, b, up)
    @a = a
    @b = b
    @up = up
    @possible = true
    @drawn = false
  end

  def other(node)
    (node == a) ? b : a
  end

  def up?
    @up
  end

  def possible?
    @possible
  end

  def direction(node)
    other = other(node)
    [other.col - node.col, other.row - node.row]
  end

  def opposes?(edge)
    edge.nil? ? false : (self.up? ^ edge.up?)
  end

  def reflection(node)
    node.edges.find{|other, edge| (edge != self) and !edge.opposes?(self)}.last
  end

  def continue(node)
    col, row = direction(node)
    o = other(node)
    to = a.grid.node(o.col + col, o.row + row)
    o.edges[to]
  end

  def continues_from?(node)
    cont = continue(node)
    cont.nil? ? false : (self.drawn? and cont.drawn?)
  end

  def turns?(node)
    drawn = other(node).drawn_edges
    drawn.size == 2 and drawn.first.opposes?(drawn.last)
  end

  def drawn?
    @drawn
  end

  def draw
    @drawn = true
  end

  def erase
    @drawn = false
  end

  def to_s
    "(#{a.col},#{a.row} - #{b.col},#{b.row}): #{drawn? ? 'drawn' : ''} #{possible? ? 'possible' : ''}"
  end

  def console
    self.possible? ? (self.drawn? ? (self.up? ? '|' : '-') : ' ') : (self.drawn? ? (self.up? ? '"' : '=') : '*') 
  end
end

class MasyuPillar
  attr_reader :node
  attr_accessor :valid

  def initialize(node)
    @node = node
  end

  def number_drawn
    node.edges.select{|other, edge| edge.drawn?}.size
  end

  def complete?
    true
  end

  def empty?
    false
  end

  def possible?(edge)
    true
  end

  def valid?
    @valid
  end

  def check_possibilities
    node.edges.inject({}) do |possibilities, rel|
      other, edge = rel
      p = possible?(edge)

      edge.possible &= p
      possibilities.merge(edge => p)
    end
  end

  def draw

  end

  def trigger
  end

  def console
  end

  def to_s
    console
  end
end

class NoPillar < MasyuPillar
  def complete?
    drawn = number_drawn
    drawn % 2 == 0
  end

  def empty?
    true
  end

  def possible?(edge)
    drawn = number_drawn
    (drawn == 0) or (drawn == 1) or (drawn == 2 and edge.drawn?)
  end

  def draw
    drawn = node.drawn_edges
    possible = node.possible_edges

    if drawn.size == 1
      left = possible - drawn
      left.first.draw if left.size == 1
    end
  end

  def console
    complete? ? '#' : "+"
  end
end

class BlackPillar < MasyuPillar
  def complete?
    drawn = node.drawn_edges
    size = drawn.size

    (size == 2) and (drawn.first.opposes?(drawn.last)) and drawn.inject(true){|whole, edge| whole and edge.continues_from?(node)}
  end

  def other_opposes?(edge)
    edge.other(node).drawn_edges.any?{|drawn| drawn.opposes?(edge)}
  end

  def tail_exists?(edge)
    other = edge.other(node)
    col, row = node.direction(other)
    node.grid.node(node.col + col*2, node.row + row*2)
  end

  def possible?(edge)
    drawn = node.drawn_edges
    size = drawn.size
    
    case size
      when 0: !other_opposes?(edge) and tail_exists?(edge)
      when 1: !other_opposes?(edge) and tail_exists?(edge) and (edge.drawn? or edge.opposes?(drawn.first))
      when 2: !other_opposes?(edge) and tail_exists?(edge) and edge.drawn? and drawn.first.opposes?(drawn.last)
      else false
    end
  end

  def console
    complete? ? '$' : '@'
  end

  def draw
    drawn = node.drawn_edges
    possible = node.possible_edges

    (possible - drawn).partition{|edge| edge.up?}.select{|edges| edges.size == 1}.each do |e|
      edge = e.first
      edge.draw
      edge.continue(node).draw
    end
  end
end

class WhitePillar < MasyuPillar
  def complete?
    drawn = node.drawn_edges
    drawn.size == 2 and !drawn.first.opposes?(drawn.last) and (drawn.first.turns?(node) or drawn.last.turns?(node))
  end

  def through?(edge)
    node.edges.select{|n, other| edge.up? == other.up?}.size == 2
  end

  def possible?(edge)
    drawn = node.drawn_edges

    case drawn.size
      when 0: through?(edge)
      when 1: through?(edge) and !edge.oppose(drawn.first)
      when 2: 
        if edge.continues_from?(node)
          puts "setting reflection of continuing edge to not possible #{edge.to_s}"
          reflection = edge.reflection(node)
          continue = reflection.continue(node)
          puts "reflection -- #{reflection.to_s}, continue -- #{continue.to_s}"
          reflection = edge.reflection(node).continue(node)
          reflection.possible = false unless reflection.nil?
        end
        edge.drawn? and !drawn.first.opposes?(drawn.last)
      else false
    end
  end

  def draw
    drawn = node.drawn_edges
    possible = node.possible_edges

    case drawn.size
      when 0:
        if possible.size < 4
          if possible.size < 2
            @valid = false
          else
            to_draw = possible.partition{|p| p.up?}.find{|p| p.size == 2}
            to_draw.each{|to| to.draw}
          end
        end
      else
    end
  end

  def console
    complete? ? '%' : 'O'
  end
end

class MasyuPath
  
end

class MasyuGrid
  attr_reader :cols, :rows, :nodes, :edges

  def initialize(cols, rows)
    @cols = cols
    @rows = rows

    make_nodes
    make_edges
  end

  def make_nodes
    @nodes = (0...cols).map do |col|
      (0...rows).map do |row|
        MasyuNode.new(self, col, row)
      end
    end
  end

  def make_edges
    @edges = nodes.flatten.inject([]) do |made, node|
      pre = node.preceding
      pre.each do |edge|
        edge.other(node).tell_about(edge)
      end
      
      made + pre
    end
  end

  def edge_for(a, b)
    a.edges[b]
  end

  def in_bounds(high, value)
    value >= 0 and value < high
  end

  def node(col, row)
    (in_bounds(cols, col) and in_bounds(rows, row)) ? nodes[col][row] : nil
  end

  def set_pillars(pillars)
    pillars.each do |col, row, pillar|
      self.node(col, row).pillar = pillar
    end
  end

  def check_possibilities
    nodes.flatten.each do |node|
      node.pillar.check_possibilities
    end
  end

  def draw
    nodes.flatten.each do |n|
      n.draw
    end
  end

  def total_drawn
    edges.inject(0){|total, edge| total + (edge.drawn? ? 1 : 0)}
  end

  def solve
    total = -1
    while total < total_drawn
      puts console

      total = total_drawn
      check_possibilities
      draw
    end
  end

  def to_s
    console
  end

  def console
    nodes.map do |col|
      edgerow = ''
      row = ''
      col.each do |node|
        up, over = node.preceding.partition{|edge| edge.up?}
        up.each do |u|
          edgerow += ' ' unless over.empty?
          edgerow += u.console
        end
        over.each{|o| row += o.console}

        row += node.pillar.console
      end
      [edgerow, row].join("\n")
    end.join("\n")
  end
end

def argest
  grid = MasyuGrid.new(5, 5)

  pillars = [[1, 1, WhitePillar],
             [3, 4, BlackPillar]]
  grid.set_pillars(pillars)

  grid.edge_for(grid.node(2,1), grid.node(2,2)).draw
  grid.edge_for(grid.node(2,3), grid.node(2,2)).draw
  grid.edge_for(grid.node(1,4), grid.node(2,4)).draw
  grid.edge_for(grid.node(2,4), grid.node(3,4)).draw
  grid.edge_for(grid.node(3,2), grid.node(3,3)).draw
  grid.edge_for(grid.node(3,3), grid.node(3,4)).draw
  grid.edge_for(grid.node(1,0), grid.node(1,1)).draw
  grid.edge_for(grid.node(1,1), grid.node(1,2)).draw
  grid.edge_for(grid.node(1,2), grid.node(0,2)).draw
  grid.check_possibilities

  puts grid.console
end

def test
  grid = MasyuGrid.new(4, 4)

  pillars = [[2, 0, BlackPillar], 
             [0, 2, WhitePillar], 
             [2, 3, WhitePillar]]
  grid.set_pillars(pillars)

  grid.solve
  puts grid.console
end

test
