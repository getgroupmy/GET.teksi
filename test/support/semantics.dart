import 'package:flutter/semantics.dart';

/// What a screen reader is handed, shared by the gates that ask about it.
///
/// Lifted out of semantics_test.dart when empty_states_test.dart needed
/// the same question asked of the same screens with nothing in them. A
/// second copy would drift from the first the next time the definition of
/// "a control" changed, which is the argument support/screens.dart already
/// makes for the screen list itself.

/// Every node in the tree, in traversal order.
List<SemanticsNode> flattenSemantics(SemanticsNode root) {
  final out = <SemanticsNode>[];
  void walk(SemanticsNode node) {
    out.add(node);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return out;
}

/// Whether [node] says anything a screen reader could read out.
///
/// A node earns its label from any of these, so all three count: `label` for
/// a `Semantics` wrapper or a tooltip, `value` for a field's contents, and
/// `tooltip` where the platform keeps it separate.
bool announcesSomething(SemanticsNode node) =>
    node.label.trim().isNotEmpty ||
    node.value.trim().isNotEmpty ||
    node.tooltip.trim().isNotEmpty;

/// The nodes a screen reader would stop on and call a control.
List<SemanticsNode> controls(SemanticsNode root) =>
    flattenSemantics(root)
        .where(
          (n) =>
              n.flagsCollection.isButton ||
              n.flagsCollection.isLink ||
              n.flagsCollection.isTextField,
        )
        .toList();

/// A description that says where to look, rather than just that something is
/// wrong. The rect is the only locator a dropped node leaves behind.
String describeNode(SemanticsNode node) {
  final kinds = [
    if (node.flagsCollection.isButton) 'button',
    if (node.flagsCollection.isLink) 'link',
    if (node.flagsCollection.isTextField) 'text field',
  ].join('/');
  return '$kinds at ${node.rect} (id ${node.id})';
}
