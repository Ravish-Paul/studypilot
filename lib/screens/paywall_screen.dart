import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../controllers/paywall_controller.dart';
import '../providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  Widget build(BuildContext context) {
    final paywall = ref.watch(paywallControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyPilot Pro'),
        actions: [
          TextButton(
            onPressed: paywall.restoring ? null : () => _restore(paywall),
            child: Text(
              paywall.restoring ? 'Restoring...' : 'Restore',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.workspace_premium,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock unlimited AI planning',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plan stays alive — adapt, reschedule and never fall behind.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _Benefit(
            icon: Icons.all_inclusive,
            title: 'Unlimited subjects',
            subtitle: 'Plan your entire semester, not just one subject',
          ),
          const _Benefit(
            icon: Icons.auto_awesome,
            title: 'Unlimited AI replans',
            subtitle: 'Every skipped day gets rebuilt smartly',
          ),
          const _Benefit(
            icon: Icons.insights,
            title: 'Weekly insights',
            subtitle: 'See where your focus actually goes',
          ),
          const _Benefit(
            icon: Icons.palette,
            title: 'Premium themes',
            subtitle: 'Make StudyPilot yours',
          ),
          const SizedBox(height: 24),
          if (paywall.loadingPackages)
            const Center(child: CircularProgressIndicator())
          else if (paywall.demoMode) ...[
            _PackageCard(
              title: 'Pro Monthly',
              price: '\$3.99 / month',
              highlighted: false,
              onTap: () => _demoUnlock(paywall),
            ),
            const SizedBox(height: 12),
            _PackageCard(
              title: 'Pro Lifetime',
              price: '\$24.99 once',
              highlighted: true,
              onTap: () => _demoUnlock(paywall),
            ),
            const SizedBox(height: 16),
            Text(
              'RevenueCat SDK is fully integrated. No store products are '
              'configured in this build, so purchases run in test mode — '
              'unlocks Pro locally for evaluation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            if (paywall.monthlyPackage != null)
              _PackageCard(
                title: 'Pro Monthly',
                price: paywall.monthlyPackage!.storeProduct.priceString,
                highlighted: false,
                onTap: () => _purchase(paywall, paywall.monthlyPackage!),
              ),
            if (paywall.lifetimePackage != null) ...[
              const SizedBox(height: 12),
              _PackageCard(
                title: 'Pro Lifetime',
                price: paywall.lifetimePackage!.storeProduct.priceString,
                highlighted: true,
                onTap: () => _purchase(paywall, paywall.lifetimePackage!),
              ),
            ],
            if (paywall.monthlyPackage == null &&
                paywall.lifetimePackage == null)
              const Center(child: Text('No packages available right now')),
          ],
          if (paywall.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                paywall.message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (paywall.isPro)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    const Text('Pro is active'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          Text(
            'Payments are processed by the app store via RevenueCat. '
            'Subscriptions renew automatically until cancelled.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(
    PaywallController paywall,
    Package package,
  ) async {
    final success = await paywall.purchase(package);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro unlocked. Thank you!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _demoUnlock(PaywallController paywall) async {
    await paywall.demoUnlock();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pro unlocked (test mode)')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _restore(PaywallController paywall) async {
    final restored = await paywall.restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? 'Purchases restored' : (paywall.message ?? 'Nothing to restore'),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final bool highlighted;
  final VoidCallback onTap;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.15)
          : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: highlighted ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (highlighted)
                      Text(
                        'Best value',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
