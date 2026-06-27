import 'package:flutter/material.dart';
import '../appointment_provider.dart';
import '../utils/helpers.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatefulWidget {
  final AppointmentProvider provider;

  const ClientsScreen({super.key, required this.provider});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profiles = widget.provider.clientProfiles;
    
    // Filter profiles based on query
    final filtered = profiles.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_query.toLowerCase());
      final phoneMatches = p.phoneNumber.replaceAll(RegExp(r'\D'), '').contains(_query);
      return nameMatches || phoneMatches;
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.provider.translate('searchClients'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _query = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _query = val;
              });
            },
          ),
        ),

        // List View
        Expanded(
          child: profiles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      widget.provider.translate('noClientsAdded'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.provider.translate('noClientsFound'),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final client = filtered[index];
                        final initials = client.name.trim().isNotEmpty
                            ? client.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : '?';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            client.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(formatPhoneNumber(client.phoneNumber)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${client.appointments.length} ${widget.provider.translate('calendarTab').toLowerCase()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientDetailsScreen(profile: client),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
