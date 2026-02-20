import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart' as health;
import '../../services/health_data_service.dart';
import '../../models/health_data.dart' as models;
import '../../widgets/loading_widgets.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> with TickerProviderStateMixin {
  final HealthDataService _healthDataService = HealthDataService();
  
  bool _isLoading = true;
  bool _hasHealthAccess = false;
  String? _error;
  
  // Data variables
  models.DailyHealthSummary? _todaysSummary;
  List<models.DailyHealthSummary> _weeklyData = [];
  List<health.HealthDataPoint> _recentHeartRate = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeHealthData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check Health Connect access
      _hasHealthAccess = await _healthDataService.isHealthDataAvailable();
      
      if (_hasHealthAccess) {
        await _loadHealthData();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize health data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHealthData() async {
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));

    try {
      // Load today's summary
      _todaysSummary = await _healthDataService.getDailyHealthSummary(today);
      
      // Load weekly data
      _weeklyData = await _healthDataService.getWeeklyHealthSummaries(weekAgo);
      
      // Load recent heart rate data
      _recentHeartRate = await _healthDataService.getHealthData(
        type: health.HealthDataType.HEART_RATE,
        startDate: today.subtract(const Duration(hours: 24)),
        endDate: today,
      );
      
      setState(() {});
    } catch (e) {
      debugPrint('Error loading health data: $e');
      setState(() {
        _error = 'Failed to load health data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.directions_run), text: 'Activity'),
            Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget(message: 'Loading health data...'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildActivityTab(),
                _buildNutritionTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (!_hasHealthAccess) {
      return _buildConnectionPrompt();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary Card
          _buildTodaySummaryCard(),
          const SizedBox(height: 24),
          
          // Quick Stats Grid
          _buildQuickStatsGrid(),
          const SizedBox(height: 24),
          
          // Weekly Trends
          if (_weeklyData.isNotEmpty) ...[
            _buildWeeklyTrendsCard(),
            const SizedBox(height: 24),
          ],
          
          // Health Insights
          _buildHealthInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Summary
          _buildActivitySummaryCard(),
          const SizedBox(height: 24),
          
          // Activity Chart
          if (_recentHeartRate.isNotEmpty) _buildActivityChart(),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition Summary
          _buildNutritionSummaryCard(),
          const SizedBox(height: 24),
          
          // Weekly Nutrition Trends
          if (_weeklyData.isNotEmpty) _buildNutritionChart(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status
          _buildConnectionStatusCard(),
          const SizedBox(height: 24),
          
          // Data Sources
          _buildDataSourcesCard(),
          const SizedBox(height: 24),
          
          // Sync Options
          _buildSyncOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildConnectionPrompt() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 80,
              color: colorScheme.primary,
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: 24),
            Text(
              'Connect Your Health Data',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to Health Connect to access comprehensive health and fitness data including steps, heart rate, nutrition, and more.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Health Connect Button (Primary recommendation)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _connectHealthConnect,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Connect Health Connect'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Combine data from both sources
    final steps = _todaysSummary?.steps ?? 0;
    final calories = _todaysSummary?.caloriesBurned ?? 0.0;
    final distance = _todaysSummary?.distance ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Summary',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.directions_walk,
                    value: NumberFormat('#,###').format(steps),
                    label: 'Steps',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.local_fire_department,
                    value: calories.toStringAsFixed(0),
                    label: 'Calories',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.straighten,
                    value: '${distance.toStringAsFixed(1)} km',
                    label: 'Distance',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_todaysSummary == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Connect Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.timer,
              title: 'Move Minutes',
              value: '${_todaysSummary!.moveMinutes}',
              subtitle: 'min active',
              color: Colors.purple,
            ),
            _buildStatCard(
              icon: Icons.favorite,
              title: 'Heart Points',
              value: '${_todaysSummary!.heartPoints}',
              subtitle: 'intensity points',
              color: Colors.red,
            ),
            _buildStatCard(
              icon: Icons.bedtime,
              title: 'Sleep',
              value: '${(_todaysSummary!.sleepHours ?? 0.0).toStringAsFixed(1)}h',
              subtitle: 'last night',
              color: Colors.indigo,
            ),
            _buildStatCard(
              icon: Icons.water_drop,
              title: 'Hydration',
              value: '${_todaysSummary!.hydration.toStringAsFixed(0)}ml',
              subtitle: 'water intake',
              color: Colors.cyan,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Steps Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weeklyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.steps.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInsightsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Health Insights',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              icon: Icons.trending_up,
              title: 'Activity Level',
              description: _getActivityInsight(),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.schedule,
              title: 'Sleep Quality',
              description: _getSleepInsight(),
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.restaurant,
              title: 'Nutrition',
              description: _getNutritionInsight(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getActivityInsight() {
    final steps = _todaysSummary?.steps ?? 0;
    if (steps >= 10000) {
      return 'Great job! You\'ve reached your daily step goal.';
    } else if (steps >= 7500) {
      return 'You\'re doing well! Just a bit more to reach 10,000 steps.';
    } else {
      return 'Try to be more active today. Every step counts!';
    }
  }

  String _getSleepInsight() {
    final sleepHours = _todaysSummary?.sleepHours ?? 0;
    if (sleepHours >= 7 && sleepHours <= 9) {
      return 'Perfect! You\'re getting optimal sleep duration.';
    } else if (sleepHours < 7) {
      return 'Try to get more sleep. Aim for 7-9 hours per night.';
    } else {
      return 'You might be sleeping too much. 7-9 hours is ideal.';
    }
  }

  String _getNutritionInsight() {
    if (_weeklyData.isNotEmpty) {
      return 'Keep tracking your nutrition for better health insights.';
    } else {
      return 'Start logging your meals in Health Connect for nutrition insights.';
    }
  }

  Widget _buildActivitySummaryCard() {
    // Implementation for activity summary
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Detailed activity metrics will be displayed here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    // Implementation for activity chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heart Rate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _recentHeartRate.asMap().entries.map((entry) {
                        final dataPoint = entry.value;
                        double heartRateValue = 0.0;
                        if (dataPoint.value is health.NumericHealthValue) {
                          heartRateValue = (dataPoint.value as health.NumericHealthValue).numericValue.toDouble();
                        }
                        return FlSpot(entry.key.toDouble(), heartRateValue);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard() {
    // Implementation for nutrition summary
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Nutrition data will be displayed here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChart() {
    // Implementation for nutrition chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Nutrition Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weeklyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.caloriesBurned);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildConnectionStatusItem(
              'Health Connect',
              _hasHealthAccess,
              Icons.health_and_safety,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusItem(String name, bool isConnected, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isConnected ? 'Connected' : 'Not Connected',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSourcesCard() {
    // Implementation for data sources
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Configure your data sources and permissions here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOptionsCard() {
    // Implementation for sync options
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await _loadHealthData();
                  setState(() => _isLoading = false);
                  _showSuccessSnackBar('Health data synced successfully!');
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _connectHealthConnect() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _healthDataService.initializeHealthData();
      if (success) {
        setState(() {
          _hasHealthAccess = true;
        });
        await _loadHealthData();
        _showSuccessSnackBar('Health Connect connected successfully!');
      } else {
        _showErrorSnackBar('Failed to connect to Health Connect');
      }
    } catch (e) {
      _showErrorSnackBar('Error connecting to Health Connect: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 