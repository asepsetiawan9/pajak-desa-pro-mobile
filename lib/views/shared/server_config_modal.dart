import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';

class ServerConfigModal extends StatefulWidget {
  const ServerConfigModal({super.key});

  @override
  State<ServerConfigModal> createState() => _ServerConfigModalState();
}

class _ServerConfigModalState extends State<ServerConfigModal> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _urlController = TextEditingController(text: authProvider.currentBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _selectPreset(String url) {
    setState(() {
      _urlController.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengaturan Host Server',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih preset atau masukkan URL API Backend lokal untuk ujicoba:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.phone_android, size: 16, color: AppColors.accent),
                label: const Text('Android Emulator (10.0.2.2)'),
                backgroundColor: AppColors.surfaceCard,
                onPressed: () => _selectPreset(ApiConstants.defaultLocalAndroidEmulator),
              ),
              ActionChip(
                avatar: const Icon(Icons.laptop, size: 16, color: AppColors.primary),
                label: const Text('Desktop/Web (127.0.0.1)'),
                backgroundColor: AppColors.surfaceCard,
                onPressed: () => _selectPreset(ApiConstants.defaultLocalDesktop),
              ),
              ActionChip(
                avatar: const Icon(Icons.cloud_done, size: 16, color: AppColors.success),
                label: const Text('Production VPS'),
                backgroundColor: AppColors.surfaceCard,
                onPressed: () => _selectPreset(ApiConstants.defaultProductionVps),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL API Backend Base Path',
              hintText: 'http://192.168.x.x:8000/api/v1',
              prefixIcon: Icon(Icons.link, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  await authProvider.setBaseUrl(url);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Host API backend diubah ke: $url'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Simpan & Hubungkan'),
            ),
          ),
        ],
      ),
    );
  }
}
