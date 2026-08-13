import 'package:api/api.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';

import '../../../components/placeholder.dart';
import '../../components/focusable.dart';
import '../../components/future_builder_handler.dart';
import '../../components/loading.dart';

class MediaChannel<T> extends StatelessWidget {
  const MediaChannel({
    super.key,
    required this.label,
    required this.height,
    required this.builder,
    required this.future,
    this.loadingBuilder,
    this.itemExtent,
  });

  final double? itemExtent;
  final String label;
  final double height;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Future<List<T>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderSliverHandler(
      future: future,
      loadingBuilder:
          loadingBuilder != null
              ? (context, snapshot) => Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surfaceContainerLow,
                highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GPlaceholderRect(
                        width: 100,
                        height: 18,
                        padding: EdgeInsets.only(left: 48, right: 48, top: 12),
                      ),
                      SizedBox(
                        height: height,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemExtent: itemExtent,
                          padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 12),
                          itemCount: 6,
                          itemBuilder: (context, index) => loadingBuilder!(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
      builder:
          (context, snapshot) => SliverToBoxAdapter(
            child:
                snapshot.requireData.isNotEmpty
                    ? Actions(
                      actions: {
                        DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                          onInvoke: (indent) {
                            final currentNode = FocusManager.instance.primaryFocus;
                            if (currentNode != null) {
                              final nearestScope = currentNode.nearestScope!;
                              final focusedChild = nearestScope.focusedChild;
                              switch (indent.direction) {
                                case TraversalDirection.up:
                                case TraversalDirection.down:
                                  if (focusedChild == null || !focusedChild.focusInDirection(indent.direction)) {
                                    FocusTraversalGroup.of(context).inDirection(nearestScope.parent!, indent.direction);
                                  }
                                case TraversalDirection.right:
                                case TraversalDirection.left:
                                  focusedChild?.focusInDirection(indent.direction);
                              }
                            }
                            return null;
                          },
                        ),
                      },
                      child: FocusScope(
                        onFocusChange: (f) {
                          if (f) {
                            FocusManager.instance.primaryFocus?.nearestScope?.children.first.requestFocus();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(padding: const EdgeInsets.only(left: 48, right: 48, top: 12), child: Text(label)),
                            SizedBox(
                              height: height,
                              child: ListView.builder(
                                itemExtent: itemExtent,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 12),
                                itemCount: snapshot.requireData.length,
                                itemBuilder: (context, index) => builder(context, snapshot.requireData[index]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : const SizedBox(),
          ),
    );
  }
}

class MediaGridChannel<T> extends StatefulWidget {
  const MediaGridChannel({
    super.key,
    required this.label,
    required this.itemBuilder,
    required this.onQuery,
    required this.gridDelegate,
  });

  final String label;
  final SliverGridDelegate gridDelegate;
  final ItemWidgetBuilder<T> itemBuilder;
  final Future<PageData<T>> Function(int) onQuery;

  @override
  State<MediaGridChannel<T>> createState() => _MediaGridChannelState<T>();
}

class AlphabetMediaGridChannel<T> extends StatefulWidget {
  const AlphabetMediaGridChannel({
    super.key,
    required this.label,
    required this.future,
    required this.itemBuilder,
    required this.gridDelegate,
    required this.titleOf,
    required this.alphabetKeyOf,
    required this.compare,
  });

  final String label;
  final Future<List<T>> future;
  final ItemWidgetBuilder<T> itemBuilder;
  final SliverGridDelegate gridDelegate;
  final String Function(T) titleOf;
  final String Function(String) alphabetKeyOf;
  final int Function(String, String) compare;

  @override
  State<AlphabetMediaGridChannel<T>> createState() => _AlphabetMediaGridChannelState<T>();
}

class _AlphabetMediaGridChannelState<T> extends State<AlphabetMediaGridChannel<T>> {
  String? _activeLetter;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderSliverHandler<List<T>>(
      future: widget.future,
      builder: (context, snapshot) {
        final allItems = [...snapshot.requireData]
          ..sort((a, b) => widget.compare(widget.titleOf(a), widget.titleOf(b)));
        final letters = allItems.map((item) => widget.alphabetKeyOf(widget.titleOf(item))).toSet().toList()..sort();
        final items =
            _activeLetter == null
                ? allItems
                : allItems.where((item) => widget.alphabetKeyOf(widget.titleOf(item)) == _activeLetter).toList();

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 48, right: 48, top: 12),
                child: Row(
                  children: [
                    Text('${widget.label} (${allItems.length})'),
                    const Spacer(),
                    if (_activeLetter != null)
                      Text(
                        '${_activeLetter!} · ${items.length}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 8),
                  children: [
                    _AlphabetButton(
                      label: widget.label,
                      selected: _activeLetter == null,
                      onTap: () => setState(() => _activeLetter = null),
                    ),
                    ...letters.map(
                      (letter) => _AlphabetButton(
                        label: letter,
                        selected: _activeLetter == letter,
                        onTap: () => setState(() => _activeLetter = letter),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 12),
              sliver: SliverGrid.builder(
                itemCount: items.length,
                gridDelegate: widget.gridDelegate,
                itemBuilder: (context, index) => widget.itemBuilder(context, items[index], index),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlphabetButton extends StatelessWidget {
  const _AlphabetButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Focusable(
        width: label.length > 1 ? 62 : 42,
        selected: selected,
        selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaGridChannelState<T> extends State<MediaGridChannel<T>> {
  PagingState<int, T> _state = PagingState();
  int? _count;

  Future<void> _fetchNextPage() async {
    if (_state.isLoading) return;

    await Future.value();

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = (_state.keys?.last ?? -1) + 1;
      final data = await widget.onQuery(newKey);
      final hasNextPage = data.offset + data.limit < data.count;
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            pages: [...?_state.pages, data.data],
            keys: [...?_state.keys, newKey],
            hasNextPage: hasNextPage,
            isLoading: false,
          );
          _count = data.count;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(error: error, isLoading: false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers:
          _count != 0
              ? [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48, right: 48, top: 12),
                    child: Text('${widget.label}${_count != null ? ' ($_count)' : ''}'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 12),
                  sliver: PagedSliverGrid(
                    showNewPageProgressIndicatorAsGridChild: false,
                    showNoMoreItemsIndicatorAsGridChild: false,
                    builderDelegate: PagedChildBuilderDelegate<T>(
                      itemBuilder: widget.itemBuilder,
                      noMoreItemsIndicatorBuilder:
                          (context) => const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'THE END',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      firstPageProgressIndicatorBuilder: (context) => const Loading(),
                      newPageProgressIndicatorBuilder:
                          (context) => const Padding(padding: EdgeInsets.only(top: 16), child: Loading()),
                    ),
                    gridDelegate: widget.gridDelegate,
                    fetchNextPage: _fetchNextPage,
                    state: _state,
                  ),
                ),
              ]
              : [],
    );
  }
}
