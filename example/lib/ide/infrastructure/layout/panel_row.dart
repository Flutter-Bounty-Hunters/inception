import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

/// A row-oriented layout widget, similar to `Row`, which adds additional control
/// over how children size themselves in relation to one another when there isn't
/// enough space.
///
/// All [children] must either be [DesiredSizePanel]s or [ExpandedPanel]s. These
/// widgets set policies for how they're sized within a [PanelRow].
///
/// An [ExpandedPanel] is sized similar to an `Expanded` widget within a `Row`.
/// However, an [ExpandedPanel] can define a minimum extent, which is the smallest
/// that the [ExpandedPanel] will ever be, regardless of available space.
///
/// A [DesiredSizePanel] attempts to take up a given desired extent. If there's not
/// enough space for fit the panel at that extent, then all [DesiredSizePanel]s
/// are reduced in size, proportional to each of their desired sizes. For example,
/// if the [DesiredSizedPanel]s needs to shrink, and one panel wants to be 400px,
/// and another wants to be 200px, then the shrunken versions of the [DesiredSizePanel]s
/// will retain the 2:1 ratio of their desired sizes.
///
/// [DesiredSizePanel]s also accept an optional minimum extent, which overrides the
/// proportional scaling that would otherwise apply.
class PanelRow extends MultiChildRenderObjectWidget {
  const PanelRow({
    super.key,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPanelRow();
  }
}

class RenderPanelRow extends RenderBox with ContainerRenderObjectMixin<RenderBox, PanelRowParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData == null) {
      throw Exception(
          "PanelRow child is missing its PanelRowParentData - did you remember to wrap your widget with DesiredSizePanel or ExpandedPanel?");
    }
  }

  @override
  void performLayout() {
    final desiredSizeChildren = <RenderBox>[];
    final expandedChildren = <RenderBox>[];

    // Sort all children between those that have a desired size and those
    // that expand to fill available space.
    var child = firstChild;
    while (child != null) {
      if (child.parentData!.asPanelRow.isExpanded) {
        expandedChildren.add(child);
      } else {
        desiredSizeChildren.add(child);
      }

      child = childAfter(child);
    }

    // Sort the children with desired sizes based on their layout order.
    // Children with lower layout orders will be given available space first.
    desiredSizeChildren.sort((a, b) => a.parentData!.asPanelRow.layoutOrder! - b.parentData!.asPanelRow.layoutOrder!);
  }
}

class DesiredSizePanel extends ParentDataWidget<PanelRowParentData> {
  const DesiredSizePanel({
    super.key,
    required this.layoutOrder,
    required this.desiredExtent,
    this.minimumExtent = 0,
    required super.child,
  }) : assert(minimumExtent >= 0, "Minimum extent must be >= 0 - can't have negative sizes.");

  final int layoutOrder;
  final double desiredExtent;
  final double minimumExtent;

  @override
  void applyParentData(RenderObject renderObject) {
    renderObject.parentData = PanelRowParentData.desiredSize(
      layoutOrder: layoutOrder,
      desiredExtent: desiredExtent,
      minimumExtent: minimumExtent,
    );
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PanelRow;
}

class ExpandedPanel extends ParentDataWidget<PanelRowParentData> {
  const ExpandedPanel({
    super.key,
    required this.flex,
    this.minimumExtent = 0,
    required super.child,
  }) : assert(minimumExtent >= 0, "Minimum extent must be >= 0 - can't have negative sizes.");

  final int flex;
  final double minimumExtent;

  @override
  void applyParentData(RenderObject renderObject) {
    renderObject.parentData = PanelRowParentData.expanded(
      flex: flex,
      minimumExtent: minimumExtent,
    );
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PanelRow;
}

class PanelRowParentData extends ParentData with ContainerParentDataMixin<RenderBox> {
  PanelRowParentData.desiredSize({
    required this.layoutOrder,
    required this.desiredExtent,
    this.minimumExtent = 0,
  })  : isExpanded = false,
        flex = null;

  PanelRowParentData.expanded({
    this.flex = 1,
    this.minimumExtent = 0,
  })  : isExpanded = true,
        layoutOrder = null,
        desiredExtent = null;

  /// The layout order of this child in the [PanelRow] layout - children with lower
  /// layout orders take up [desiredExtent] first, followed by children with higher
  /// layout orders.
  ///
  /// If [isExpanded] is `true`, then [layoutOrder] is `null`, because expanded
  /// children, by definition, compute their extent after all other children.
  final int? layoutOrder;

  /// The extent (e.g., width) of this child when there's enough space to fit everything.
  ///
  /// If [isExpanded] is `true`, then [desiredExtent] is `null`.
  final double? desiredExtent;

  /// The extent (e.g., width) of this child when it's as small as possible.
  final double minimumExtent;

  /// Whether this child should expand to fill all available space.
  final bool isExpanded;

  /// The flex factor of this child, if [isExpanded] is `true`.
  ///
  /// If [isExpanded] is false, [flex] is `null`.
  final int? flex;
}

extension on ParentData {
  PanelRowParentData get asPanelRow => this as PanelRowParentData;
}
