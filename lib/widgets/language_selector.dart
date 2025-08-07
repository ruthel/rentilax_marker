import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Langue / Language',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...languageService.supportedLanguages.map((language) {
                  final isSelected =
                      languageService.currentLocale.languageCode ==
                          language['code'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: ListTile(
                      leading: Text(
                        language['flag'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        language['name'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () async {
                        await languageService
                            .changeLanguage(language['locale']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Langue changée vers ${language['name']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
