import 'package:flutter/material.dart';

class TVListTile extends StatefulWidget {
  const TVListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.autofocus,
    this.focusNode,
    this.onFocusChange,
    this.selected = false,
    this.dense,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool? autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool selected;
  final bool? dense;

  @override
  State<TVListTile> createState() => _TVListTileState();
}

class _TVListTileState extends State<TVListTile> with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color:
            _focused
                ? colors.primaryContainer.withAlpha(145)
                : widget.selected
                ? colors.surfaceContainerHighest
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? colors.primary.withAlpha(210) : Colors.transparent,
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        dense: widget.dense,
        selected: widget.selected || _focused,
        selectedColor: colors.onPrimaryContainer,
        selectedTileColor: Colors.transparent,
        tileColor: Colors.transparent,
        enabled: widget.onTap != null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        autofocus: widget.autofocus ?? false,
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        onTap: widget.onTap,
        focusNode: widget.focusNode ?? _focusNode,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
          widget.onFocusChange?.call(focused);
        },
        title: widget.title,
        subtitle:
            widget.subtitle != null
                ? DefaultTextStyle(
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.secondary),
                  child: widget.subtitle!,
                )
                : null,
        leading: widget.leading,
        trailing: widget.trailing,
      ),
    );
  }
}

class TVRadioListTile<T> extends StatefulWidget {
  const TVRadioListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.autofocus,
    this.focusNode,
    this.onFocusChange,
    this.selected = false,
    required this.value,
    this.groupValue,
    this.onChanged,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool? autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool selected;
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  @override
  State<TVRadioListTile<T>> createState() => _TVRadioListTileState<T>();
}

class _TVRadioListTileState<T> extends State<TVRadioListTile<T>> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: _tileDecoration(colors, _focused, widget.selected),
      child: RadioListTile(
        value: widget.value,
        groupValue: widget.groupValue,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        autofocus: widget.autofocus ?? false,
        selected: widget.selected || _focused,
        selectedTileColor: Colors.transparent,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        focusNode: widget.focusNode ?? _focusNode,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
          widget.onFocusChange?.call(focused);
        },
        title: widget.title,
        subtitle:
            widget.subtitle != null
                ? DefaultTextStyle(
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.secondary),
                  child: widget.subtitle!,
                )
                : null,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class TVSwitchListTile<T> extends StatefulWidget {
  const TVSwitchListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.autofocus,
    this.focusNode,
    this.onFocusChange,
    this.selected = false,
    required this.value,
    this.onChanged,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool? autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool selected;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<TVSwitchListTile<T>> createState() => _TVSwitchListTileState<T>();
}

class _TVSwitchListTileState<T> extends State<TVSwitchListTile<T>> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: _tileDecoration(colors, _focused, widget.selected),
      child: SwitchListTile(
        value: widget.value,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        autofocus: widget.autofocus ?? false,
        selected: widget.selected || _focused,
        selectedTileColor: Colors.transparent,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        focusNode: widget.focusNode ?? _focusNode,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
          widget.onFocusChange?.call(focused);
        },
        title: widget.title,
        subtitle:
            widget.subtitle != null
                ? DefaultTextStyle(
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.secondary),
                  child: widget.subtitle!,
                )
                : null,
        onChanged: widget.onChanged,
      ),
    );
  }
}

BoxDecoration _tileDecoration(ColorScheme colors, bool focused, bool selected) {
  return BoxDecoration(
    color:
        focused
            ? colors.primaryContainer.withAlpha(145)
            : selected
            ? colors.surfaceContainerHighest
            : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: focused ? colors.primary.withAlpha(210) : Colors.transparent, width: focused ? 1.5 : 1),
  );
}
