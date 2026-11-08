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

	/// ru: 'Изменить'
	String get edit => 'Изменить';

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
	late final Translations$game$ru game = Translations$game$ru._(_root);
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
	late final Translations$misc$ru misc = Translations$misc$ru._(_root);
	late final Translations$d2$ru d2 = Translations$d2$ru._(_root);
}

// Path: errors
class Translations$errors$ru {
	Translations$errors$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Ой, кажется произошла ошибка😢'
	String get crashTitle => 'Ой, кажется произошла ошибка😢';

	/// ru: 'У вас нет доступа к получению информации. Возможно истек срок жизни токенов доступа. Попробуйте очистить данные приложения'
	String get accessDenied => 'У вас нет доступа к получению информации. Возможно истек срок жизни токенов доступа. Попробуйте очистить данные приложения';
}

// Path: time
class Translations$time$ru {
	Translations$time$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: '{minutes}мин {seconds}сек'
	String minutesSeconds({required Object minutes, required Object seconds}) => '${minutes}мин ${seconds}сек';

	/// ru: '{seconds}сек'
	String seconds({required Object seconds}) => '${seconds}сек';
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

// Path: game
class Translations$game$ru {
	Translations$game$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Выйти в меню?'
	String get goToMenu => 'Выйти в меню?';

	/// ru: 'Завершить игру?'
	String get surrender => 'Завершить игру?';

	/// ru: 'Использовать подсказку?'
	String get showHelp => 'Использовать подсказку?';

	/// ru: 'Подсказка пока не готова. Попробуйте позже'
	String get hintNotReady => 'Подсказка пока не готова. Попробуйте позже';

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

	late final Translations$game$combos$ru combos = Translations$game$combos$ru._(_root);
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
	late final Translations$settings$onOff$ru onOff = Translations$settings$onOff$ru._(_root);
	late final Translations$settings$dictUpdPeriod$ru dictUpdPeriod = Translations$settings$dictUpdPeriod$ru._(_root);
	late final Translations$settings$moveTimer$ru moveTimer = Translations$settings$moveTimer$ru._(_root);

	/// ru: 'Просмотр статистики'
	String get statisticSub => 'Просмотр статистики';

	late final Translations$settings$groups$ru groups = Translations$settings$groups$ru._(_root);
	late final Translations$settings$timer$ru timer = Translations$settings$timer$ru._(_root);
	late final Translations$settings$themeMode$ru themeMode = Translations$settings$themeMode$ru._(_root);

	/// ru: 'Статистика'
	String get stats => 'Статистика';
}

// Path: stats
class Translations$stats$ru {
	Translations$stats$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Статистика'
	String get title => 'Статистика';

	/// ru: 'Данные отсутствуют'
	String get noData => 'Данные отсутствуют';

	Map<String, String> get groups => {
		'tt_n_pts': 'Всего сыграно партий',
		'tt_onl': 'Онлайн',
		'hscr': 'Рекорд',
		'combo': 'Комбо',
		'mst_frq_cts': 'Самые загадываемые города',
		'msg_big_cts': 'Самые длинные города',
	};
	Map<String, String> get fields => {
		'pva': 'В режиме против Андроида',
		'pvp': 'В режиме против Игрока',
		'pvn': 'В режиме Мультиплеер',
		'pvo': 'В режиме Онлайн',
		'tim': 'Общее время',
		'win': 'Побед',
		'los': 'Поражений',
		'qt': 'Быстрый ответ',
		'sw': 'Короткие города',
		'lw': 'Длинные города',
		'sc': 'Одна страна',
		'dc': 'Разные страны',
	};
}

// Path: citiesList
class Translations$citiesList$ru {
	Translations$citiesList$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Города'
	String get title => 'Города';

	/// ru: 'Заявки на редактирование'
	String get about => 'Заявки на редактирование';

	/// ru: 'Введите город'
	String get enterCity => 'Введите город';

	/// ru: 'Загрузка базы данных...'
	String get loading => 'Загрузка базы данных...';

	/// ru: 'Неизвестно'
	String get unkCity => 'Неизвестно';

	/// ru: 'Выбрать все'
	String get selectAll => 'Выбрать все';

	/// ru: 'Нужно изменить страну или название'
	String get wantEdit => 'Нужно изменить страну или название';

	/// ru: 'Нужно удалить'
	String get wantRemove => 'Нужно удалить';
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

	late final Translations$gameResults$matchResult$ru matchResult = Translations$gameResults$matchResult$ru._(_root);

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

	/// ru: 'Изменение города'
	String get titleEdit => 'Изменение города';

	/// ru: 'Добавление города'
	String get titleAdd => 'Добавление города';

	/// ru: 'Удаление города'
	String get titleRemove => 'Удаление города';

	List<String> get commonRules => [
		'Вы ввели город без опечатки. Например: *Кешенев* вместо *Кишинев*',
		'Город не был переименован. Например: *Ленинград* вместо *Санкт-Петербург*',
		'Город правильно транслитерирован. Например: *Йокогама* вместо *Иокогама*',
		'Введённый город должен писаться слитно, без тире и пробелов. Например: *Йошкарола* вместо *Йошкар-Ола*',
		'Введённый вами населённый пункт *имеет статус города*. Вы можете проверить это, например, в Википедии',
	];
	List<String> get removingRules => [
		'Населенный пункт может быть удален если он не имеет статуса города',
		'Если город был переименован или указан неверно, используйте форму изменения города',
	];

	/// ru: 'ОТПРАВИТЬ'
	String get send => 'ОТПРАВИТЬ';

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

	/// ru: 'Предлагаемые изменения'
	String get proposedChanges => 'Предлагаемые изменения';

	/// ru: 'Причина изменения или ссылка на источник'
	String get editReasonHint => 'Причина изменения или ссылка на источник';

	/// ru: 'Перед отправкой заявки убедитесь в следующем'
	String get beforeSending => 'Перед отправкой заявки убедитесь в следующем';

	/// ru: 'Добавить город'
	String get addCity => 'Добавить город';

	/// ru: 'Причина добавления или ссылка на источник'
	String get addReasonHint => 'Причина добавления или ссылка на источник';

	/// ru: 'Удалить город'
	String get removeCity => 'Удалить город';

	/// ru: 'Причина удаления'
	String get removeReason => 'Причина удаления';

	/// ru: 'Причина удаления или ссылка на источник'
	String get removeReasonHint => 'Причина удаления или ссылка на источник';

	/// ru: 'Название города'
	String get cityNameHint => 'Название города';

	/// ru: 'Новое название города'
	String get cityNameHelper => 'Новое название города';

	/// ru: 'Город не должен быть пустым'
	String get cityNameEmpty => 'Город не должен быть пустым';

	/// ru: 'Ищем список всех стран...'
	String get searchingCountries => 'Ищем список всех стран...';

	/// ru: 'Страна не определена'
	String get countryNotSet => 'Страна не определена';

	/// ru: 'Принадлежность к стране'
	String get countryHelper => 'Принадлежность к стране';

	/// ru: 'Нужно указать причину внесения изменений'
	String get reasonRequired => 'Нужно указать причину внесения изменений';

	/// ru: 'Заявки на изменение города'
	String get listTitle => 'Заявки на изменение города';

	/// ru: 'Для просмотра информации войдите в профиль'
	String get signInToView => 'Для просмотра информации войдите в профиль';

	/// ru: 'Здесь пока ничего нет. Вы можете самостоятельно отправлять заявки на изменение городов. Мы обязательно рассмотрим вашу заявку. Свои заявки и результаты рассмотрения вы сможете увидеть здесь'
	String get listEmpty => 'Здесь пока ничего нет.\nВы можете самостоятельно отправлять заявки на изменение городов.\nМы обязательно рассмотрим вашу заявку. Свои заявки и результаты рассмотрения вы сможете увидеть здесь';

	/// ru: 'Заявки на рассмотрении'
	String get pendingTitle => 'Заявки на рассмотрении';

	/// ru: 'Ранее рассмотренные заявки'
	String get reviewedTitle => 'Ранее рассмотренные заявки';

	/// ru: 'Что-то пошло не так'
	String get unexpectedState => 'Что-то пошло не так';

	/// ru: 'Что-то пошло не так : {state}'
	String unexpectedStateDetails({required Object state}) => 'Что-то пошло не так : ${state}';

	/// ru: 'Не удалось загрузить данные :( {message}'
	String listLoadingError({required Object message}) => 'Не удалось загрузить данные :(\n${message}';

	/// ru: 'У вас нет открытых заявок'
	String get noPending => 'У вас нет открытых заявок';

	/// ru: 'У вас нет рассмотренных заявок'
	String get noReviewed => 'У вас нет рассмотренных заявок';

	/// ru: 'Причина:'
	String get reasonLabel => 'Причина:';

	/// ru: 'Результат:'
	String get resultLabel => 'Результат:';
}

// Path: firstTimeScreen
class Translations$firstTimeScreen$ru {
	Translations$firstTimeScreen$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get messages => [
		'Добро Пожаловать в игру!',
		'Вы будете загадывать города с\nвашим оппонентом или андроидом по очереди',
		'Каждое последующее слово \nдолжно начинаться на последнюю \nбукву предыдущего слова',
		'Исключение составляют только: ь, ъ, ы, ё',
		'Победителем считается тот, кто в конце игры набрал больше очков или сдался последним',
	];
}

// Path: login
class Translations$login$ru {
	Translations$login$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Обновление картинки профиля'
	String get updatingAvatar => 'Обновление картинки профиля';

	/// ru: 'Не удалось войти через соц.сеть'
	String get socialFailed => 'Не удалось войти через соц.сеть';

	/// ru: 'Что-то пошло не так :(. Попробуйте снова'
	String get failed => 'Что-то пошло не так :(. Попробуйте снова';

	/// ru: 'Вход'
	String get title => 'Вход';

	/// ru: 'Ваше имя'
	String get nameLabel => 'Ваше имя';

	/// ru: 'Используйте вход через социальные сети чтобы не потерять свой аккаунт'
	String get socialHint => 'Используйте вход через социальные сети чтобы не потерять свой аккаунт';

	/// ru: 'Войти'
	String get signIn => 'Войти';

	/// ru: 'или войти используя'
	String get orSignInWith => 'или войти используя';
}

// Path: multiplayer
class Translations$multiplayer$ru {
	Translations$multiplayer$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Мультиплеер'
	String get title => 'Мультиплеер';

	/// ru: 'Запуск сервера...'
	String get startingServer => 'Запуск сервера...';

	/// ru: 'Переподключитесь к Wi-Fi сети или попробуйте снова'
	String get reconnectWifi => 'Переподключитесь к Wi-Fi сети или попробуйте снова';

	/// ru: 'Произошла какая-то ошибка :('
	String get error => 'Произошла какая-то ошибка :(';

	/// ru: 'Для создания соединения вы должны находиться в одной Wi-Fi сети с вашим оппонентом'
	String get sameWifiHint => 'Для создания соединения вы должны находиться в одной Wi-Fi сети с вашим оппонентом';

	/// ru: 'Создать'
	String get create => 'Создать';

	/// ru: 'Присоединиться'
	String get join => 'Присоединиться';

	/// ru: 'Поиск'
	String get search => 'Поиск';

	/// ru: 'Доступные устройства'
	String get availableDevices => 'Доступные устройства';

	/// ru: 'Вы должны находиться в одной сети для поиска устройств'
	String get sameNetworkHint => 'Вы должны находиться в одной сети для поиска устройств';

	/// ru: 'Ничего не найдено. Убедитесь что у оппонента создано соединение и вы находитесь в одной сети'
	String get nothingFound => 'Ничего не найдено. Убедитесь что у оппонента создано соединение и вы находитесь в одной сети';
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

	/// ru: 'Игра начнётся сразу после того, как вам найдётся оппонент. Не забывайте, что на ответ у вас есть полторы минуты'
	String get gameDesc => 'Игра начнётся сразу после того, как вам найдётся оппонент. Не забывайте, что на\nответ у вас есть полторы минуты';

	/// ru: 'Игра'
	String get gameTab => 'Игра';

	/// ru: 'Подключиться'
	String get connect => 'Подключиться';

	/// ru: 'Подключено'
	String get connected => 'Подключено';

	/// ru: 'Подключение к серверу...'
	String get connectingToServer => 'Подключение к серверу...';

	/// ru: 'Не удалось подключиться к серверу.'
	String get connectionError => 'Не удалось подключиться к серверу.';

	/// ru: 'Загрузка профиля...'
	String get fetchingProfile => 'Загрузка профиля...';

	/// ru: 'Авторизация...'
	String get authorization => 'Авторизация...';

	/// ru: 'Ожидание оппонента...'
	String get awaitingForOpp => 'Ожидание оппонента...';

	/// ru: 'Ожидание пользователя {login}'
	String awaitingForInvite({required Object login}) => 'Ожидание пользователя ${login}';

	/// ru: 'Друзья'
	String get friendsTab => 'Друзья';

	/// ru: 'История'
	String get historyTab => 'История';

	/// ru: 'Заблокированные игроки'
	String get blacklistTab => 'Заблокированные игроки';

	/// ru: 'Профиль'
	String get profileTab => 'Профиль';

	/// ru: 'Ваша история игр'
	String get battleHistory => 'Ваша история игр';

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

	/// ru: 'Принять заявку'
	String get acceptFriendshipRequest => 'Принять заявку';

	/// ru: 'Отклонить заявку'
	String get declineFriendshipRequest => 'Отклонить заявку';

	/// ru: 'Отменить заявку'
	String get cancelFriendshipRequest => 'Отменить заявку';

	/// ru: '[Ваша заявка]'
	String get myRequest => '[Ваша заявка]';

	/// ru: 'Заблокировать'
	String get ban => 'Заблокировать';

	/// ru: 'Разблокировать'
	String get unban => 'Разблокировать';

	/// ru: 'Перезагрузить'
	String get reload => 'Перезагрузить';

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

	/// ru: 'У вас пока нет друзей. Вы можете добавить друга во время онлайн игры.'
	String get noFriendsPlaceholder => 'У вас пока нет друзей. Вы можете добавить друга во время онлайн игры.';

	/// ru: 'История игр пока пуста. Сыграйте хотя бы одну игру.'
	String get noHistoryPlaceholder => 'История игр пока пуста. Сыграйте хотя бы одну игру.';

	/// ru: 'Здесь будут отображаться игроки, которых вы внесли в черный список'
	String get noBlacklistPlaceholder => 'Здесь будут отображаться игроки, которых вы внесли в черный список';

	/// ru: 'Администратор'
	String get admin => 'Администратор';

	/// ru: 'Не удалось авторизоваться на сервере'
	String get authFailed => 'Не удалось авторизоваться на сервере';

	/// ru: '[Заблокирован]'
	String get banned => '[Заблокирован]';

	/// ru: 'Пользователь добавил вас в чёрный список'
	String get inputBan => 'Пользователь добавил вас в чёрный список';

	/// ru: 'Был(а) в сети {date}'
	String lastOnline({required Object date}) => 'Был(а) в сети ${date}';

	/// ru: 'вчера, в {time}'
	String yesterday({required Object time}) => 'вчера, в ${time}';

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

	/// ru: 'Приглашение в игру от {login}'
	String invitationFrom({required Object login}) => 'Приглашение в игру от ${login}';

	/// ru: 'Не удалось принять запрос от пользователя: Вы не авторизованы в аккаунте'
	String get acceptFailedNotSignedIn => 'Не удалось принять запрос от пользователя: Вы не авторизованы в аккаунте';

	/// ru: 'Вы получили приглашение от пользователя, но сейчас находитесь в другом аккаунте'
	String get wrongAccount => 'Вы получили приглашение от пользователя, но сейчас находитесь в другом аккаунте';

	/// ru: 'Произошла неизвестная ошибка :('
	String get unknownError => 'Произошла неизвестная ошибка :(';
}

// Path: misc
class Translations$misc$ru {
	Translations$misc$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Камера'
	String get camera => 'Камера';

	/// ru: 'Галерея'
	String get gallery => 'Галерея';
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

	/// ru: 'Статистика'
	String get statistics => 'Статистика';

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

// Path: settings.onOff
class Translations$settings$onOff$ru {
	Translations$settings$onOff$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Выкл'
	String get off => 'Выкл';

	/// ru: 'Вкл'
	String get on => 'Вкл';
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

// Path: settings.moveTimer
class Translations$settings$moveTimer$ru {
	Translations$settings$moveTimer$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Выкл'
	String get off => 'Выкл';

	/// ru: '{n} мин'
	String minutes({required Object n}) => '${n} мин';
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

// Path: gameResults.matchResult
class Translations$gameResults$matchResult$ru {
	Translations$gameResults$matchResult$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Вы победили!'
	String get win => 'Вы победили!';

	/// ru: 'Вы проиграли'
	String get lose => 'Вы проиграли';

	/// ru: 'Ничья!'
	String get draw => 'Ничья!';
}

// Path: online.invitationResult
class Translations$online$invitationResult$ru {
	Translations$online$invitationResult$ru._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ru: 'Пользователь уже занят'
	String get busy => 'Пользователь уже занят';

	/// ru: 'Пользователь отклонил ваше приглашение'
	String get denied => 'Пользователь отклонил ваше приглашение';

	/// ru: 'Приглашение не может быть доставлено'
	String get noUser => 'Приглашение не может быть доставлено';

	/// ru: 'Пользователь должен быть у вас в друзьях!'
	String get notFriend => 'Пользователь должен быть у вас в друзьях!';
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
