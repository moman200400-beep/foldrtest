import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';

class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Header Skeleton
          SliverAppBar(
            expandedHeight: 180,
            backgroundColor: Colors.transparent,
            flexibleSpace: GlassContainer(
              borderRadius: 35,
              backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              child: const SizedBox.expand(),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 2000.ms,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
          ),
          
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              
              // Banners Skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  height: 140,
                  borderRadius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  child: const SizedBox.expand(),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
              ),
              const SizedBox(height: 30),

              // Categories Skeleton
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (_, i) => Container(
                    width: 80,
                    margin: const EdgeInsets.only(left: 10),
                    child: GlassContainer(
                      borderRadius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      child: const SizedBox.expand(),
                    ),
                  ).animate(delay: (i * 100).ms, onPlay: (c) => c.repeat()).shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                ),
              ),
              const SizedBox(height: 30),

              // Products Grid Skeleton
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 4,
                itemBuilder: (_, i) => GlassContainer(
                  borderRadius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  child: const SizedBox.expand(),
                ).animate(delay: (i * 150).ms, onPlay: (c) => c.repeat()).shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }
}
