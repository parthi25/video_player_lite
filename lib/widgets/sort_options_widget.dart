import 'package:flutter/material.dart';

enum SortOption {
  name,
  dateModified,
  size,
  duration,
}

enum SortOrder {
  ascending,
  descending,
}

class SortOptionsWidget extends StatelessWidget {
  final SortOption currentSort;
  final SortOrder currentOrder;
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<SortOrder> onOrderChanged;

  const SortOptionsWidget({
    super.key,
    required this.currentSort,
    required this.currentOrder,
    required this.onSortChanged,
    required this.onOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Sort options',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: _buildSortItem(
            context,
            'Name',
            SortOption.name,
            Icons.sort_by_alpha,
          ),
        ),
        PopupMenuItem(
          value: 'date',
          child: _buildSortItem(
            context,
            'Date Modified',
            SortOption.dateModified,
            Icons.access_time,
          ),
        ),
        PopupMenuItem(
          value: 'size',
          child: _buildSortItem(
            context,
            'File Size',
            SortOption.size,
            Icons.storage,
          ),
        ),
        PopupMenuItem(
          value: 'duration',
          child: _buildSortItem(
            context,
            'Duration',
            SortOption.duration,
            Icons.timer,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'order',
          child: _buildOrderItem(context),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'name':
            onSortChanged(SortOption.name);
            break;
          case 'date':
            onSortChanged(SortOption.dateModified);
            break;
          case 'size':
            onSortChanged(SortOption.size);
            break;
          case 'duration':
            onSortChanged(SortOption.duration);
            break;
          case 'order':
            onOrderChanged(
              currentOrder == SortOrder.ascending
                  ? SortOrder.descending
                  : SortOrder.ascending,
            );
            break;
        }
      },
    );
  }

  Widget _buildSortItem(
    BuildContext context,
    String title,
    SortOption option,
    IconData icon,
  ) {
    final isSelected = currentSort == option;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context) {
    return Row(
      children: [
        Icon(
          currentOrder == SortOrder.ascending
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          currentOrder == SortOrder.ascending ? 'Ascending' : 'Descending',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}