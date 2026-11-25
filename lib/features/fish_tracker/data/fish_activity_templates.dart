import 'package:uuid/uuid.dart';
import '../../../data/models/bd_fishes_catalog.dart';
import '../../../data/models/fish_activity.dart';

class FishActivityTemplates {
  FishActivityTemplates._();

  static const _uuid = Uuid();

  /// Generates full lifecycle & daily schedule activities for a fish pond.
  static List<FishActivity> generateForPond({
    required String fishPondId,
    required String speciesId,
    required DateTime stockingDate,
    required int targetHarvestDays,
  }) {
    final species = BdFishesCatalog.findById(speciesId);
    final activities = <FishActivity>[];

    // Day 0: Fingerling Acclimatization & Stocking
    activities.add(
      FishActivity(
        id: _uuid.v4(),
        fishPondId: fishPondId,
        title: 'Fingerling Acclimatization & Stocking',
        titleBn: 'পোনা অবমুক্তকরণ ও পানির তাপমাত্রা সমতাকরণ',
        description:
            'Float fingerling bags in pond water for 25-30 minutes to match temperature before releasing.',
        descriptionBn:
            'পুকুরের পানিতে পোনার পাত্র/ব্যাগ ২৫-৩০ মিনিট ভাসিয়ে রেখে তাপমাত্রা সমতা করে আস্তে আস্তে পোনা অবমুক্ত করুন।',
        dayFromStocking: 0,
        scheduledDate: stockingDate,
        category: 'treatment',
        suggestedTime: '09:00 AM',
      ),
    );

    // Generate recurring activities across the culture period
    final daysToGenerate = targetHarvestDays.clamp(30, 365);

    for (var day = 1; day <= daysToGenerate; day++) {
      final date = stockingDate.add(Duration(days: day));

      // 1. Morning Feeding (08:00 AM BST)
      activities.add(
        FishActivity(
          id: _uuid.v4(),
          fishPondId: fishPondId,
          title: 'Morning Feed (${species.optimalFeedingTimes.first})',
          titleBn: 'সকালের খাবার প্রদান (${species.optimalFeedingTimes.first})',
          description:
              'Provide morning floating/sinking feed (${species.nameEn}). Check feeding response after 20 minutes.',
          descriptionBn:
              'নির্ধারিত মাত্রায় প্রোটিনযুক্ত খাবার দিন। ২০ মিনিট পর পর্যবেক্ষণ করুন মাছ খাবার পুরোপুরি গ্রহণ করেছে কিনা।',
          dayFromStocking: day,
          scheduledDate: date,
          category: 'feeding',
          suggestedTime: species.optimalFeedingTimes.first,
        ),
      );

      // 2. Pond Oxygen Generation & Swimming / Water Agitation (11:30 AM BST)
      // High importance daily task as requested by user
      activities.add(
        FishActivity(
          id: _uuid.v4(),
          fishPondId: fishPondId,
          title: 'Oxygen Aeration & Swimming Agitation',
          titleBn: 'পুকুরে সাঁতার কেটে বা বাঁশ পিটিয়ে অক্সিজেন সঞ্চালন',
          description:
              'Agitate water by swimming or beating water with bamboo poles to increase dissolved oxygen (DO > ${species.minOxygenPpm} ppm).',
          descriptionBn:
              'পুকুরে সাঁতার কেটে, বাঁশ দিয়ে পানি পিটিয়ে বা পাম্পের ঝর্ণা চালিয়ে পানিতে দ্রবীভূত অক্সিজেন সঞ্চালন নিশ্চিত করুন।',
          dayFromStocking: day,
          scheduledDate: date,
          category: 'oxygen_aeration',
          suggestedTime: '11:30 AM',
        ),
      );

      // 3. Afternoon Feeding (04:30 PM BST)
      final afternoonTime = species.optimalFeedingTimes.length > 1
          ? species.optimalFeedingTimes[1]
          : '04:30 PM';
      activities.add(
        FishActivity(
          id: _uuid.v4(),
          fishPondId: fishPondId,
          title: 'Afternoon Feed ($afternoonTime)',
          titleBn: 'বিকালের খাবার প্রদান ($afternoonTime)',
          description:
              'Provide second meal ration of the day. Avoid overfeeding before dusk.',
          descriptionBn:
              'দিনের দ্বিতীয় ধাপের পুষ্টিকর ফিড নির্দিষ্ট ট্রে বা পুকুরের নির্দিষ্ট স্থানে সমানভাবে ছড়িয়ে দিন।',
          dayFromStocking: day,
          scheduledDate: date,
          category: 'feeding',
          suggestedTime: afternoonTime,
        ),
      );

      // 4. Weekly Water Quality & Transparency Test (Every 7 days)
      if (day % 7 == 0) {
        activities.add(
          FishActivity(
            id: _uuid.v4(),
            fishPondId: fishPondId,
            title: 'Water Quality & pH / Secchi Disc Test',
            titleBn: 'পানির গুণমান, পিএইচ ও স্বচ্ছতা পরীক্ষা',
            description:
                'Check water color, Secchi disc transparency (25-35 cm ideal) and pH (7.5-8.5 ideal).',
            descriptionBn:
                'পানির রং ও শেওলার ঘনত্ব দেখুন। সেকি ডিস্ক দিয়ে স্বচ্ছতা (২৫-৩৫ সেমি) এবং পিএইচ মিটার/লিটমাস দিয়ে পিএইচ পরীক্ষা করুন।',
            dayFromStocking: day,
            scheduledDate: date,
            category: 'water_quality',
            suggestedTime: '10:00 AM',
          ),
        );
      }

      // 5. Netting Sampling & Weight Growth Check (Every 20 days)
      if (day % 20 == 0 && day < targetHarvestDays - 5) {
        activities.add(
          FishActivity(
            id: _uuid.v4(),
            fishPondId: fishPondId,
            title: 'Netting Sample & Growth Measurement',
            titleBn: 'জাল টেনে নমুনা সংগ্রহ ও ওজন পর্যবেক্ষণ',
            description:
                'Cast net to sample 15-20 fish, measure average weight gain, inspect body for parasites, and adjust daily feed quantity.',
            descriptionBn:
                'পুকুরে জাল টেনে ১৫-২০টি মাছ তুলে ওজন মাপুন, মাছের শরীরে কোনো পরজীবী বা ঘা আছে কিনা দেখুন এবং নতুন ওজনের ভিত্তিতে খাবারের পরিমাণ সমন্বয় করুন।',
            dayFromStocking: day,
            scheduledDate: date,
            category: 'sampling',
            suggestedTime: '09:30 AM',
          ),
        );
      }

      // 6. Monthly Liming & Salt Application (Every 30 days)
      if (day % 30 == 0 && day < targetHarvestDays - 10) {
        activities.add(
          FishActivity(
            id: _uuid.v4(),
            fishPondId: fishPondId,
            title: 'Preventive Liming & Salt Treatment',
            titleBn: 'রোগ প্রতিরোধে প্রতি শতকে চুন ও লবণ প্রয়োগ',
            description:
                'Apply agricultural lime (100-200g/decimal) dissolved in water to stabilize alkalinity and prevent fungal diseases.',
            descriptionBn:
                'প্রতি শতকে ১০০-২০০ গ্রাম চুন রাতে ভিজিয়ে রেখে সকালে গুলে পুকুরে সমানভাবে ছিটিয়ে দিন। প্রয়োজনে সামান্য লবণ ব্যবহার করুন।',
            dayFromStocking: day,
            scheduledDate: date,
            category: 'treatment',
            suggestedTime: '10:30 AM',
          ),
        );
      }
    }

    // Final Harvest Preparation
    activities.add(
      FishActivity(
        id: _uuid.v4(),
        fishPondId: fishPondId,
        title: 'Market Harvest & Pond Drainage',
        titleBn: 'মাছ আহরণ ও বাজারজাতকরণ',
        description:
            'Stop feeding 24 hours prior to harvesting for clean gut. Cast drag net and harvest market-size fish.',
        descriptionBn:
            'আহরণের ২৪ ঘণ্টা আগে খাবার বন্ধ রাখুন যাতে পেট পরিষ্কার থাকে। বড় বেড় জাল টেনে অথবা পানি কমিয়ে পূর্ণাঙ্গ মাছ বাজারজাত করুন।',
        dayFromStocking: targetHarvestDays,
        scheduledDate: stockingDate.add(Duration(days: targetHarvestDays)),
        category: 'sampling',
        suggestedTime: '06:00 AM',
      ),
    );

    return activities;
  }
}
