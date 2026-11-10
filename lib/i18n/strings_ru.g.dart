///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsRu = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <ru>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// ru: 'Да'
	String get yes => 'Да';

	/// ru: 'Нет'
	String get no => 'Нет';

	/// ru: 'Отмена'
	String get cancel => 'Отмена';

	/// ru: 'Назад'
	String get back => 'Назад';

	/// ru: 'Добавить'
	String get add => 'Добавить';

	/// ru: 'Применить'
	String get apply => 'Применить';

	/// ru: 'Принять'
	String get accept => 'Принять';

	/// ru: 'Отклонить'
	String get decline => 'Отклонить';

	/// ru: 'Удалить'
	String get delete => 'Удалить';

	late final Translations$errors$ru errors = Translations$errors$ru._(_root);
	late final Translations$time$ru time = Translations$time$ru._(_root);
	late final Translations$players$ru players = Translations$players$ru._(_root);
	late final Translations$home$ru home = Translations$home$ru._(_root);
	late final Translations$route$ru route = Translations$route$ru._(_root);
	late final Translations$profile$ru profile = Translations$profile$ru._(_root);
	late final Translations$game$ru game = Translations$game$ru._(_root);
	late final Translations$hotseat$ru hotseat = Translations$hotseat$ru._(_root);
	late final Translations$settings$ru settings = Translations$settings$ru._(_root);
	late final Translations$stats$ru stats = Translations$stats$ru._(_root);
	late final Translations$citiesList$ru citiesList = Translations$citiesList$ru._(_root);
	late final Translations$exclusionList$ru exclusionList = Translations$exclusionList$ru._(_root);
	late final Translations$gameResults$ru gameResults = Translations$gameResults$ru._(_root);
	late final Translations$citiesRequest$ru citiesRequest = Translations$citiesRequest$ru._(_root);
	late final Translations$firstTimeScreen$ru firstTimeScreen = Translations$firstTimeScreen$ru._(_root);
	late final Translations$login$ru login = Translations$login$ru._(_root);
	late final Translations$multiplayer$ru multiplayer = Translations$multiplayer$ru._(_root);
	late final Translations$online$ru online = Translations$online$ru._(_root);
	late final Translations$achievements$ru achievements = Translations$achievements$ru._(_root);
	late final Translations$misc$ru misc = Translations$misc$ru._(_root);
	late final Translations$d2$ru d2 = Translations$d2$ru._(_root);
}

// Path: errors
class Translations$errors$ru {
	Translations$errors$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Что-то сломалось'
	String get crashTitle => 'Что-то сломалось';

	/// ru: 'У вас нет доступа к получению информации. Возможно истек срок жизни токенов доступа. Попробуйте очистить данные приложения'
	String get accessDenied => 'У вас нет доступа к получению информации. Возможно истек срок жизни токенов доступа. Попробуйте очистить данные приложения';

	/// ru: 'Вернитесь назад и попробуйте ещё раз'
	String get crashHint => 'Вернитесь назад и попробуйте ещё раз';

	/// ru: 'Скрыть'
	String get hideDetails => 'Скрыть';
}

// Path: time
class Translations$time$ru {
	Translations$time$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: '{minutes} мин {seconds} с'
	String minutesSeconds({required Object minutes, required Object seconds}) => '${minutes} мин ${seconds} с';

	/// ru: '{seconds} с'
	String seconds({required Object seconds}) => '${seconds} с';
}

// Path: players
class Translations$players$ru {
	Translations$players$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Игрок'
	String get player => 'Игрок';

	/// ru: 'Андроид'
	String get android => 'Андроид';

	/// ru: 'Игрок 1'
	String get firstPlayer => 'Игрок 1';

	/// ru: 'Игрок 2'
	String get secondPlayer => 'Игрок 2';
}

// Path: home
class Translations$home$ru {
	Translations$home$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Города'
	String get title => 'Города';

	/// ru: 'С компьютером'
	String get vsComputer => 'С компьютером';

	/// ru: 'Вдвоём'
	String get twoPlayers => 'Вдвоём';

	/// ru: 'По Wi-Fi'
	String get wifi => 'По Wi-Fi';

	/// ru: 'Онлайн'
	String get online => 'Онлайн';

	/// ru: 'Играть'
	String get play => 'Играть';

	/// ru: 'Настройки'
	String get settings => 'Настройки';

	/// ru: 'Профиль'
	String get profile => 'Профиль';
}

// Path: route
class Translations$route$ru {
	Translations$route$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Классика'
	String get variantClassic => 'Классика';

	/// ru: 'Маршрут'
	String get variantRoute => 'Маршрут';

	/// ru: 'Город на последнюю букву предыдущего'
	String get hintClassic => 'Город на последнюю букву предыдущего';

	/// ru: 'Очки — километры между городами'
	String get hintRoute => 'Очки — километры между городами';

	/// ru: 'Город на букву'
	String get letterCaption => 'Город на букву';

	/// ru: 'Ход {n} из {total}'
	String move({required Object n, required Object total}) => 'Ход ${n} из ${total}';

	/// ru: 'км'
	String get km => 'км';

	/// ru: 'пропуск хода'
	String get skipped => 'пропуск хода';

	/// ru: '(one) {Схема маршрута: {n} город, последний — {city}} (few) {Схема маршрута: {n} города, последний — {city}} (many) {Схема маршрута: {n} городов, последний — {city}} (other) {Схема маршрута: {n} городов, последний — {city}}'
	String mapLabel({required num n, required Object city}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		one: 'Схема маршрута: ${n} город, последний — ${city}',
		few: 'Схема маршрута: ${n} города, последний — ${city}',
		many: 'Схема маршрута: ${n} городов, последний — ${city}',
		other: 'Схема маршрута: ${n} городов, последний — ${city}',
	);

	/// ru: '{owner}: {city} ({country}), плюс {km} км'
	String feedItem({required Object owner, required Object city, required Object country, required Object km}) => '${owner}: ${city} (${country}), плюс ${km} км';

	/// ru: 'Вы'
	String get you => 'Вы';

	/// ru: 'стран'
	String get countries => 'стран';

	/// ru: 'самый длинный перелёт'
	String get longestLeg => 'самый длинный\nперелёт';

	/// ru: 'городов'
	String get cities => 'городов';

	/// ru: 'Поделиться маршрутом'
	String get share => 'Поделиться маршрутом';

	/// ru: 'Не получилось поделиться'
	String get shareFailed => 'Не получилось поделиться';

	/// ru: '(one) {Мой маршрут в «Сыграем в Города»: {km} км, {countries} страна https://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities} (few) {Мой маршрут в «Сыграем в Города»: {km} км, {countries} страны https://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities} (many) {Мой маршрут в «Сыграем в Города»: {km} км, {countries} стран https://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities} (other) {Мой маршрут в «Сыграем в Города»: {km} км, {countries} стран https://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities}'
	String shareText({required num countries, required Object km}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(countries,
		one: 'Мой маршрут в «Сыграем в Города»: ${km} км, ${countries} страна\nhttps://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities',
		few: 'Мой маршрут в «Сыграем в Города»: ${km} км, ${countries} страны\nhttps://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities',
		many: 'Мой маршрут в «Сыграем в Города»: ${km} км, ${countries} стран\nhttps://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities',
		other: 'Мой маршрут в «Сыграем в Города»: ${km} км, ${countries} стран\nhttps://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities',
	);
}

// Path: profile
class Translations$profile$ru {
	Translations$profile$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Профиль'
	String get title => 'Профиль';

	/// ru: 'Паспорт'
	String get passport => 'Паспорт';

	/// ru: '(one) {{count} страна} (few) {{count} страны} (many) {{count} стран} (other) {{count} стран}'
	String countriesCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} страна',
		few: '${count} страны',
		many: '${count} стран',
		other: '${count} стран',
	);

	/// ru: '(one) {Ещё {count} страна} (few) {Ещё {count} страны} (many) {Ещё {count} стран} (other) {Ещё {count} стран}'
	String moreCountries({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Ещё ${count} страна',
		few: 'Ещё ${count} страны',
		many: 'Ещё ${count} стран',
		other: 'Ещё ${count} стран',
	);

	/// ru: 'Все'
	String get all => 'Все';

	/// ru: '(one) {побед онлайн из {count}} (few) {побед онлайн из {count}} (many) {побед онлайн из {count}} (other) {побед онлайн из {count}}'
	String onlineWinsOf({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'побед онлайн из ${count}',
		few: 'побед онлайн из ${count}',
		many: 'побед онлайн из ${count}',
		other: 'побед онлайн из ${count}',
	);

	/// ru: 'Достижения'
	String get achievements => 'Достижения';

	/// ru: '{title}, ещё не получено'
	String achievementLocked({required Object title}) => '${title}, ещё не получено';

	/// ru: 'Рейтинг'
	String get rating => 'Рейтинг';

	/// ru: 'Друзья'
	String get friends => 'Друзья';

	/// ru: 'История'
	String get history => 'История';

	/// ru: 'Чёрный список'
	String get blacklist => 'Чёрный список';

	/// ru: 'Статистика'
	String get stats => 'Статистика';

	/// ru: 'Настройки'
	String get settings => 'Настройки';

	/// ru: 'Войти'
	String get signIn => 'Войти';

	/// ru: 'онлайн'
	String get online => 'онлайн';
}

// Path: game
class Translations$game$ru {
	Translations$game$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Выйти в меню?'
	String get goToMenu => 'Выйти в меню?';

	/// ru: 'Сдаться?'
	String get surrender => 'Сдаться?';

	/// ru: 'Использовать подсказку?'
	String get showHelp => 'Использовать подсказку?';

	/// ru: 'На эту букву подсказок больше нет'
	String get hintUnavailable => 'На эту букву подсказок больше нет';

	/// ru: 'Загрузка обновлений {percent}%'
	String downloadingUpdates({required Object percent}) => 'Загрузка обновлений ${percent}%';

	/// ru: 'Проверка обновлений словаря'
	String get checkingForUpdates => 'Проверка обновлений словаря';

	/// ru: 'Загрузка базы данных'
	String get loadingDatabase => 'Загрузка базы данных';

	/// ru: 'Сообщение'
	String get messageHint => 'Сообщение';

	/// ru: 'Варианты исправления'
	String get corrections => 'Варианты исправления';

	/// ru: 'Город {city} уже был загадан'
	String alreadyUsed({required Object city}) => 'Город ${city} уже был загадан';

	/// ru: 'Город должен начинаться на букву {letter}'
	String wrongLetter({required Object letter}) => 'Город должен начинаться на букву ${letter}';

	/// ru: 'Очень жаль, но нам неизвестен город {city}. Проверьте правильность написания'
	String unknownCity({required Object city}) => 'Очень жаль, но нам неизвестен город ${city}.\nПроверьте правильность написания';

	/// ru: 'Пауза'
	String get pause => 'Пауза';

	/// ru: 'Продолжить'
	String get resume => 'Продолжить';

	/// ru: 'Правила игры'
	String get rules => 'Правила игры';

	/// ru: 'Выйти в меню'
	String get exitToMenu => 'Выйти в меню';

	/// ru: 'Сдаться…'
	String get surrenderMenu => 'Сдаться…';

	/// ru: 'Подсказка'
	String get hint => 'Подсказка';

	/// ru: 'Подсказка через {time}'
	String hintIn({required Object time}) => 'Подсказка через ${time}';

	/// ru: 'Город на букву'
	String get cityOnLetter => 'Город на букву';

	/// ru: 'Город на {letter}…'
	String cityOnLetterHint({required Object letter}) => 'Город на ${letter}…';

	/// ru: 'Город…'
	String get cityHint => 'Город…';

	/// ru: '?'
	String get letterAny => '?';

	/// ru: 'Буква хода: любая'
	String get letterAnySemantics => 'Буква хода: любая';

	/// ru: 'Чат'
	String get chat => 'Чат';

	/// ru: '(one) {Чат, {count} новое сообщение} (few) {Чат, {count} новых сообщения} (many) {Чат, {count} новых сообщений} (other) {Чат, {count} новых сообщений}'
	String chatUnread({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Чат, ${count} новое сообщение',
		few: 'Чат, ${count} новых сообщения',
		many: 'Чат, ${count} новых сообщений',
		other: 'Чат, ${count} новых сообщений',
	);

	/// ru: 'Ваш ход'
	String get yourTurn => 'Ваш ход';

	/// ru: '(one) {Осталась {s} секунда} (few) {Осталось {s} секунды} (many) {Осталось {s} секунд} (other) {Осталось {s} секунд}'
	String secondsLeft({required num s}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(s,
		one: 'Осталась ${s} секунда',
		few: 'Осталось ${s} секунды',
		many: 'Осталось ${s} секунд',
		other: 'Осталось ${s} секунд',
	);

	/// ru: 'Отправить'
	String get send => 'Отправить';

	late final Translations$game$combos$ru combos = Translations$game$combos$ru._(_root);

	/// ru: 'Партия закончится поражением'
	String get surrenderMessage => 'Партия закончится поражением';

	/// ru: 'Сдаться'
	String get surrenderConfirm => 'Сдаться';

	/// ru: 'Выйти'
	String get exitConfirm => 'Выйти';

	/// ru: 'Остаться'
	String get stay => 'Остаться';
}

// Path: hotseat
class Translations$hotseat$ru {
	Translations$hotseat$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Передайте телефон'
	String get passPhone => 'Передайте телефон';

	/// ru: 'Ход: {name}'
	String turnOf({required Object name}) => 'Ход: ${name}';

	/// ru: 'Игрок 1'
	String get player1 => 'Игрок 1';

	/// ru: 'Игрок 2'
	String get player2 => 'Игрок 2';

	/// ru: 'Я готов'
	String get ready => 'Я готов';

	/// ru: 'Имя первого игрока'
	String get nameLabel1 => 'Имя первого игрока';

	/// ru: 'Имя второго игрока'
	String get nameLabel2 => 'Имя второго игрока';

	/// ru: 'Таймер на паузе'
	String get timerPaused => 'Таймер на паузе';
}

// Path: settings
class Translations$settings$ru {
	Translations$settings$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Настройки'
	String get settings => 'Настройки';

	late final Translations$settings$settingsItemTitles$ru settingsItemTitles = Translations$settings$settingsItemTitles$ru._(_root);
	late final Translations$settings$difficulty$ru difficulty = Translations$settings$difficulty$ru._(_root);
	late final Translations$settings$scoringType$ru scoringType = Translations$settings$scoringType$ru._(_root);
	late final Translations$settings$dictUpdPeriod$ru dictUpdPeriod = Translations$settings$dictUpdPeriod$ru._(_root);
	late final Translations$settings$groups$ru groups = Translations$settings$groups$ru._(_root);
	late final Translations$settings$timer$ru timer = Translations$settings$timer$ru._(_root);
	late final Translations$settings$themeMode$ru themeMode = Translations$settings$themeMode$ru._(_root);

	/// ru: 'Лицензии'
	String get licenses => 'Лицензии';
}

// Path: stats
class Translations$stats$ru {
	Translations$stats$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Статистика'
	String get title => 'Статистика';

	Map<String, String> get groups => {
		'tt_n_pts': 'Всего сыграно партий',
		'tt_onl': 'Онлайн',
		'hscr': 'Рекорд',
		'combo': 'Комбо',
		'mst_frq_cts': 'Частые города',
		'msg_big_cts': 'Самые длинные города',
		'countries': 'Страны',
	};
	Map<String, String> get fields => {
		'pva': 'С компьютером',
		'pvp': 'Вдвоём',
		'pvn': 'По Wi-Fi',
		'pvo': 'Онлайн',
		'tim': 'Общее время',
		'win': 'Побед',
		'los': 'Поражений',
		'qt': 'Быстрый ответ',
		'sw': 'Короткие города',
		'lw': 'Длинные города',
		'sc': 'Одна страна',
		'dc': 'Разные страны',
	};

	/// ru: '(one) {партия} (few) {партии} (many) {партий} (other) {партий}'
	String games({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'партия',
		few: 'партии',
		many: 'партий',
		other: 'партий',
	);

	/// ru: '(one) {победа} (few) {победы} (many) {побед} (other) {побед}'
	String wins({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'победа',
		few: 'победы',
		many: 'побед',
		other: 'побед',
	);

	/// ru: '(one) {поражение} (few) {поражения} (many) {поражений} (other) {поражений}'
	String losses({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'поражение',
		few: 'поражения',
		many: 'поражений',
		other: 'поражений',
	);

	/// ru: 'Время в игре'
	String get timeInGame => 'Время в игре';

	/// ru: '{hours} ч {minutes} мин'
	String durationHm({required Object hours, required Object minutes}) => '${hours} ч ${minutes} мин';

	/// ru: '{minutes} мин'
	String durationM({required Object minutes}) => '${minutes} мин';

	/// ru: 'Пока пусто'
	String get emptyTitle => 'Пока пусто';

	/// ru: 'Статистика появится после первой партии'
	String get emptyText => 'Статистика появится после первой партии';
}

// Path: citiesList
class Translations$citiesList$ru {
	Translations$citiesList$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Города'
	String get title => 'Города';

	/// ru: 'Неизвестно'
	String get unkCity => 'Неизвестно';

	/// ru: 'Мои заявки'
	String get myRequests => 'Мои заявки';

	/// ru: 'Найти город'
	String get searchHint => 'Найти город';

	/// ru: 'Все страны'
	String get allCountries => 'Все страны';

	/// ru: '(one) {{count} страна} (few) {{count} страны} (many) {{count} стран} (other) {{count} стран}'
	String countriesN({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} страна',
		few: '${count} страны',
		many: '${count} стран',
		other: '${count} стран',
	);

	/// ru: 'Предложить город'
	String get proposeCity => 'Предложить город';

	/// ru: 'Предложить правку'
	String get proposeEdit => 'Предложить правку';

	/// ru: 'Предложить удаление'
	String get proposeRemove => 'Предложить удаление';

	/// ru: 'Действия: {city}'
	String cityActions({required Object city}) => 'Действия: ${city}';

	/// ru: 'Страны'
	String get countriesTitle => 'Страны';

	/// ru: 'Найти страну'
	String get countrySearch => 'Найти страну';

	/// ru: 'Недавние'
	String get recent => 'Недавние';

	/// ru: 'Сбросить'
	String get reset => 'Сбросить';
}

// Path: exclusionList
class Translations$exclusionList$ru {
	Translations$exclusionList$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: '{city} это страна'
	String thisIsACountry({required Object city}) => '${city} это страна';

	/// ru: '{city} это название штата'
	String thisIsAState({required Object city}) => '${city} это название штата';

	/// ru: '{city} не является городом'
	String thisIsNotACity({required Object city}) => '${city} не является городом';

	/// ru: 'Город {city} ранее был переименован в {new_name}.'
	String renamedCity({required Object city, required Object newName}) => 'Город ${city} ранее был переименован в ${newName}.';

	/// ru: 'Возможно вы имели в виду город {city} ?'
	String incompleteCity({required Object city}) => 'Возможно вы имели в виду город ${city} ?';

	/// ru: '{city} не является городом. Это {kind}'
	String notACity({required Object city, required Object kind}) => '${city} не является городом. Это ${kind}';
}

// Path: gameResults
class Translations$gameResults$ru {
	Translations$gameResults$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Ваш счёт: '
	String get score => 'Ваш счёт: ';

	/// ru: 'Мой счёт {score} очков в игре Сыграем в Города! https://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities Сможешь набрать больше?'
	String shareScore({required Object score}) => 'Мой счёт ${score} очков в игре Сыграем в Города!\nhttps://play.google.com/store/apps/details?id=ru.aleshi.letsplaycities\n Сможешь набрать больше?';

	/// ru: 'Победа!'
	String get winTitle => 'Победа!';

	/// ru: 'Поражение'
	String get loseTitle => 'Поражение';

	/// ru: 'Ничья'
	String get drawTitle => 'Ничья';

	/// ru: 'городов'
	String get cities => 'городов';

	/// ru: 'время'
	String get time => 'время';

	/// ru: 'самый длинный город'
	String get longestCity => 'самый длинный город';

	/// ru: 'Комбо'
	String get comboTitle => 'Комбо';

	/// ru: '×{count}'
	String comboTimes({required Object count}) => '×${count}';

	/// ru: 'Сыграть ещё'
	String get playAgain => 'Сыграть ещё';

	/// ru: 'В меню'
	String get toMenu => 'В меню';

	/// ru: 'Поделиться'
	String get share => 'Поделиться';

	/// ru: 'У {name} вышло время'
	String descTimeout({required Object name}) => 'У ${name} вышло время';

	/// ru: '{name} отключился'
	String descDisconnected({required Object name}) => '${name} отключился';

	/// ru: '{name} сдался'
	String descSurrender({required Object name}) => '${name} сдался';

	/// ru: 'Вы играли с:'
	String get youPlayedWith => 'Вы играли с:';
}

// Path: citiesRequest
class Translations$citiesRequest$ru {
	Translations$citiesRequest$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Правка города'
	String get titleEdit => 'Правка города';

	/// ru: 'Новый город'
	String get titleAdd => 'Новый город';

	/// ru: 'Удаление города'
	String get titleRemove => 'Удаление города';

	List<String> get commonRules => [
		'Без опечаток\n~Кешенев~ → *Кишинёв*',
		'Нынешнее название\n~Ленинград~ → *Санкт-Петербург*',
		'Принятая транслитерация\n~Иокогама~ → *Йокогама*',
		'Слитно, без дефисов и пробелов\n~Йошкар-Ола~ → *Йошкарола*',
		'Это город, а не село или посёлок',
	];
	List<String> get removingRules => [
		'Удаляем только то, что не город\nСёла, посёлки, районы',
		'Город переименован или записан с ошибкой?',
	];

	/// ru: 'Отправить'
	String get send => 'Отправить';

	/// ru: 'Город с названием "{city}" не найден в базе данных'
	String cityNotFound({required Object city}) => 'Город с названием "${city}" не найден в базе данных';

	/// ru: 'Не удалось загрузить данные. Попробуйте открыть экран еще раз'
	String get formLoadingError => 'Не удалось загрузить данные. Попробуйте открыть экран еще раз';

	/// ru: 'Произошла какая-то сетевая ошибка. Попробуйте еще раз'
	String get networkError => 'Произошла какая-то сетевая ошибка. Попробуйте еще раз';

	/// ru: 'Для того, чтобы отправлять запрос нужно авторизоваться. Вы можете сделать это в профиле'
	String get signInToSend => 'Для того, чтобы отправлять запрос нужно авторизоваться. Вы можете сделать это в профиле';

	/// ru: 'Заявка отправлена!'
	String get requestSent => 'Заявка отправлена!';

	/// ru: 'Перед отправкой'
	String get beforeSending => 'Перед отправкой';

	/// ru: 'Город не должен быть пустым'
	String get cityNameEmpty => 'Город не должен быть пустым';

	/// ru: 'Ищем список всех стран...'
	String get searchingCountries => 'Ищем список всех стран...';

	/// ru: 'Нужно указать причину внесения изменений'
	String get reasonRequired => 'Нужно указать причину внесения изменений';

	/// ru: 'Мои заявки'
	String get listTitle => 'Мои заявки';

	/// ru: 'Для просмотра информации войдите в профиль'
	String get signInToView => 'Для просмотра информации войдите в профиль';

	/// ru: 'Предложите город или правку — ответ появится здесь'
	String get listEmpty => 'Предложите город или правку — ответ появится здесь';

	/// ru: 'На рассмотрении'
	String get pendingTitle => 'На рассмотрении';

	/// ru: 'Рассмотренные'
	String get reviewedTitle => 'Рассмотренные';

	/// ru: 'Ответ'
	String get resultLabel => 'Ответ';

	/// ru: 'Отозвать'
	String get withdraw => 'Отозвать';

	/// ru: 'Заявка отозвана'
	String get withdrawn => 'Заявка отозвана';

	/// ru: 'Добавить город'
	String get typeAdd => 'Добавить город';

	/// ru: 'Изменить город'
	String get typeEdit => 'Изменить город';

	/// ru: 'Удалить город'
	String get typeRemove => 'Удалить город';

	/// ru: 'Принята'
	String get statusApproved => 'Принята';

	/// ru: 'Отклонена'
	String get statusDeclined => 'Отклонена';

	/// ru: 'меняем на'
	String get changesTo => 'меняем на';

	/// ru: 'Заявок пока нет'
	String get listEmptyTitle => 'Заявок пока нет';

	/// ru: 'Сейчас в словаре'
	String get currentCity => 'Сейчас в словаре';

	/// ru: 'Название'
	String get nameLabel => 'Название';

	/// ru: 'Страна'
	String get countryLabel => 'Страна';

	/// ru: 'Причина или ссылка'
	String get reasonFieldLabel => 'Причина или ссылка';

	/// ru: 'Нужен вход'
	String get signInTitle => 'Нужен вход';
}

// Path: firstTimeScreen
class Translations$firstTimeScreen$ru {
	Translations$firstTimeScreen$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'На последнюю букву'
	String get step1Title => 'На последнюю букву';

	/// ru: 'Называйте города по очереди. Каждый начинается на букву, которой закончился предыдущий'
	String get step1Text => 'Называйте города по очереди. Каждый начинается на букву, которой закончился предыдущий';

	/// ru: 'Омск'
	String get step1From => 'Омск';

	/// ru: 'Киров'
	String get step1To => 'Киров';

	/// ru: 'Ь, Ъ, Ы и Ё пропускаем'
	String get step2Title => 'Ь, Ъ, Ы и Ё пропускаем';

	/// ru: 'Берите букву перед ними'
	String get step2Text => 'Берите букву перед ними';

	/// ru: 'Тверь'
	String get step2From => 'Тверь';

	/// ru: 'Рига'
	String get step2To => 'Рига';

	/// ru: 'Больше очков — победа'
	String get step3Title => 'Больше очков — победа';

	/// ru: 'Или соперник сдаётся первым'
	String get step3Text => 'Или соперник сдаётся первым';

	/// ru: 'Пропустить'
	String get skip => 'Пропустить';

	/// ru: 'Дальше'
	String get next => 'Дальше';

	/// ru: 'Шаг {step} из {total}'
	String stepOf({required Object step, required Object total}) => 'Шаг ${step} из ${total}';
}

// Path: login
class Translations$login$ru {
	Translations$login$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Не удалось войти через соц.сеть'
	String get socialFailed => 'Не удалось войти через соц.сеть';

	/// ru: 'Что-то пошло не так :(. Попробуйте снова'
	String get failed => 'Что-то пошло не так :(. Попробуйте снова';

	/// ru: 'Войти через Google'
	String get google => 'Войти через Google';

	/// ru: 'Войти через VK ID'
	String get vkId => 'Войти через VK ID';

	/// ru: 'или играть как гость'
	String get orGuest => 'или играть как гость';

	/// ru: 'Имя'
	String get name => 'Имя';

	/// ru: 'Играть'
	String get play => 'Играть';

	Map<String, String> get errors => {
		'bad_name': 'Имя должно содержать от 2 до 64 символов',
		'forbidden_name': 'Это имя использовать нельзя',
		'banned': 'Аккаунт заблокирован',
		'too_many_requests': 'Слишком много попыток, попробуйте позже',
		'provider_disabled': 'Вход через эту соцсеть недоступен',
		'invalid_provider_token': 'Не удалось подтвердить вход через соцсеть',
		'provider_unavailable': 'Соцсеть временно недоступна',
	};
}

// Path: multiplayer
class Translations$multiplayer$ru {
	Translations$multiplayer$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'По Wi-Fi рядом'
	String get wifiTitle => 'По Wi-Fi рядом';

	/// ru: 'Создать игру'
	String get createGame => 'Создать игру';

	/// ru: 'Вас видно рядом'
	String get visibleNearby => 'Вас видно рядом';

	/// ru: '{device}'
	String deviceMode({required Object device}) => '${device}';

	/// ru: 'Ждём соперника'
	String get waitingOpponent => 'Ждём соперника';

	/// ru: 'Отменить'
	String get cancelCreate => 'Отменить';

	/// ru: 'Присоединиться'
	String get join => 'Присоединиться';

	/// ru: 'Оба телефона должны быть в одной сети Wi-Fi'
	String get sameWifi => 'Оба телефона должны быть в одной сети Wi-Fi';

	/// ru: 'Игры рядом'
	String get gamesNearby => 'Игры рядом';

	/// ru: 'Ничего не найдено'
	String get nothingFound => 'Ничего не найдено';

	/// ru: 'Повторить'
	String get retry => 'Повторить';

	/// ru: 'Переподключитесь к Wi-Fi сети или попробуйте снова'
	String get reconnectWifi => 'Переподключитесь к Wi-Fi сети или попробуйте снова';

	/// ru: 'Произошла какая-то ошибка :('
	String get error => 'Произошла какая-то ошибка :(';
}

// Path: online
class Translations$online$ru {
	Translations$online$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Онлайн'
	String get title => 'Онлайн';

	/// ru: 'Выйти'
	String get signOut => 'Выйти';

	/// ru: 'Найти соперника'
	String get connect => 'Найти соперника';

	/// ru: 'Подключаемся…'
	String get connectingToServer => 'Подключаемся…';

	/// ru: 'Загрузка профиля...'
	String get fetchingProfile => 'Загрузка профиля...';

	/// ru: 'Авторизация...'
	String get authorization => 'Авторизация...';

	/// ru: 'Ищем соперника'
	String get awaitingForOpp => 'Ищем соперника';

	/// ru: 'Ждём ответа {login}…'
	String awaitingForInvite({required Object login}) => 'Ждём ответа ${login}…';

	/// ru: 'Отменить'
	String get cancelInvite => 'Отменить';

	/// ru: '(one) {Ищем {count} секунду} (few) {Ищем {count} секунды} (many) {Ищем {count} секунд} (other) {Ищем {count} секунды}'
	String searchingFor({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Ищем ${count} секунду',
		few: 'Ищем ${count} секунды',
		many: 'Ищем ${count} секунд',
		other: 'Ищем ${count} секунды',
	);

	/// ru: 'Друзья'
	String get friendsTab => 'Друзья';

	/// ru: 'История'
	String get historyTab => 'История';

	/// ru: 'Заблокированные игроки'
	String get blacklistTab => 'Заблокированные игроки';

	/// ru: 'Ваши партии'
	String get battleHistory => 'Ваши партии';

	/// ru: 'Загрузка...'
	String get loading => 'Загрузка...';

	/// ru: 'Не удалось загрузить данные'
	String get loadingError => 'Не удалось загрузить данные';

	/// ru: 'При загрузке данных произошла ошибка'
	String get unkError => 'При загрузке данных произошла ошибка';

	/// ru: 'Пригласить в игру'
	String get invite => 'Пригласить в игру';

	/// ru: 'Добавить в друзья'
	String get addToFriend => 'Добавить в друзья';

	/// ru: 'Удалить из друзей'
	String get removeFromFriends => 'Удалить из друзей';

	/// ru: 'Принять'
	String get acceptFriendshipRequest => 'Принять';

	/// ru: 'Отклонить'
	String get declineFriendshipRequest => 'Отклонить';

	/// ru: 'Отменить'
	String get cancelFriendshipRequest => 'Отменить';

	/// ru: 'Заблокировать'
	String get ban => 'Заблокировать';

	/// ru: 'Разблокировать'
	String get unban => 'Разблокировать';

	/// ru: 'Повторить'
	String get reload => 'Повторить';

	/// ru: 'В меню'
	String get toMenu => 'В меню';

	/// ru: 'Нет связи с сервером'
	String get noConnection => 'Нет связи с сервером';

	/// ru: 'Проверьте интернет и попробуйте ещё раз'
	String get noConnectionHint => 'Проверьте интернет и попробуйте ещё раз';

	/// ru: 'Вход с другого устройства'
	String get replaced => 'Вход с другого устройства';

	/// ru: 'Подождите пару секунд'
	String get rateLimited => 'Подождите пару секунд';

	/// ru: 'Обновите приложение'
	String get updateApp => 'Обновите приложение';

	/// ru: 'Игра уже идёт'
	String get hostFull => 'Игра уже идёт';

	/// ru: '{login} удален из друзей'
	String removedFromFriends({required Object login}) => '${login} удален из друзей';

	/// ru: 'Запись удалена'
	String get banlistEntryRemoved => 'Запись удалена';

	/// ru: 'Пользователь заблокирован!'
	String get userBanned => 'Пользователь заблокирован!';

	/// ru: 'Пользователь разблокирован!'
	String get userUnbanned => 'Пользователь разблокирован!';

	/// ru: 'Заявка отменена'
	String get requestCancelled => 'Заявка отменена';

	/// ru: 'Заявка принята'
	String get requestAccepted => 'Заявка принята';

	/// ru: 'Заявка отклонена'
	String get requestDeclined => 'Заявка отклонена';

	/// ru: 'Добавляйте соперников в друзья после партии'
	String get noFriendsPlaceholder => 'Добавляйте соперников в друзья после партии';

	/// ru: 'Друзей пока нет'
	String get friendsEmptyTitle => 'Друзей пока нет';

	/// ru: 'Игрок добавил вас в чёрный список'
	String get inputBan => 'Игрок добавил вас в чёрный список';

	/// ru: 'Заявки в друзья'
	String get friendRequests => 'Заявки в друзья';

	/// ru: 'Мои друзья'
	String get myFriends => 'Мои друзья';

	/// ru: 'Имя или ID'
	String get searchHint => 'Имя или ID';

	/// ru: 'Заявка отправлена'
	String get requestSent => 'Заявка отправлена';

	/// ru: 'Пригласить'
	String get inviteShort => 'Пригласить';

	/// ru: 'Все друзья'
	String get allFriends => 'Все друзья';

	/// ru: '{name}, в сети'
	String friendOnline({required Object name}) => '${name}, в сети';

	/// ru: 'Пригласить в игру: {name}'
	String inviteNamed({required Object name}) => 'Пригласить в игру: ${name}';

	late final Translations$online$lastSeen$ru lastSeen = Translations$online$lastSeen$ru._(_root);
	Map<String, String> get apiErrors => {
		'bad_image': 'Не удалось обработать картинку',
		'too_large': 'Картинка слишком большая',
		'blocked': 'Между вами есть блокировка',
		'self': 'Нельзя выбрать себя',
		'not_found': 'Пользователь не найден',
		'banned': 'Аккаунт заблокирован',
		'too_many_requests': 'Слишком много запросов, попробуйте позже',
		'already_reviewed': 'Заявка уже рассмотрена',
		'bad_reason': 'Причина слишком длинная',
		'bad_request': 'Не удалось отправить запрос',
	};

	/// ru: '(one) {{count} слово} (few) {{count} слова} (many) {{count} слов} (other) {{count} слов}'
	String wordsCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} слово',
		few: '${count} слова',
		many: '${count} слов',
		other: '${count} слов',
	);

	late final Translations$online$invitationResult$ru invitationResult = Translations$online$invitationResult$ru._(_root);

	/// ru: 'Вы не авторизованы в аккаунте'
	String get notSignedIn => 'Вы не авторизованы в аккаунте';

	/// ru: 'Не удалось выполнить действие'
	String get actionFailed => 'Не удалось выполнить действие';

	/// ru: 'Не удалось изменить аватар'
	String get avatarChangeFailed => 'Не удалось изменить аватар';

	/// ru: '{name} приглашает вас сыграть'
	String invitesYou({required Object name}) => '${name} приглашает вас сыграть';

	/// ru: 'Хочет добавить вас в друзья'
	String get wantsFriendship => 'Хочет добавить вас в друзья';

	/// ru: 'В вашем чёрном списке'
	String get inYourBlacklist => 'В вашем чёрном списке';

	/// ru: 'Партий пока нет'
	String get historyEmptyTitle => 'Партий пока нет';

	/// ru: 'Список пуст'
	String get blacklistEmptyTitle => 'Список пуст';

	/// ru: 'в друзьях'
	String get friendMark => 'в друзьях';

	/// ru: 'Добавляйте соперников в друзья после партии. Здесь их можно будет позвать в игру'
	String get friendsHint => 'Добавляйте соперников в друзья после партии. Здесь их можно будет позвать в игру';

	/// ru: 'Аватар'
	String get avatarTitle => 'Аватар';

	/// ru: 'Разблокировать: {name}'
	String unbanNamed({required Object name}) => 'Разблокировать: ${name}';

	List<String> get months => [
		'Январь',
		'Февраль',
		'Март',
		'Апрель',
		'Май',
		'Июнь',
		'Июль',
		'Август',
		'Сентябрь',
		'Октябрь',
		'Ноябрь',
		'Декабрь',
	];
	List<String> get monthsGenitive => [
		'января',
		'февраля',
		'марта',
		'апреля',
		'мая',
		'июня',
		'июля',
		'августа',
		'сентября',
		'октября',
		'ноября',
		'декабря',
	];
	List<String> get monthsShort => [
		'янв',
		'фев',
		'мар',
		'апр',
		'мая',
		'июн',
		'июл',
		'авг',
		'сен',
		'окт',
		'ноя',
		'дек',
	];
}

// Path: achievements
class Translations$achievements$ru {
	Translations$achievements$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: '15 городов'
	String get write15Cities => '15 городов';

	/// ru: '3 подсказки'
	String get use3Tips => '3 подсказки';

	/// ru: 'Первый друг'
	String get add1Friend => 'Первый друг';

	/// ru: 'Сложный режим'
	String get playInHardMode => 'Сложный режим';

	/// ru: '1000 очков'
	String get reachScore1000Pts => '1000 очков';

	/// ru: '80 городов'
	String get write80Cities => '80 городов';

	/// ru: 'Вход через соцсеть'
	String get loginViaSocial => 'Вход через соцсеть';

	/// ru: 'Смена темы'
	String get changeTheme => 'Смена темы';

	/// ru: '50 городов за партию'
	String get write50CitiesInGame => '50 городов за партию';

	/// ru: '3 онлайн-партии'
	String get playOnline3Times => '3 онлайн-партии';

	/// ru: '30 подсказок'
	String get use30Tips => '30 подсказок';

	/// ru: '5000 очков'
	String get reachScore5000Pts => '5000 очков';

	/// ru: '500 городов'
	String get write500Cities => '500 городов';

	/// ru: '100 городов за партию'
	String get write100CitiesInGame => '100 городов за партию';

	/// ru: '25000 очков'
	String get reachScore25000Pts => '25000 очков';
}

// Path: misc
class Translations$misc$ru {
	Translations$misc$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Сделать фото'
	String get camera => 'Сделать фото';

	/// ru: 'Выбрать из галереи'
	String get gallery => 'Выбрать из галереи';
}

// Path: d2
class Translations$d2$ru {
	Translations$d2$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Буква хода: {letter}'
	String letterSemantics({required Object letter}) => 'Буква хода: ${letter}';

	/// ru: 'Назад'
	String get back => 'Назад';

	/// ru: 'Закрыть'
	String get close => 'Закрыть';

	/// ru: 'Подробнее'
	String get details => 'Подробнее';

	/// ru: 'Сыграем в Города'
	String get logoSemantics => 'Сыграем в Города';

	late final Translations$d2$nav$ru nav = Translations$d2$nav$ru._(_root);
}

// Path: game.combos
class Translations$game$combos$ru {
	Translations$game$combos$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Быстрый ответ'
	String get quickTime => 'Быстрый ответ';

	/// ru: 'Короткие города'
	String get shortWord => 'Короткие города';

	/// ru: 'Длинные города'
	String get longWord => 'Длинные города';

	/// ru: 'Одна страна'
	String get sameCountry => 'Одна страна';

	/// ru: 'Разные страны'
	String get differentCountries => 'Разные страны';
}

// Path: settings.settingsItemTitles
class Translations$settings$settingsItemTitles$ru {
	Translations$settings$settingsItemTitles$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Сложность'
	String get difficulty => 'Сложность';

	/// ru: 'Подсчёт очков'
	String get scoring => 'Подсчёт очков';

	/// ru: 'Таймер хода'
	String get moveTimer => 'Таймер хода';

	/// ru: 'Автоисправление'
	String get correction => 'Автоисправление';

	/// ru: 'Звук'
	String get sound => 'Звук';

	/// ru: 'Чат'
	String get onlineChat => 'Чат';

	/// ru: 'Обновление словаря'
	String get dictUpdates => 'Обновление словаря';

	/// ru: 'Тема'
	String get theme => 'Тема';
}

// Path: settings.difficulty
class Translations$settings$difficulty$ru {
	Translations$settings$difficulty$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Легко'
	String get easy => 'Легко';

	/// ru: 'Нормально'
	String get medium => 'Нормально';

	/// ru: 'Сложно'
	String get hard => 'Сложно';
}

// Path: settings.scoringType
class Translations$settings$scoringType$ru {
	Translations$settings$scoringType$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'По очкам'
	String get byScore => 'По очкам';

	/// ru: 'По времени'
	String get byTime => 'По времени';

	/// ru: 'До сдачи'
	String get lastMove => 'До сдачи';
}

// Path: settings.dictUpdPeriod
class Translations$settings$dictUpdPeriod$ru {
	Translations$settings$dictUpdPeriod$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Выкл'
	String get never => 'Выкл';

	/// ru: 'Каждые 3ч'
	String get threeHours => 'Каждые 3ч';

	/// ru: 'Каждый день'
	String get daily => 'Каждый день';
}

// Path: settings.groups
class Translations$settings$groups$ru {
	Translations$settings$groups$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Игра'
	String get game => 'Игра';

	/// ru: 'Онлайн'
	String get online => 'Онлайн';

	/// ru: 'Приложение'
	String get app => 'Приложение';
}

// Path: settings.timer
class Translations$settings$timer$ru {
	Translations$settings$timer$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: '30 с'
	String get s30 => '30 с';

	/// ru: '1 мин'
	String get m1 => '1 мин';

	/// ru: '2 мин'
	String get m2 => '2 мин';

	/// ru: 'Нет'
	String get off => 'Нет';
}

// Path: settings.themeMode
class Translations$settings$themeMode$ru {
	Translations$settings$themeMode$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Светлая'
	String get light => 'Светлая';

	/// ru: 'Тёмная'
	String get dark => 'Тёмная';

	/// ru: 'Как в системе'
	String get system => 'Как в системе';
}

// Path: online.lastSeen
class Translations$online$lastSeen$ru {
	Translations$online$lastSeen$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'в сети'
	String get now => 'в сети';

	/// ru: 'в сети в {time}'
	String today({required Object time}) => 'в сети в ${time}';

	/// ru: 'в сети вчера'
	String get yesterday => 'в сети вчера';

	/// ru: '(one) {в сети {count} день назад} (few) {в сети {count} дня назад} (many) {в сети {count} дней назад} (other) {в сети {count} дней назад}'
	String daysAgo({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'в сети ${count} день назад',
		few: 'в сети ${count} дня назад',
		many: 'в сети ${count} дней назад',
		other: 'в сети ${count} дней назад',
	);

	/// ru: 'в сети {date}'
	String date({required Object date}) => 'в сети ${date}';
}

// Path: online.invitationResult
class Translations$online$invitationResult$ru {
	Translations$online$invitationResult$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Пользователь отклонил ваше приглашение'
	String get declined => 'Пользователь отклонил ваше приглашение';

	/// ru: 'Пользователь уже занят'
	String get busy => 'Пользователь уже занят';

	/// ru: 'Приглашение не может быть доставлено'
	String get offline => 'Приглашение не может быть доставлено';

	/// ru: 'Пользователь должен быть у вас в друзьях'
	String get notFriends => 'Пользователь должен быть у вас в друзьях';

	/// ru: 'Между вами есть блокировка'
	String get blocked => 'Между вами есть блокировка';

	/// ru: 'Пользователь не ответил на приглашение'
	String get expired => 'Пользователь не ответил на приглашение';

	/// ru: 'Приглашение уже недействительно'
	String get replyExpired => 'Приглашение уже недействительно';

	/// ru: 'Не удалось принять приглашение'
	String get replyRejected => 'Не удалось принять приглашение';
}

// Path: d2.nav
class Translations$d2$nav$ru {
	Translations$d2$nav$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Играть'
	String get play => 'Играть';

	/// ru: 'Города'
	String get cities => 'Города';

	/// ru: 'Профиль'
	String get profile => 'Профиль';
}
