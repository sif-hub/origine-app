// lib/features/genealogy/presentation/widgets/family_tree_view.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import 'family_tree_layout.dart';

class FamilyTreeView extends StatefulWidget {
  final FamilyTreeModel tree;
  final void Function(PersonModel) onNodeTap;

  const FamilyTreeView({super.key, required this.tree, required this.onNodeTap});

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final _controller = TransformationController();
  late TreeLayout _layout;
  Size _viewport = Size.zero;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _layout = computeTreeLayout(widget.tree);
  }

  @override
  void didUpdateWidget(covariant FamilyTreeView old) {
    super.didUpdateWidget(old);
    if (old.tree != widget.tree) {
      _layout = computeTreeLayout(widget.tree);
      _fitted = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit() {
    if (_viewport == Size.zero || _layout.size == Size.zero) return;
    final scale = math.min(1.0, math.min(_viewport.width / _layout.size.width, _viewport.height / _layout.size.height));
    final dx = (_viewport.width - _layout.size.width * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translate(math.max(dx, 0), 0)
      ..scale(scale);
  }

  void _zoom(double factor) {
    final current = _controller.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.25, 2.5);
    final f = target / current;
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    _controller.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(f)
      ..translate(-center.dx, -center.dy)
      ..multiply(_controller.value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tree.nodes.isEmpty) return const SizedBox.shrink();
    final byId = {for (final n in widget.tree.nodes) n.id: n};

    return LayoutBuilder(builder: (context, constraints) {
      _viewport = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_fitted) {
        _fitted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
      }
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.25,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox(
                width: _layout.size.width,
                height: _layout.size.height,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: _layout.size,
                      painter: _TreePainter(_layout),
                    ),
                    for (final entry in _layout.positions.entries)
                      Positioned(
                        left: entry.value.dx,
                        top: entry.value.dy,
                        child: GestureDetector(
                          onTap: () => widget.onNodeTap(byId[entry.key]!),
                          child: _NodeCard(person: byId[entry.key]!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _RoundButton(icon: Icons.add, onTap: () => _zoom(1.25)),
                const SizedBox(height: 6),
                _RoundButton(icon: Icons.remove, onTap: () => _zoom(0.8)),
                const SizedBox(height: 6),
                _RoundButton(icon: Icons.fit_screen, onTap: _fit),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blanc,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.vertForet),
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final TreeLayout layout;
  _TreePainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.vertForet.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final dashed = Paint()
      ..color = AppColors.gris.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final marriage = Paint()
      ..color = AppColors.or
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final c in layout.connectors) {
      final path = Path()
        ..moveTo(c.from.dx, c.from.dy)
        ..lineTo(c.from.dx, c.busY)
        ..lineTo(c.to.dx, c.busY)
        ..lineTo(c.to.dx, c.to.dy);
      if (c.secondary) {
        _drawDashed(canvas, path, dashed);
      } else {
        canvas.drawPath(path, line);
      }
    }

    for (final (a, b) in layout.marriages) {
      canvas.drawLine(a, b, marriage);
      final mid = Offset((a.dx + b.dx) / 2, a.dy);
      canvas.drawCircle(mid, 5, Paint()..color = AppColors.or);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) => old.layout != layout;
}

class _NodeCard extends StatelessWidget {
  final PersonModel person;
  const _NodeCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final color = person.sexe == 'M'
        ? AppColors.vertForet
        : person.sexe == 'F'
            ? AppColors.erreur
            : AppColors.gris;
    final initial = person.nomComplet.isNotEmpty ? person.nomComplet[0].toUpperCase() : '?';

    return Container(
      width: kNodeW,
      height: kNodeH,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: person.vivant ? AppColors.blanc : const Color(0xFFF1EEE9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.nomComplet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  person.dateNaissance != null ? person.annees : '—',
                  style: const TextStyle(fontSize: 10, color: AppColors.gris),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
