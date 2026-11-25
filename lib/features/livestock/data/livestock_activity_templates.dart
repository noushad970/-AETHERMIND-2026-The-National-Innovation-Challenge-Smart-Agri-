import '../../../core/constants/app_constants.dart';
import '../../../data/models/animal.dart';

/// Defines the default activity timeline for an [Animal].
/// Each entry is a single scheduled task on a specific milestone day.
class LivestockActivityTemplate {
  const LivestockActivityTemplate({
    required this.dayFromStart,
    required this.category,
    required this.titleEn,
    required this.titleBn,
    this.descriptionEn = '',
    this.descriptionBn = '',
    this.repeatIntervalDays = 0,
  });

  final int dayFromStart;
  final String category;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final int repeatIntervalDays;
}

class LivestockActivityTemplates {
  LivestockActivityTemplates._();

  static List<LivestockActivity> build({
    required String animalId,
    required String species,
    required String purpose,
    required DateTime startDate,
  }) {
    final tpl = _templatesFor(species, purpose);
    final activities = <LivestockActivity>[];
    final seen = <String>{};

    for (final t in tpl) {
      final key = '${t.dayFromStart}_${t.category}_${t.titleEn}';
      if (!seen.add(key)) continue;

      final scheduledDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: t.dayFromStart));

      final idSuffix = t.repeatIntervalDays > 0
          ? '${t.dayFromStart}_${t.category}_r${t.repeatIntervalDays}_${activities.length}'
          : '${t.dayFromStart}_${t.category}_${activities.length}';

      activities.add(
        LivestockActivity(
          id: '${animalId}_d$idSuffix',
          animalId: animalId,
          title: t.titleEn,
          titleBn: t.titleBn,
          description: t.descriptionEn,
          descriptionBn: t.descriptionBn,
          category: t.category,
          dayFromStart: t.dayFromStart,
          scheduledDate: scheduledDay,
          repeatIntervalDays: t.repeatIntervalDays,
        ),
      );
    }
    return activities;
  }

  static List<LivestockActivityTemplate> _templatesFor(
    String species,
    String purpose,
  ) {
    final base = _baseCare();
    final specific = _speciesSpecific(species, purpose);
    return [...base, ...specific];
  }

  static List<LivestockActivityTemplate> _baseCare() {
    return [
      const LivestockActivityTemplate(
        dayFromStart: 0,
        category: AppConstants.lcatFeeding,
        titleEn: 'Daily feed & nutrient ration',
        titleBn: 'দৈনিক সুষম খাদ্য ও পুষ্টি সরবরাহ',
        descriptionEn: 'Provide balanced morning and evening feed rations.',
        descriptionBn: 'সকাল ও সন্ধ্যায় নির্ধারিত মাত্রায় পুষ্টিকর দানাদার ও সুষম খাবার দিন।',
        repeatIntervalDays: 1,
      ),
      const LivestockActivityTemplate(
        dayFromStart: 0,
        category: AppConstants.lcatWater,
        titleEn: 'Clean drinking water check',
        titleBn: 'বিশুদ্ধ খাবার পানির সরবরাহ ও পাত্র পরিষ্কার',
        descriptionEn: 'Refill clean drinking water and clean water troughs.',
        descriptionBn: 'সার্বক্ষণিক পরিষ্কার খাবার পানি নিশ্চিত করুন এবং পানির পাত্র ধুয়ে পরিষ্কার রাখুন।',
        repeatIntervalDays: 1,
      ),
      const LivestockActivityTemplate(
        dayFromStart: 0,
        category: AppConstants.lcatHealth,
        titleEn: 'Daily physical health inspection',
        titleBn: 'দৈনিক শারীরিক স্বাস্থ্য ও লক্ষণ পর্যবেক্ষণ',
        descriptionEn: 'Observe gait, eyes, droppings, and body condition.',
        descriptionBn: 'প্রাণীর হাঁটাচলা, চোখ, মল ও শারীরিক সক্রিয়তা নিবিড়ভাবে লক্ষ্য করুন।',
        repeatIntervalDays: 1,
      ),
      const LivestockActivityTemplate(
        dayFromStart: 7,
        category: AppConstants.lcatCleaning,
        titleEn: 'Weekly housing cleaning & disinfection',
        titleBn: 'সাপ্তাহিক খামার ও বাসস্থান জীবাণুমুক্তকরণ',
        descriptionEn: 'Remove droppings, change bedding, and spray disinfectant.',
        descriptionBn: 'বিষ্ঠা পরিষ্কার করুন, নতুন লিটার বা বিছানা দিন এবং জীবাণুনাশক স্প্রে করুন।',
        repeatIntervalDays: 7,
      ),
    ];
  }

  static List<LivestockActivityTemplate> _speciesSpecific(
    String species,
    String purpose,
  ) {
    final lower = species.toLowerCase();
    final wantsMilk =
        purpose == AppConstants.purposeDairy ||
        purpose == AppConstants.purposeMixed ||
        lower.contains('cow') ||
        lower.contains('dairy');

    final raw = <LivestockActivityTemplate>[];

    if (lower.contains('poultry') || lower.contains('chicken') || lower.contains('broiler') || lower.contains('layer')) {
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 1,
          category: AppConstants.lcatHealth,
          titleEn: 'Brooder temperature & glucose water',
          titleBn: 'ব্রুডার তাপমাত্রা ও গ্লুকোজ-স্যালাইন পানি',
          descriptionEn: 'Maintain 95°F brooder warmth; supply electrolyte water.',
          descriptionBn: 'ব্রুডারে ৯৫°ফা. তাপমাত্রা বজায় রাখুন এবং প্রাথমিক স্যালাইন পানি খেতে দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 3,
          category: AppConstants.lcatVaccination,
          titleEn: 'Marek\'s / Ranikhet (ND) eye drops',
          titleBn: 'মেরেক্স বা রাণীক্ষেত (বি১) চোখের ড্রপ',
          descriptionEn: 'Apply Ranikhet B1 / Marek\'s vaccine via eye drop.',
          descriptionBn: '১ম ডোজ রাণীক্ষেত বি১ ভ্যাকসিন এক ফোঁটা চোখে দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 7,
          category: AppConstants.lcatVaccination,
          titleEn: 'Gumboro (IBD) 1st dose vaccine',
          titleBn: 'গামবোরো (আইবিডি) ১ম ডোজ টিকা',
          descriptionEn: 'Administer IBD vaccine in morning drinking water.',
          descriptionBn: 'সকালের স্বাভাবিক তাপমাত্রার খাবার পানিতে গামবোরো ১ম ডোজ দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 14,
          category: AppConstants.lcatVaccination,
          titleEn: 'Gumboro (IBD) booster dose',
          titleBn: 'গামবোরো (আইবিডি) বুস্টার ডোজ টিকা',
          descriptionEn: 'Give booster dose to ensure full antibody protection.',
          descriptionBn: 'সম্পূর্ণ রোগ প্রতিরোধ নিশ্চিত করতে গামবোরো বুস্টার ডোজ প্রদান করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 21,
          category: AppConstants.lcatVaccination,
          titleEn: 'Ranikhet (ND Lasota) booster',
          titleBn: 'রাণীক্ষেত (লাসোটা) বুস্টার ও খাবার পরিবর্তন',
          descriptionEn: 'Administer ND Lasota vaccine and transition to grower feed.',
          descriptionBn: 'রাণীক্ষেত লাসোটা ভ্যাকসিন দিন এবং গ্রোয়ার খাবারে রূপান্তর শুরু করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 28,
          category: AppConstants.lcatVaccination,
          titleEn: 'Fowl Pox wing-web vaccination',
          titleBn: 'ফাউল পক্স (বসন্ত) ডানার চামড়ায় টিকা',
          descriptionEn: 'Vaccinate in the wing web to prevent pox infection.',
          descriptionBn: 'বসন্ত রোগ প্রতিরোধে ডানার চামড়ায় ফাউল পক্স টিকা প্রয়োগ করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 35,
          category: AppConstants.lcatHealth,
          titleEn: 'Deworming & multivitamin course',
          titleBn: 'কৃমিনাশক ও মাল্টিভিটামিন কোর্স',
          descriptionEn: 'Give dewormer followed by 3 days of Vitamin AD3E.',
          descriptionBn: 'কৃমিনাশক ওষুধ খাওয়ান এবং পরবর্তী ৩ দিন ভিটামিন এডি৩ই দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 42,
          category: AppConstants.lcatWeighing,
          titleEn: 'Broiler market weight evaluation',
          titleBn: 'ব্রয়লার বাজারজাত ওজন পরীক্ষা',
          descriptionEn: 'Sample-weigh 10 birds to verify target weight (>1.8kg).',
          descriptionBn: '১০টি ব্রয়লারের ওজন মেপে বিক্রির উপযোগী গড় ওজন (>১.৮ কেজি) যাচাই করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 60,
          category: AppConstants.lcatFeeding,
          titleEn: 'Feed calcium & protein booster',
          titleBn: 'ক্যালসিয়াম ও প্রোটিন পরিপূরক খাদ্য',
          descriptionEn: 'Supplement crushed oyster shells for bone and shell strength.',
          descriptionBn: 'হাড় ও ডিমের খোসা মজবুত করতে ঝিনুক চূর্ণ ও অতিরিক্ত ক্যালসিয়াম দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 112,
          category: AppConstants.lcatEggCollect,
          titleEn: 'Layer egg production onset',
          titleBn: 'লেয়ার ডিম পাড়ার শুরু ও খাঁচা ব্যবস্থাপনা',
          descriptionEn: 'Switch to 100% layer mash feed and open nest boxes.',
          descriptionBn: 'শতভাগ লেয়ার ম্যাশ খাবারে যান এবং ডিম পাড়ার নেস্ট বক্স উন্মুক্ত করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 140,
          category: AppConstants.lcatHealth,
          titleEn: 'Peak lay percentage audit (>85%)',
          titleBn: 'সর্বোচ্চ ডিম উৎপাদন পর্যবেক্ষণ (>৮৫%)',
          descriptionEn: 'Count daily eggs and verify shell thickness and yolk color.',
          descriptionBn: 'দৈনিক ডিমের শতকরা হার গণনা করুন এবং খোসার দৃঢ়তা ও কুসুমের রঙ পরীক্ষা করুন।',
        ),
      ]);
    } else if (lower.contains('duck')) {
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 3,
          category: AppConstants.lcatHealth,
          titleEn: 'Duckling warmth & starter feeding',
          titleBn: 'হাঁসের বাচ্চার উষ্ণতা ও স্টার্টার খাদ্য',
          descriptionEn: 'Feed moist starter crumble; maintain dry bedding.',
          descriptionBn: 'হালকা ভেজা স্টার্টার খাদ্য দিন এবং ব্রুডারের মেঝে শুকনো রাখুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 14,
          category: AppConstants.lcatVaccination,
          titleEn: 'Duck Plague / Enteritis vaccine',
          titleBn: 'ডাক প্লেগ (প্লেগ রোগ) প্রতিরোধক টিকা',
          descriptionEn: 'Inject duck plague vaccine subcutaneously.',
          descriptionBn: 'ঘাড়ের চামড়ার নিচে ১ সিসি ডাক প্লেগ টিকা ইনজেকশন দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 28,
          category: AppConstants.lcatVaccination,
          titleEn: 'Duck Cholera vaccination',
          titleBn: 'ডাক কলেরা প্রতিষেধক টিকা',
          descriptionEn: 'Administer cholera vaccine to prevent pasteurellosis.',
          descriptionBn: 'কলেরা রোগ প্রতিরোধে চামড়ার নিচে কলেরা টিকা প্রয়োগ করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 45,
          category: AppConstants.lcatWater,
          titleEn: 'Controlled pond swimming access',
          titleBn: 'নিয়ন্ত্রিত পুকুরে সাঁতার কাটানো',
          descriptionEn: 'Allow 1-2 hours swimming access in clean pond.',
          descriptionBn: 'রোদে পরিষ্কার পুকুরে দিনে ১-২ ঘণ্টা সাঁতার কাটতে দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 90,
          category: AppConstants.lcatHealth,
          titleEn: 'Deworming & liver tonic',
          titleBn: 'কৃমিনাশক ও লিভার টনিক কোর্স',
          descriptionEn: 'Administer broad-spectrum anthelmintic.',
          descriptionBn: 'কৃমিনাশক খাওয়ান এবং সুস্থতার জন্য লিভার টনিক দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 120,
          category: AppConstants.lcatEggCollect,
          titleEn: 'Duck egg collection start',
          titleBn: 'হাঁসের ডিম সংগ্রহ ও পরিচর্যা',
          descriptionEn: 'Collect fresh eggs twice daily (early morning & afternoon).',
          descriptionBn: 'ভোরবেলা ও বিকালে প্রতিদিন দুইবার সতেজ ডিম সংগ্রহ করুন।',
        ),
      ]);
    } else if (lower.contains('cow') || lower.contains('cattle') || lower.contains('beef') || lower.contains('buffalo')) {
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 1,
          category: AppConstants.lcatHealth,
          titleEn: 'Deworming & body condition score',
          titleBn: 'কৃমিনাশক প্রয়োগ ও শারীরিক স্বাস্থ্য পরীক্ষা',
          descriptionEn: 'Administer oral anthelmintic (e.g. Albendazole).',
          descriptionBn: 'মুখে আলবেনডাজল বা অনুমোদিত কৃমিনাশক ট্যাবলেট খাওয়ান।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 7,
          category: AppConstants.lcatVaccination,
          titleEn: 'FMD (Foot-and-Mouth Disease) vaccine',
          titleBn: 'ক্ষুরারোগ (FMD) প্রতিরোধক টিকা',
          descriptionEn: 'Inject FMD trivalent vaccine (repeat every 6 months).',
          descriptionBn: 'গবাদিপশুকে ক্ষুরারোগের ট্রাইভ্যালেন্ট টিকা ইনজেকশন দিন (প্রতি ৬ মাসে পুনরাবৃত্তি)।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 14,
          category: AppConstants.lcatFeeding,
          titleEn: 'Mineral mixture & urea molasses straw',
          titleBn: 'খনিজ মিশ্রণ ও ইউএমএস (UMS) খাদ্য',
          descriptionEn: 'Add 50g mineral mix and salt lick block to daily feed.',
          descriptionBn: 'দৈনিক খাবারের সাথে ৫০ গ্রাম মিনারেল মিক্স ও ইউরিয়া মোলাসেস খড় দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 30,
          category: AppConstants.lcatVaccination,
          titleEn: 'Anthrax & Black Quarter (BQ) vaccine',
          titleBn: 'তড়কা ও বাদলা রোগের টিকা',
          descriptionEn: 'Administer Anthrax / BQ vaccine subcutaneously.',
          descriptionBn: 'তড়কা ও বাদলা রোগের প্রতিষেধক টিকা চামড়ার নিচে দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 60,
          category: AppConstants.lcatHealth,
          titleEn: 'Hoof trimming & skin parasite spray',
          titleBn: 'ক্ষুর ছাঁটাই ও বহিঃপরজীবী দমন',
          descriptionEn: 'Inspect hooves and spray against ticks/lice.',
          descriptionBn: 'বড় হওয়া ক্ষুর কেটে দিন এবং মাছি, উকুন ও আটালি দমনে স্প্রে করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 90,
          category: AppConstants.lcatHealth,
          titleEn: 'Estrus / heat cycle & breeding check',
          titleBn: 'গরম হওয়া (ডাক আসা) ও কৃত্রিম প্রজনন',
          descriptionEn: 'Check for standing heat or artificial insemination readiness.',
          descriptionBn: 'গাভী ডাক আসার সঠিক সময় পর্যবেক্ষণ করে কৃত্রিম প্রজননের ব্যবস্থা নিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 120,
          category: AppConstants.lcatHealth,
          titleEn: 'Secondary deworming & liver booster',
          titleBn: '২য় দফায় কৃমিনাশক ও লিভার টনিক',
          descriptionEn: 'Rotate dewormer active ingredient (e.g. Levamisole).',
          descriptionBn: 'গ্রুপ পরিবর্তন করে লিভামিসোল জাতীয় কৃমিনাশক ও লিভার টনিক দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 180,
          category: AppConstants.lcatVaccination,
          titleEn: 'FMD 6-month booster vaccination',
          titleBn: 'ক্ষুরারোগের ৬ মাসের বুস্টার টিকা',
          descriptionEn: 'Mandatory 6-month booster for continuous immunity.',
          descriptionBn: 'স্থায়ী রোগ প্রতিরোধ ক্ষমতার জন্য ৬ মাস অন্তর ক্ষুরারোগের বুস্টার ডোজ দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 270,
          category: AppConstants.lcatHealth,
          titleEn: 'Pregnancy diagnosis & dry-period prep',
          titleBn: 'গর্ভ পরীক্ষা ও দুধ দোহন বন্ধের প্রস্তুতি',
          descriptionEn: 'Perform vet palpation for pregnant cows.',
          descriptionBn: 'অভিজ্ঞ পশুচিকিৎসক দ্বারা গর্ভ নিশ্চিত করুন ও বিশ্রামকালীন প্রস্তুতি নিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 365,
          category: AppConstants.lcatHealth,
          titleEn: 'Annual herd health & weight audit',
          titleBn: 'বার্ষিক খামারের স্বাস্থ্য ও দুধ উৎপাদনের হিসাব',
          descriptionEn: 'Review annual milk yield, calf health, and feed conversion.',
          descriptionBn: 'বাৎসরিক গড় দুধ উৎপাদন, বাছুরের বৃদ্ধি ও খামারের লাভ-ক্ষতির হিসাব পর্যালোচনা করুন।',
        ),
      ]);
      if (wantsMilk) {
        raw.addAll([
          const LivestockActivityTemplate(
            dayFromStart: 0,
            category: AppConstants.lcatMilk,
            titleEn: 'Daily morning & evening milking',
            titleBn: 'সকাল ও সন্ধ্যার নিয়মিত দুধ দোহন',
            descriptionEn: 'Sanitize udder with warm water; log milk liters.',
            descriptionBn: 'হালকা গরম পানিতে ওলান ধুয়ে জীবাণুমুক্ত করে দুধ দোহন করুন এবং লিটার হিসাব রাখুন।',
            repeatIntervalDays: 1,
          ),
          const LivestockActivityTemplate(
            dayFromStart: 15,
            category: AppConstants.lcatHealth,
            titleEn: 'Mastitis test (California Mastitis Test)',
            titleBn: 'ওলানপচা (ম্যাসটাইটিস) পরীক্ষা',
            descriptionEn: 'Test milk from all 4 quarters with CMT reagent.',
            descriptionBn: 'সিএমটি কিট দিয়ে চার বাঁটের দুধ পরীক্ষা করে ওলানপচা রোগ আগে থেকেই প্রতিরোধ করুন।',
            repeatIntervalDays: 15,
          ),
        ]);
      }
    } else if (lower.contains('goat') || lower.contains('sheep')) {
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 1,
          category: AppConstants.lcatHealth,
          titleEn: 'Deworming & quarantine inspection',
          titleBn: 'কৃমিনাশক ও খামারে নতুন ছাগল পর্যবেক্ষণ',
          descriptionEn: 'Administer broad-spectrum anthelmintic.',
          descriptionBn: 'ব্রড-স্পেকট্রাম কৃমিনাশক খাওয়ান এবং সুস্থতা পরীক্ষা করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 7,
          category: AppConstants.lcatVaccination,
          titleEn: 'PPR (Peste des Petits Ruminants) vaccine',
          titleBn: 'পিপিআর (PPR) প্রতিষেধক টিকা',
          descriptionEn: 'Inject PPR vaccine subcutaneously (protects for 1 year).',
          descriptionBn: 'চামড়ার নিচে ১ সিসি পিপিআর টিকা দিন (১ বছর পর্যন্ত কার্যকর থাকে)।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 21,
          category: AppConstants.lcatVaccination,
          titleEn: 'Goat Pox / Enterotoxaemia vaccine',
          titleBn: 'গোট পক্স বা এন্টারোটক্সিমিয়া টিকা',
          descriptionEn: 'Administer enterotoxaemia toxoid vaccine.',
          descriptionBn: 'ছাগলের বসন্ত ও পেটফোলা (এন্টারোটক্সিমিয়া) প্রতিরোধক টিকা প্রয়োগ করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 45,
          category: AppConstants.lcatHealth,
          titleEn: 'Hoof trimming & footbath',
          titleBn: 'ক্ষুর ছাঁটাই ও ফুটবাথ',
          descriptionEn: 'Trim overgrown hooves and dip in copper sulfate solution.',
          descriptionBn: 'অতিরিক্ত ক্ষুর কেটে কপার সালফেট বা পটাশ মিশ্রিত ফুটবাথে ক্ষুর চুবিয়ে নিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 90,
          category: AppConstants.lcatHealth,
          titleEn: 'Quarterly deworming & vitamin booster',
          titleBn: 'ত্রৈমাসিক কৃমিনাশক ও ভিটামিন কোর্স',
          descriptionEn: 'Rotate anthelmintic and provide Vitamin AD3E.',
          descriptionBn: '৩ মাস পর কৃমিনাশক পরিবর্তন করুন এবং ভিটামিন এডি৩ই দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 180,
          category: AppConstants.lcatVaccination,
          titleEn: 'Enterotoxaemia 6-month booster',
          titleBn: 'এন্টারোটক্সিমিয়ার ৬ মাসের বুস্টার টিকা',
          descriptionEn: 'Administer booster before seasonal lush grass grazing.',
          descriptionBn: 'বর্ষায় কচি ঘাস খাওয়ানোর আগে এন্টারোটক্সিমিয়ার বুস্টার ডোজ দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 365,
          category: AppConstants.lcatVaccination,
          titleEn: 'Annual PPR booster vaccination',
          titleBn: 'বার্ষিক পিপিআর বুস্টার টিকা',
          descriptionEn: 'Re-vaccinate herd against PPR.',
          descriptionBn: 'পুরো ছাগলের পালে বার্ষিক পিপিআর টিকা পুনরায় দিন।',
        ),
      ]);
    } else if (lower.contains('fish') || lower.contains('carp') || lower.contains('tilapia') || lower.contains('pangas')) {
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 1,
          category: AppConstants.lcatWater,
          titleEn: 'Pond liming & water preparation',
          titleBn: 'চুন প্রয়োগ ও পুকুর প্রস্তুত',
          descriptionEn: 'Apply agricultural lime (1 kg/decimal) to balance pH.',
          descriptionBn: 'পানির পিএইচ ঠিক রাখতে শতকে ১ কেজি হারে কৃষি চুন দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 3,
          category: AppConstants.lcatFeeding,
          titleEn: 'Plankton blooming with organic manure',
          titleBn: 'প্রাকৃতিক প্লাংকটন তৈরি ও জৈব সার',
          descriptionEn: 'Apply decomposed cow dung to generate natural plankton.',
          descriptionBn: 'পুকুরে প্রাকৃতিক খাদ্য উৎপাদনে পচা গোবর ও কম্পোস্ট সার দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 7,
          category: AppConstants.lcatHealth,
          titleEn: 'Fingerling stocking & acclimatization',
          titleBn: 'পোনা মজুদ ও খাপ খাওয়ানো',
          descriptionEn: 'Float fingerling bags in pond water for 30 mins before release.',
          descriptionBn: 'পুকুরের পানিতে পোনার ব্যাগ ৩০ মিনিট ভাসিয়ে রেখে তাপমাত্রা সমান করে পোনা ছাড়ুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 15,
          category: AppConstants.lcatFeeding,
          titleEn: 'Floating pellet feed adjustment',
          titleBn: 'ভাসমান ফিড খাবার নিয়ন্ত্রণ',
          descriptionEn: 'Feed 5% of estimated body weight twice daily.',
          descriptionBn: 'মাছের ওজনের ৫% হারে সকাল ও বিকালে ভাসমান খাবার দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 30,
          category: AppConstants.lcatWater,
          titleEn: 'Water transparency (Secchi disc) test',
          titleBn: 'পানির স্বচ্ছতা (সেকি ডিস্ক) পরীক্ষা',
          descriptionEn: 'Check water depth transparency (target 25-35 cm).',
          descriptionBn: 'সেকি ডিস্ক দিয়ে পানির স্বচ্ছতা মাপুন (আদর্শ মাত্রা ২৫-৩৫ সেমি)।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 60,
          category: AppConstants.lcatWeighing,
          titleEn: 'Sample netting & growth evaluation',
          titleBn: 'নমুনা মাছ ধরা ও ওজন পরিমাপ',
          descriptionEn: 'Net 20 fish to measure weight gain and adjust feed.',
          descriptionBn: 'জাল টেনে ২০টি মাছের ওজন মেপে বৃদ্ধির হার অনুযায়ী খাবার সমন্বয় করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 90,
          category: AppConstants.lcatHealth,
          titleEn: 'Pond disinfection & salt application',
          titleBn: 'পুকুর জীবাণুমুক্তকরণ ও লবণ প্রয়োগ',
          descriptionEn: 'Apply salt or potassium permanganate for gill health.',
          descriptionBn: 'মাছের ফুলকা ও ত্বকের সুরক্ষায় লবণ বা পটাশ ব্যবহার করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 150,
          category: AppConstants.lcatWeighing,
          titleEn: 'Pre-harvest weight & market check',
          titleBn: 'বাজারজাত ওজন যাচাই',
          descriptionEn: 'Verify fish reached target market weight (e.g. >500g-1kg).',
          descriptionBn: 'মাছ বিক্রির উপযুক্ত আকারে পৌঁছেছে কিনা তা যাচাই করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 180,
          category: AppConstants.lcatHealth,
          titleEn: 'Final netting & harvest',
          titleBn: 'চূড়ান্ত জাল টানা ও মাছ ধরা',
          descriptionEn: 'Drain pond partially and harvest mature market fish.',
          descriptionBn: 'পুকুর থেকে পরিণত মাছ ধরে বাজারে বিক্রির ব্যবস্থা করুন।',
        ),
      ]);
    } else {
      // Default general livestock schedule
      raw.addAll([
        const LivestockActivityTemplate(
          dayFromStart: 7,
          category: AppConstants.lcatVaccination,
          titleEn: 'Primary herd vaccination',
          titleBn: 'প্রাথমিক দলগত টিকাদান',
          descriptionEn: 'Administer primary vaccine according to local vet advice.',
          descriptionBn: 'স্থানীয় পশুচিকিৎসকের পরামর্শ অনুযায়ী প্রাথমিক প্রতিষেধক টিকা দিন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 30,
          category: AppConstants.lcatHealth,
          titleEn: 'Deworming & health check',
          titleBn: 'কৃমিনাশক ও স্বাস্থ্য পরীক্ষা',
          descriptionEn: 'Administer anthelmintic and check body condition.',
          descriptionBn: 'কৃমিনাশক খাওয়ান এবং শারীরিক বৃদ্ধি ও স্বাস্থ্য পরীক্ষা করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 90,
          category: AppConstants.lcatHealth,
          titleEn: 'Quarterly health & weight check',
          titleBn: 'ত্রৈমাসিক স্বাস্থ্য ও ওজন পরীক্ষা',
          descriptionEn: 'Inspect herd vitality, feed intake, and growth.',
          descriptionBn: 'প্রাণীর খাবারের রুচি ও দৈহিক বৃদ্ধির হার পর্যবেক্ষণ করুন।',
        ),
        const LivestockActivityTemplate(
          dayFromStart: 180,
          category: AppConstants.lcatVaccination,
          titleEn: '6-month booster vaccination',
          titleBn: '৬ মাসের বুস্টার টিকাদান',
          descriptionEn: 'Administer seasonal booster vaccinations.',
          descriptionBn: 'মৌসুমি রোগ প্রতিরোধে ৬ মাসের বুস্টার টিকা দিন।',
        ),
      ]);
    }

    return raw;
  }
}
