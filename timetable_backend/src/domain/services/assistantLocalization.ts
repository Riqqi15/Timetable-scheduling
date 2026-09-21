export type AssistantLanguage = 'id' | 'en' | 'zh-Hans' | 'ar';

export type AssistantRouteStepText = {
  text: string;
  detailNote: string;
  durationText: string;
};

export type AssistantScheduleText = {
  departureTime: string;
  trainName: string;
  destination: string;
  platform: string;
  calendarCode?: string;
  dayOffset?: number;
};

export const resolveAssistantLanguage = (
  value?: string | null,
): AssistantLanguage => {
  const normalized = (value ?? 'id').replace('_', '-').toLowerCase();
  if (normalized.startsWith('en')) return 'en';
  if (normalized.startsWith('zh')) return 'zh-Hans';
  if (normalized.startsWith('ar')) return 'ar';
  return 'id';
};

const forLanguage = <T>(
  language: AssistantLanguage,
  values: Record<AssistantLanguage, T>,
): T => values[language];

export const assistantPromptCopy = (lang?: string | null) => {
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return {
        languageInstruction:
          'Answer warmly, clearly, and naturally in English. Do not use Markdown such as **text**.',
        outOfScopeReply:
          'Sorry, I can only help with KRL Commuter Line travel information and app usage.',
      };
    case 'zh-Hans':
      return {
        languageInstruction:
          '请始终使用简体中文，以温暖、清晰、自然的方式回答。不要使用 **文字** 之类的 Markdown 格式。',
        outOfScopeReply:
          '抱歉，我只能协助查询KRL通勤铁路出行信息和应用使用方法。',
      };
    case 'ar':
      return {
        languageInstruction:
          'أجب دائمًا باللغة العربية بأسلوب واضح وطبيعي وودود. لا تستخدم تنسيق Markdown مثل **النص**.',
        outOfScopeReply:
          'عذرًا، يمكنني المساعدة فقط في معلومات رحلات قطارات KRL واستخدام التطبيق.',
      };
    case 'id':
      return {
        languageInstruction:
          'Jawab hangat, jelas, dan natural dalam bahasa Indonesia. Jangan gunakan Markdown seperti **teks**.',
        outOfScopeReply:
          'Maaf, aku hanya dapat membantu informasi perjalanan KRL Commuter Line dan penggunaan aplikasi.',
      };
  }
};

const hintText = (hints: string[], language: AssistantLanguage): string => {
  if (hints.length === 0) {
    return forLanguage(language, {
      id: 'Sebutkan nama stasiun KRL-nya ya.',
      en: 'Please tell me the KRL station name.',
      'zh-Hans': '请告诉我KRL车站名称。',
      ar: 'اذكر اسم محطة KRL من فضلك.',
    });
  }
  const examples = hints.slice(0, 2).join(
    language === 'id' ? ' atau ' : language === 'en' ? ' or ' : language === 'zh-Hans' ? '或' : ' أو ',
  );
  return forLanguage(language, {
    id: `Misalnya ${examples}.`,
    en: `For example ${examples}.`,
    'zh-Hans': `例如${examples}。`,
    ar: `مثل ${examples}.`,
  });
};

export const localizedAreaClarification = (
  area: string,
  destination?: string | null,
  hints: string[] = [],
  lang: string = 'id',
): string => {
  const language = resolveAssistantLanguage(lang);
  const cleanArea = area.trim();
  const destinationName = destination?.trim();
  const hintsCopy = hintText(hints, language);
  switch (language) {
    case 'en':
      return `For the ${cleanArea} area, which KRL station will you depart from? ${hintsCopy} 🚆 After you choose, I'll find the route${destinationName ? ` to ${destinationName}` : ''}.`;
    case 'zh-Hans':
      return `从${cleanArea}地区出发时，你会从哪个KRL车站上车？${hintsCopy} 🚆 选好车站后，我会为你查找${destinationName ? `前往${destinationName}的` : ''}路线。`;
    case 'ar':
      return `بالنسبة إلى منطقة ${cleanArea}، من أي محطة KRL ستبدأ رحلتك؟ ${hintsCopy} 🚆 بعد اختيار المحطة، سأبحث لك عن المسار${destinationName ? ` إلى ${destinationName}` : ''}.`;
    case 'id':
      return `Kalau dari kawasan ${cleanArea}, kamu berangkat dari stasiun KRL mana? ${hintsCopy} 🚆 Setelah pilih stasiunnya, aku carikan rute${destinationName ? ` ke ${destinationName}` : ''}.`;
  }
};

export const localizedDestinationAreaClarification = (
  area: string,
  origin?: string | null,
  hints: string[] = [],
  lang: string = 'id',
): string => {
  const language = resolveAssistantLanguage(lang);
  const cleanArea = area.trim();
  const originName = origin?.trim();
  const hintsCopy = hintText(hints, language);
  switch (language) {
    case 'en':
      return `To reach the ${cleanArea} area${originName ? ` from ${originName}` : ''}, which KRL station do you want to get off at? ${hintsCopy} 🚆 Tell me the station and I'll find the route.`;
    case 'zh-Hans':
      return `前往${cleanArea}地区时${originName ? `（从${originName}出发）` : ''}，你想在哪个KRL车站下车？${hintsCopy} 🚆 告诉我车站后，我会为你查找路线。`;
    case 'ar':
      return `للوصول إلى منطقة ${cleanArea}${originName ? ` انطلاقًا من ${originName}` : ''}، في أي محطة KRL تريد النزول؟ ${hintsCopy} 🚆 أخبرني بالمحطة وسأبحث لك عن المسار.`;
    case 'id':
      return `Kalau menuju kawasan ${cleanArea}${originName ? ` dari ${originName}` : ''}, kamu mau turun di stasiun KRL mana? ${hintsCopy} 🚆 Sebutkan stasiun tujuannya, nanti aku carikan rutenya.`;
  }
};

export const localizedNoScheduleMessage = (
  station: string,
  lang: string = 'id',
): string => {
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return `I haven't found any schedule data for ${station} in the app yet. Please check the station information board or the official KAI Commuter source for the latest departures 🚆`;
    case 'zh-Hans':
      return `应用中尚未找到${station}的时刻表数据。请查看车站信息屏或KAI Commuter官方渠道获取最新发车信息 🚆`;
    case 'ar':
      return `لم نعثر بعد على بيانات جدول محطة ${station} في التطبيق. تحقق من لوحة معلومات المحطة أو المصدر الرسمي لـ KAI Commuter لمعرفة أحدث مواعيد المغادرة 🚆`;
    case 'id':
      return `Belum ada data jadwal untuk ${station} di aplikasi. Cek papan informasi stasiun atau sumber resmi KAI Commuter untuk waktu keberangkatan terbaru ya 🚆`;
  }
};

export const localizedRouteNotFoundMessage = (lang: string = 'id'): string => {
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return 'Hmm, I couldn\'t find a route for that pair. Please check the origin and destination station names, for example “from Bekasi to Jakarta Kota” 🚆';
    case 'zh-Hans':
      return '嗯，我没有找到这两个车站之间的路线。请检查出发站和目的站名称，例如“从Bekasi到Jakarta Kota” 🚆';
    case 'ar':
      return 'لم أجد مسارًا بين هاتين المحطتين. تحقق من اسمي محطة الانطلاق والوجهة، مثل "من Bekasi إلى Jakarta Kota" 🚆';
    case 'id':
      return 'Waduh, aku belum menemukan rute untuk pasangan itu. Boleh cek lagi nama stasiun asal dan tujuannya ya? Misalnya "dari Bekasi ke Jakarta Kota" 🚆';
  }
};

export const localizedSameOriginMessage = (lang: string = 'id'): string => {
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return 'Your origin and destination are the same 😄 Try a different station?';
    case 'zh-Hans':
      return '出发站和目的站相同 😄 请换一个车站。';
    case 'ar':
      return 'محطة الانطلاق والوجهة هما نفس المحطة 😄 جرّب محطة مختلفة.';
    case 'id':
      return 'Asal dan tujuannya sama nih 😄 Coba stasiun yang berbeda ya?';
  }
};

const translateDuration = (value: string, language: AssistantLanguage) => {
  if (language === 'id') return value;
  const match = value.match(/^(\d+)\s+menit$/i);
  if (!match) return value;
  return forLanguage(language, {
    id: value,
    en: `${match[1]} minutes`,
    'zh-Hans': `${match[1]}分钟`,
    ar: `${match[1]} دقيقة`,
  });
};

const translateStepText = (value: string, language: AssistantLanguage) => {
  if (language === 'id') return value;
  const patterns: Array<[RegExp, (match: RegExpMatchArray) => string]> = [
    [
      /^Naik dari (.+)$/i,
      (match) =>
        language === 'en'
          ? `Board at ${match[1]}`
          : language === 'zh-Hans'
            ? `在${match[1]}上车`
            : `اركب من ${match[1]}`,
    ],
    [
      /^Lanjut naik (.+)$/i,
      (match) =>
        language === 'en'
          ? `Continue on ${match[1]}`
          : language === 'zh-Hans'
            ? `继续乘坐${match[1]}`
            : `تابع على ${match[1]}`,
    ],
    [
      /^Berjalan dari (.+) menuju Stasiun (.+)$/i,
      (match) =>
        language === 'en'
          ? `Walk from ${match[1]} to ${match[2]} Station`
          : language === 'zh-Hans'
            ? `从${match[1]}步行前往${match[2]}站`
            : `امشِ من ${match[1]} إلى محطة ${match[2]}`,
    ],
    [
      /^Pindah peron di (.+)$/i,
      (match) =>
        language === 'en'
          ? `Change platforms at ${match[1]}`
          : language === 'zh-Hans'
            ? `在${match[1]}换乘站台`
            : `غيّر الرصيف في ${match[1]}`,
    ],
    [
      /^Tiba di (.+)$/i,
      (match) =>
        language === 'en'
          ? `Arrive at ${match[1]}`
          : language === 'zh-Hans'
            ? `抵达${match[1]}`
            : `الوصول إلى ${match[1]}`,
    ],
  ];
  for (const [pattern, translate] of patterns) {
    const match = value.match(pattern);
    if (match) return translate(match);
  }
  return value;
};

const translateDetail = (value: string, language: AssistantLanguage) => {
  if (language === 'id') return value;
  if (/^Tujuan$/i.test(value)) {
    return language === 'en' ? 'Destination' : language === 'zh-Hans' ? '目的地' : 'الوجهة';
  }
  const transfer = value.match(/^Pindah ke (.+)$/i);
  if (transfer) {
    return language === 'en'
      ? `Transfer to ${transfer[1]}`
      : language === 'zh-Hans'
        ? `换乘${transfer[1]}`
        : `انتقل إلى ${transfer[1]}`;
  }
  const fromTo = value.match(/^Dari (.+) menuju (.+)$/i);
  if (fromTo) {
    return language === 'en'
      ? `From ${fromTo[1]} toward ${fromTo[2]}`
      : language === 'zh-Hans'
        ? `从${fromTo[1]}前往${fromTo[2]}`
        : `من ${fromTo[1]} باتجاه ${fromTo[2]}`;
  }
  const toward = value.match(/^(.+) menuju (.+)$/i);
  if (toward) {
    return language === 'en'
      ? `${toward[1]} toward ${toward[2]}`
      : language === 'zh-Hans'
        ? `${toward[1]}前往${toward[2]}`
        : `${toward[1]} باتجاه ${toward[2]}`;
  }
  return value;
};

export const localizeAssistantRouteStep = (
  step: AssistantRouteStepText,
  lang: string = 'id',
): AssistantRouteStepText => {
  const language = resolveAssistantLanguage(lang);
  return {
    text: translateStepText(step.text, language),
    detailNote: translateDetail(step.detailNote, language),
    durationText: translateDuration(step.durationText, language),
  };
};

export const localizedRouteIntro = (
  from: string,
  to: string,
  lang: string = 'id',
) => {
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return `Here is your route from ${from} to ${to} 🚆`;
    case 'zh-Hans':
      return `这是从${from}前往${to}的路线 🚆`;
    case 'ar':
      return `إليك المسار من ${from} إلى ${to} 🚆`;
    case 'id':
      return `Bisa, ini rute dari ${from} ke ${to} 🚆`;
  }
};

export const localizedRouteSummary = (
  travelTime: number,
  fare: number,
  lang: string = 'id',
) => {
  const formattedFare = fare.toLocaleString('id-ID');
  switch (resolveAssistantLanguage(lang)) {
    case 'en':
      return `Estimated travel: ${travelTime} minutes · Fare: Rp${formattedFare}`;
    case 'zh-Hans':
      return `预计行程：${travelTime}分钟 · 票价：Rp${formattedFare}`;
    case 'ar':
      return `المدة التقديرية: ${travelTime} دقيقة · الأجرة: Rp${formattedFare}`;
    case 'id':
      return `Estimasi perjalanan ${travelTime} menit · Tarif Rp${formattedFare}`;
  }
};

export const buildLocalizedScheduleList = (
  stationName: string,
  departures: AssistantScheduleText[],
  lang: string = 'id',
): string => {
  const language = resolveAssistantLanguage(lang);
  const header = forLanguage(language, {
    id: `Beberapa jadwal keberangkatan dari ${stationName} (WIB) 🚆`,
    en: `Some scheduled departures from ${stationName} (WIB) 🚆`,
    'zh-Hans': `以下是从${stationName}出发的部分时刻表（WIB）🚆`,
    ar: `بعض مواعيد المغادرة من ${stationName} بتوقيت غرب إندونيسيا (WIB) 🚆`,
  });
  const lines = departures.slice(0, 5).map((departure) => {
    const nextDay = departure.dayOffset
      ? language === 'id'
        ? ' (+1 hari)'
        : language === 'en'
          ? ' (+1 day)'
          : language === 'zh-Hans'
            ? '（次日）'
            : ' (+1 يوم)'
      : '';
    const destination = language === 'id'
      ? ` ke ${departure.destination}`
      : language === 'en'
        ? ` to ${departure.destination}`
        : language === 'zh-Hans'
          ? ` 前往${departure.destination}`
          : ` إلى ${departure.destination}`;
    const platform = departure.platform
      ? language === 'id'
        ? ` (peron ${departure.platform})`
        : language === 'en'
          ? ` (platform ${departure.platform})`
          : language === 'zh-Hans'
            ? `（${departure.platform}号站台）`
            : ` (الرصيف ${departure.platform})`
      : '';
    const weekday = departure.calendarCode === 'WEEKDAY'
      ? language === 'id'
        ? ' · hari kerja, kecuali libur nasional'
        : language === 'en'
          ? ' · weekdays, excluding public holidays'
          : language === 'zh-Hans'
            ? ' · 工作日，公共假日除外'
            : ' · أيام العمل، باستثناء العطلات الرسمية'
      : '';
    return `• ${departure.departureTime}${nextDay} — ${departure.trainName}${destination}${platform}${weekday}`;
  }).join('\n');
  const footer = forLanguage(language, {
    id: 'Ini jadwal PDF, bukan real-time atau daftar kereta yang akan datang saat ini. Buka Jadwal dan pilih stasiun/hari untuk daftar lengkap; cek papan stasiun bila ada perubahan.',
    en: 'This is a PDF timetable, not real-time information or a list of trains approaching now. Open Schedule and choose a station and day for the full list; check the station board for changes.',
    'zh-Hans': '这是PDF时刻表，不是实时信息，也不是当前即将到站的列车列表。请打开“时刻表”并选择车站和日期查看完整列表；如有变更，请查看车站信息屏。',
    ar: 'هذا جدول PDF وليس معلومات لحظية أو قائمة بالقطارات القادمة الآن. افتح صفحة الجدول واختر المحطة واليوم لعرض القائمة الكاملة، وتحقق من لوحة المحطة عند وجود تغييرات.',
  });
  return `${header}\n${lines}\n\n${footer}`;
};
