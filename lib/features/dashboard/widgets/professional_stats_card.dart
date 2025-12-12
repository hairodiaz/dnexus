import 'package:flutter/material.dart';

class ProfessionalStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final String? trend;
  final bool isPositiveTrend;
  final double? percentage;
  final List<double>? chartData;
  final VoidCallback? onTap;

  const ProfessionalStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.primaryColor,
    this.secondaryColor,
    this.trend,
    this.isPositiveTrend = true,
    this.percentage,
    this.chartData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con icono y título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          (secondaryColor ?? primaryColor).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositiveTrend 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                            color: isPositiveTrend ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend!,
                            style: TextStyle(
                              color: isPositiveTrend ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Valor principal
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1a202c),
                  height: 1.0,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Título y subtítulo
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4a5568),
                ),
              ),
              
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              
              // Mini gráfico si hay datos - con clipping para evitar overflow
              if (chartData != null && chartData!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRect(
                  child: SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: _buildMiniChart(),
                  ),
                ),
              ],
              
              // Porcentaje de cambio
              if (percentage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: percentage! >= 0 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${percentage! >= 0 ? '+' : ''}${percentage!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: percentage! >= 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'vs mes anterior',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox();
    
    return CustomPaint(
      painter: MiniChartPainter(
        data: chartData!,
        color: primaryColor,
      ),
      child: Container(),
    );
  }
}

class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range == 0 ? 0.5 : (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Completar el path de relleno
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Dibujar relleno
    canvas.drawPath(fillPath, fillPaint);
    
    // Dibujar línea
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget para estadísticas en grid mejorado
class StatsGrid extends StatelessWidget {
  final List<ProfessionalStatsCard> cards;
  final int? crossAxisCount;

  const StatsGrid({
    super.key,
    required this.cards,
    this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = crossAxisCount ?? _calculateColumns(constraints.maxWidth);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: _calculateAspectRatio(constraints.maxWidth, columns),
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 2;
    return 3;
  }

  double _calculateAspectRatio(double width, int columns) {
    if (width < 600) return 1.1;
    if (columns == 2) return 1.2;
    return 1.0;
  }
}