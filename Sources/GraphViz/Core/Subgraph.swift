import struct Foundation.URL

@dynamicMemberLookup
public struct Subgraph: Hashable {
    public var id: String?

    public init(id: String? = nil) {
        self.id = id
    }

    /// Subgraphs contained by the subgraph.
    public private(set) var subgraphs: [Subgraph] = []

    public private(set) var nodes: [Node] = []

    public private(set) var edges: [Edge] = []

    public private(set) var attributes: Attributes = Attributes()

    /**
     Returns whether the subgraph is empty.

     A subgraph is considered to be empty if it
     has no subgraphs,
     has no edges,
     has no nodes with attributes, and
     has no attributes itself.
     */
    public var isEmpty: Bool {
        return subgraphs.isEmpty &&
                edges.isEmpty &&
                attributes.dictionaryValue.isEmpty &&
                nodes.filter { !$0.attributes.dictionaryValue.isEmpty }.isEmpty
    }

    public mutating func append(_ subgraph: Subgraph) {
        subgraphs.append(subgraph)
    }

    public mutating func append<S>(contentsOf subgraphs: S) where S.Element == Subgraph, S: Sequence {
        for subgraph in subgraphs {
            self.subgraphs.append(subgraph)
        }
    }
    
    public mutating func append(_ node: @autoclosure () -> Node) {
        nodes.append(node())
    }
    
    public mutating func append<S>(contentsOf nodes: S) where S.Element == Node, S: Sequence {
        for node in nodes {
            self.nodes.append(node)
        }
    }

    public mutating func append(_ edge: @autoclosure () -> Edge) {
        edges.append(edge())
    }
    
    public mutating func append<S>(contentsOf edges: S) where S.Element == Edge, S: Sequence {
        for edge in edges {
            self.edges.append(edge)
        }
    }

    public subscript<T>(dynamicMember member: WritableKeyPath<Attributes, T>) -> T {
        get {
            return attributes[keyPath: member]
        }

        set {
            attributes[keyPath: member] = newValue
        }
    }

}

// MARK: -

extension Subgraph {
    /**
     Rank constraints on the nodes in a subgraph. If rank="same", all nodes are placed on the same rank. If rank="min", all nodes are placed on the minimum rank. If rank="source", all nodes are placed on the minimum rank, and the only nodes on the minimum rank belong to some subgraph whose rank attribute is "source" or "min". Analogous criteria hold for rank="max" and rank="sink". (Note: the minimum rank is topmost or leftmost, and the maximum rank is bottommost or rightmost.)
     */
    public enum Rank: String {
        case same
        case min
        case max
        case sink
        case source
    }

    public enum Style: Hashable {
        case solid
        case dashed
        case dotted
        case bold
        case rounded
        case filled(Color)
        case striped([Color])
        case compound([Style])

        public var colors: [Color]? {
            switch self {
            case .filled(let color):
                return [color]
            case .striped(let colors):
                return colors
            case .compound(let styles):
                return styles.compactMap { $0.colors }.flatMap { $0 }
            default:
                return nil
            }
        }
    }

    public struct Attributes: Hashable {
        /// Unofficial, but supported by certain output formats, like svg.
        @Attribute("class")
        public var `class`: String?

        /**
         If the value of the attribute is "out", then the outedges of a node, that is, edges with the node as its tail node, must appear left-to-right in the same order in which they are defined in the input. If the value of the attribute is "in", then the inedges of a node must appear left-to-right in the same order in which they are defined in the input. If defined as a graph or subgraph attribute, the value is applied to all nodes in the graph or subgraph. Note that the graph attribute takes precedence over the node attribute.
         */
        @Attribute("ordering")
        public var ordering: Ordering?

        /**
         If packmode indicates an array packing, this attribute specifies an insertion order among the components, with smaller values inserted first.
         > GCN    int    0    0
         */
        @Attribute("sortvalue")
        public var sortValue: Int?

        // MARK: - Appearance Attributes

        @Attribute("shape")
        public var shape: Node.Shape?

        /// > Defines the graphic style on an object.
        @Attribute("style")
        public var style: Style? {
            willSet {
                self.fillColors = newValue?.colors
            }
        }

        /**
         The node size set by height and width is kept fixed and not expanded to contain the text label.
         */
        @Attribute("size")
        public var size: Size?
        /// > The shape of a node.

        /// > When attached to the root graph, this color is used as the background for entire canvas. For a cluster, it is used as the initial background for the cluster. If a cluster has a filled style, the cluster's fillcolor will overlay the background color.
        @Attribute("bgcolor")
        public var backgroundColor: Color?

        /// > Basic drawing color for graphics.
        /// penColor
        /// Color used to draw the bounding box around a cluster. If pencolor is not defined, color is used. If this is not defined, bgcolor is used. If this is not defined, the default is used.
        /// Note that a cluster inherits the root graph's attributes if defined. Thus, if the root graph has defined a pencolor, this will override a color or bgcolor attribute set for the cluster.
        @Attribute("pencolor")
        public var borderColor: Color?

        /**
         penwidth
         Specifies the width of the pen, in points, used to draw lines and curves, including the boundaries of edges and clusters. The value is inherited by subclusters. It has no effect on text.
         */
        @Attribute("penwidth")
        public var borderWidth: Double?

        @Attribute("fillcolor")
        private var fillColors: [Color]?

        /// - Important: Setting fillColor sets `style` to .filled;
        ///              setting `nil` fillColor sets `style` to `nil`
        public var fillColor: Color? {
            get {
                guard let colors = style?.colors else { return nil }
                return colors.count == 1 ? colors.first : nil
            }

            set {
                if let color = newValue {
                    style = .filled(color)
                } else {
                    style = nil
                }
            }
        }

        // MARK: - Link Attributes

        ///
        @Attribute("href")
        public var href: String?

        ///
        @Attribute("URL")
        public var url: URL?

        // MARK: - Label Attributes
        
        /**
         > Text label attached to objects. Different from ids labels can contain almost any special character, but not ".

         If a node does not have the attribute label, the value of the attribute id is used. If a node shall not have a label, label="" must be used.

         The escape sequences "\n", "\l" and "\r" divide the label into lines, centered, left-justified and right-justified, respectively.

         Change the appearance of the labels with the attributes fontname, fontcolor and fontsize.
         */
        @Attribute("label")
        public var label: String?

        /// > The name of the used font. (System dependend)
        /// > The font size for object labels.
        @Attribute("fontname")
        public var fontName: String?

        @Attribute("fontsize")
        public var fontSize: Double?

        /// > The font color for object labels.
        @Attribute("fontcolor")
        public var textColor: Color?

        /// > If true, allows edge labels to be less constrained in position. In particular, it may appear on top of other edges
        @Attribute("labelfloat")
        var labelFloat: Bool?

        /**
         By default, the justification of multi-line labels is done within the largest context that makes sense. Thus, in the label of a polygonal node, a left-justified line will align with the left side of the node (shifted by the prescribed margin). In record nodes, left-justified line will line up with the left side of the enclosing column of fields. If nojustify is "true", multi-line labels will be justified in the context of itself. For example, if the attribute is set, the first label line is long, and the second is shorter and left-justified, the second will align with the left-most character in the first line, regardless of how large the node might be.
         */
        @Attribute("nojustify")
        public var noJustify: Bool?

        // MARK: - Attributes Affecting Edges


        /**
         If false, the edge is not used in ranking the nodes.

         Normally, edges are used to place the nodes on ranks. In the second graph below, all nodes were placed on different ranks. In the first example, the edge b -> c does not add a constraint during rank assignment, so the only constraints are that a be above b and c.
         */
        @Attribute("constraint")
        var constraint: Bool?

        /**
         If true, the edge label is attached to the edge by a 2-segment polyline, underlining the label, then going to the closest point of spline.
         */
        @Attribute("decorate")
        var decorate: Bool?


        /// Multiplicative scale factor for arrowheads.
        @Attribute("arrowsize")
        var arrowSize: Double?

        @Attribute("arrowhead")
        var head: Edge.Arrow?

        @Attribute("arrowtail")
        var tail: Edge.Arrow?


        //        /**
        //         Set number of peripheries used in polygonal shapes and cluster boundaries. Note that user-defined shapes are treated as a form of box shape, so the default peripheries value is 1 and the user-defined shape will be drawn in a bounding rectangle. Setting peripheries=0 will turn this off. Also, 1 is the maximum peripheries value for clusters.
        //         > NC    int    shape default(nodes)
        //         1(clusters)    0
        //         */
        //        @Attribute("peripheries")
        //        public var peripheries: Int?



        // MARK: - Layout-specific Attributes

        // MARK: dot

        /**
         Rank constraints on the nodes in a subgraph. If rank="same", all nodes are placed on the same rank. If rank="min", all nodes are placed on the minimum rank. If rank="source", all nodes are placed on the minimum rank, and the only nodes on the minimum rank belong to some subgraph whose rank attribute is "source" or "min". Analogous criteria hold for rank="max" and rank="sink". (Note: the minimum rank is topmost or leftmost, and the maximum rank is bottommost or rightmost.)

         > dot only
         */
        @Attribute("rank")
        public var rank: Rank?

        // MARK: patchwork

        /// Indicates the preferred area for a node or empty cluster when laid out by patchwork.
        /// 1.0    >0    patchwork only
        @Attribute("area")
        public var area: Double?
    }
}

extension Subgraph.Attributes {
    var arrayValue: [Attributable] {
        return [
            _class,
            _ordering,
            _sortValue,
            _shape,
            _style,
            _size,
            _backgroundColor,
            _fillColors,
            _borderColor,
            _borderWidth,
            _href,
            _url,
            _fontName,
            _fontSize,
            _textColor,
            _label,
            _labelFloat,
            _noJustify,
            _constraint,
            _decorate,
            _arrowSize,
            _head,
            _tail,
            _rank,
            _area
        ]
    }

    public var dictionaryValue: [String: Any] {
        return Dictionary(uniqueKeysWithValues: arrayValue.map { ($0.name, $0.typeErasedWrappedValue) }
        ).compactMapValues { $0 }
    }
}
