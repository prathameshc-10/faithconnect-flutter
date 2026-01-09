import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mock_data.dart';
import '../../models/user_model.dart';
import '../../providers/leaders_provider.dart';
import '../widgets/leader_card.dart';
import 'leader_profile_screen.dart';

/// Religious Leaders Screen
/// Displays a list of religious leaders with "My Leaders" and "Explore" tabs
/// Matches the reference screenshot layout
class ReligiousLeadersScreen extends StatelessWidget {
  const ReligiousLeadersScreen({super.key});

  /// Build segmented control for My Leaders/Explore tabs
  Widget _buildSegmentedControl(BuildContext context, LeadersProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // My Leaders button
          Expanded(
            child: GestureDetector(
              onTap: () => provider.selectMyLeaders(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: provider.isMyLeadersSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'My Leaders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: provider.isMyLeadersSelected ? Colors.white : Colors.grey[600],
                    fontWeight: provider.isMyLeadersSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Explore button
          Expanded(
            child: GestureDetector(
              onTap: () => provider.selectExplore(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: provider.isExploreSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Explore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: provider.isExploreSelected ? Colors.white : Colors.grey[600],
                    fontWeight: provider.isExploreSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar(BuildContext context, LeadersProvider provider, bool isExplore) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: isExplore ? 'Search Leader' : 'Search',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Build sort by dropdown (only for Explore tab)
  Widget _buildSortByDropdown(BuildContext context, LeadersProvider provider) {
    if (!provider.isExploreSelected) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: provider.selectedSortBy,
        decoration: InputDecoration(
          labelText: 'Sort By',
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        items: const [
          DropdownMenuItem(value: 'Trending', child: Text('Trending')),
          DropdownMenuItem(value: 'Near you', child: Text('Near you')),
          DropdownMenuItem(value: 'New', child: Text('New')),
        ],
        onChanged: (value) {
          if (value != null) {
            provider.setSortBy(value);
          }
        },
      ),
    );
  }

  /// Filter leaders based on search query
  List<UserModel> _filterLeaders(List<UserModel> leaders, String searchQuery) {
    if (searchQuery.isEmpty) return leaders;
    
    final query = searchQuery.toLowerCase();
    return leaders.where((leader) {
      return leader.name.toLowerCase().contains(query) ||
          leader.username.toLowerCase().contains(query) ||
          (leader.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadersProvider>(
      builder: (context, provider, child) {
        // Get appropriate list based on selected tab
        final allLeaders = provider.isMyLeadersSelected
            ? MockData.getMockMyLeaders()
            : MockData.getMockExploreLeaders();
        
        // Filter based on search query
        final filteredLeaders = _filterLeaders(allLeaders, provider.searchQuery);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: const Text(
              'Religious Leaders',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              // Profile avatar on the right
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: _buildSegmentedControl(context, provider),
            ),
          ),
          body: Column(
            children: [
              // Search bar
              _buildSearchBar(context, provider, provider.isExploreSelected),
              // Sort By dropdown (only for Explore tab)
              _buildSortByDropdown(context, provider),
              // Leaders list
              Expanded(
                child: filteredLeaders.isEmpty
                    ? Center(
                        child: Text(
                          'No leaders found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredLeaders.length,
                        itemBuilder: (context, index) {
                          final leader = filteredLeaders[index];
                          final isMyLeaders = provider.isMyLeadersSelected;
                          return LeaderCard(
                            leader: leader,
                            showMessageButton: isMyLeaders,
                            onTap: () {
                              // Navigate to leader profile screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaderProfileScreen(
                                    leader: leader,
                                  ),
                                ),
                              );
                            },
                            onAction: () {
                              // Handle action (no logic required)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMyLeaders
                                        ? 'Message ${leader.name}'
                                        : 'Follow ${leader.name}',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
