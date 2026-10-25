import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/teemo_models.dart';

/// Card that frames one question of the assessment.
class FieldCard extends StatelessWidget {
  const FieldCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon, color: color, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Wrap of animated chips; the selected one fills with [color].
class ChoiceChips extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.color = AppColors.teal,
    this.icons,
  });

  final List<FieldOption> options;
  final Object? value;
  final ValueChanged<Object> onChanged;
  final Color color;
  final IconData Function(Object value)? icons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          _Chip(
            label: o.label,
            icon: icons?.call(o.value),
            selected: o.value == value,
            color: color,
            onTap: () => onChanged(o.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? AppColors.glow(color, strength: 0.3) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.inkSoft),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}

/// iOS-style segmented control with a sliding coloured thumb.
class SegmentedChoice extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.color = AppColors.teal,
    this.icons,
    this.height = 46,
  });

  final List<FieldOption> options;
  final Object? value;
  final ValueChanged<Object> onChanged;
  final Color color;
  final List<IconData>? icons;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == value).clamp(0, options.length - 1);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth / options.length;
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              left: w * index + 3,
              top: 3,
              width: w - 6,
              height: height - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: AppColors.glow(color, strength: 0.3),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(options[i].value);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: i == index ? Colors.white : AppColors.inkSoft,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icons != null) ...[
                                Icon(icons![i],
                                    size: 16, color: i == index ? Colors.white : AppColors.inkSoft),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(options[i].label,
                                    overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// − value + stepper with a rolling number.
class CounterField extends StatelessWidget {
  const CounterField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.unit = '',
    this.color = AppColors.teal,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          color: color,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text('$value',
                    key: ValueKey(value),
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1.1)),
              ),
              if (unit.isNotEmpty)
                Text(unit, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          color: color,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

/// Big value read-out above a slider.
class SliderField extends StatelessWidget {
  const SliderField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.unit,
    this.color = AppColors.teal,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$v',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: color, height: 1)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text('$min – $max', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            overlayColor: color.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: v.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (d) {
              if (d.round() != v) HapticFeedback.selectionClick();
              onChanged(d.round());
            },
          ),
        ),
      ],
    );
  }
}

/// Tile showing the chosen option; opens a searchable bottom sheet.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.spec,
    required this.value,
    required this.onChanged,
    required this.title,
    this.color = AppColors.teal,
  });

  final FieldSpec spec;
  final Object? value;
  final ValueChanged<Object> onChanged;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () async {
        final picked = await showModalBottomSheet<Object>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _PickerSheet(spec: spec, value: value, title: title, color: color),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(spec.labelFor(value),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
            Icon(Icons.unfold_more_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.spec, required this.value, required this.title, required this.color});

  final FieldSpec spec;
  final Object? value;
  final String title;
  final Color color;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.spec.options
        .where((o) => o.label.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (widget.spec.options.length > 8)
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final o = items[i];
                  final sel = o.value == widget.value;
                  return ListTile(
                    onTap: () => Navigator.pop(context, o.value),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: sel ? widget.color.withValues(alpha: 0.1) : null,
                    title: Text(o.label,
                        style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                    trailing: sel ? Icon(Icons.check_circle_rounded, color: widget.color) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData diagnosisIcon(Object v) => switch (v) {
      'Circulatory' => Icons.favorite_rounded,
      'Respiratory' => Icons.air_rounded,
      'Digestive' => Icons.restaurant_rounded,
      'Diabetes' => Icons.water_drop_rounded,
      'Injury' => Icons.personal_injury_rounded,
      'Musculoskeletal' => Icons.accessibility_new_rounded,
      'Genitourinary' => Icons.opacity_rounded,
      'Neoplasms' => Icons.biotech_rounded,
      'External' => Icons.emergency_rounded,
      _ => Icons.more_horiz_rounded,
    };
