import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_tip.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/add_food_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/weight_screen.dart';
import '../screens/weight_insights_screen.dart';
import 'common.dart';

void openTipDestination(BuildContext context, TipDestination destination) {
  if (destination == TipDestination.none) return;
  final ru = context.read<SettingsProvider>().lang == AppLang.ru;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (pageContext) {
        if (destination == TipDestination.insights) {
          return const WeightInsightsScreen();
        }
        if (destination == TipDestination.weight) {
          return Scaffold(
            backgroundColor: pageContext.colors.page,
            body: WeightScreen(onBack: () => Navigator.pop(pageContext)),
          );
        }
        return Scaffold(
          backgroundColor: pageContext.colors.page,
          appBar: AppBar(title: Text(ru ? 'Дневник питания' : 'Food diary')),
          body: DiaryScreen(
            onSearch: (meal) {
              final date = pageContext.read<AppDataProvider>().selectedDate;
              Navigator.push(
                pageContext,
                MaterialPageRoute<void>(
                  builder: (searchContext) => Scaffold(
                    backgroundColor: searchContext.colors.page,
                    body: AddFoodScreen(
                      onBack: () => Navigator.pop(searchContext),
                      initialMeal: meal,
                      selectedDate: date,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
