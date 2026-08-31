import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeHeroGraphic extends StatelessWidget {
  const HomeHeroGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Three playing cards with the three of spades in front',
      image: true,
      child: SizedBox(
        key: const ValueKey('home-hero-graphic'),
        width: 260,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 228,
              height: 128,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(64),
              ),
            ),
            Positioned(
              left: 40,
              top: 31,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: const _HeroCard(
                  rank: '7',
                  suit: '♣',
                  color: Color(0xFF31584E),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 31,
              child: Transform.rotate(
                angle: math.pi / 12,
                child: const _HeroCard(
                  rank: '9',
                  suit: '♥',
                  color: Color(0xFFA34B4B),
                ),
              ),
            ),
            const Positioned(
              top: 19,
              child: _HeroCard(
                rank: '3',
                suit: '♠',
                color: Color(0xFF173E34),
                emphasized: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.rank,
    required this.suit,
    required this.color,
    this.emphasized = false,
  });

  final String rank;
  final String suit;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: emphasized ? 86 : 78,
      height: emphasized ? 122 : 111,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6DDD8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: emphasized ? .18 : .11),
            blurRadius: emphasized ? 13 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '$rank$suit',
              style: TextStyle(
                height: 1,
                color: color,
                fontSize: emphasized ? 19 : 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
              ),
            ),
          ),
          Center(
            child: Text(
              suit,
              style: TextStyle(
                height: 1,
                color: color,
                fontSize: emphasized ? 43 : 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
