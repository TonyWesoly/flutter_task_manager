class AppConstants {
  // Routing
  static const String appTitle = 'Todo App';
  
  // Date formats
  static const String dateFormat = 'dd-MM-yyyy';
  static const String dateTimeFormat = 'dd-MM-yyyy HH:mm';
  static const String monthDayFormat = 'd MMMM';
  static const String shortDateFormat = 'dd.MM';
  static const String monthYearFormat = 'd MMM';
  
  // Locales
  static const String defaultLocale = 'pl_PL';
  static const String polishLocale = 'pl';
  
  // UI Constants
  static const double iconSizeLarge = 64.0;
  static const double iconSizeMedium = 32.0;
  static const double iconSizeSmall = 18.0;
  static const double paddingDefault = 16.0;
  static const double paddingSmall = 8.0;
  static const double spacingDefault = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingHuge = 38.0;
  
  // Selection
  static const double selectionOpacity = 0.3;
  static const double chartOpacityHigh = 0.8;
  static const double chartOpacityMedium = 0.5;
  static const double chartOpacityLow = 0.3;
  
  // Notifications
  static const String notificationChannelId = 'deadline_reminders';
  static const String notificationChannelName = 'Deadline reminders';
  static const String notificationChannelDescription = 'Powiadomienia o zbliżających się terminach';
  static const Duration testNotificationDelay = Duration(minutes: 1);
  static const Duration notificationFallbackDelay = Duration(minutes: 30);
  
  // Database
  static const String databaseName = 'db.sqlite';
  
  // Week days
  static const List<String> weekDayNames = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];
}

class AppStrings {
  // Titles
  static const String currentTasksTitle = 'Obecne zadania';
  static const String completedTasksTitle = 'Wykonane zadania';
  static const String statisticsTitle = 'Statystyki';
  
  // Task screens
  static const String addTaskTitle = 'Dodaj zadanie';
  static const String editTaskTitle = 'Edytuj zadanie';
  static const String taskTitleHint = 'Tytuł zadania';
  static const String taskTitleRequired = 'Proszę wpisać tytuł zadania';
  static const String selectDate = 'Wybierz datę';
  static const String addDetails = 'Dodaj szczegóły';
  static const String saveButton = 'Zapisz';
  static const String addButton = 'Dodaj';
  
  // Empty states
  static const String noTasksToDo = 'Brak zadań do wykonania!';
  static const String noCompletedTasks = 'Brak wykonanych zadań';
  static const String loadingText = 'Ładowanie...';
  static const String loadingStatistics = 'Ładowanie statystyk...';
  
  // Dialogs
  static const String deleteTaskTitle = 'Usunąć to zadanie?';
  static const String deleteMultipleTasksTitle = 'Usunąć zaznaczone zadania?';
  static const String restoreTaskTitle = 'Przywrócić zadanie?';
  static const String cancelButton = 'Anuluj';
  static const String deleteButton = 'Usuń';
  static const String restoreButton = 'Przywróć';
  
  // Selection mode
  static const String selectedCount = 'Zaznaczono: ';
  static const String markAsCompleteTooltip = 'Oznacz jako wykonane';
  static const String restoreTooltip = 'Przywróć';
  static const String deleteTooltip = 'Usuń';
  
  // Statistics
  static const String totalCompleted = 'Wykonanych ogólnie';
  static const String weekTotal = 'W tym tygodniu';
  static const String currentWeek = 'Ten tydzień';
  static const String previousWeek = 'Poprzedni tydzień';
  static const String nextWeek = 'Następny tydzień';
  static const String todayLabel = 'Dziś';
  
  // Task details
  static const String deadlinePrefix = 'Termin: ';
  static const String completedPrefix = 'Ukończono: ';
  
  // Notifications
  static const String reminderPrefix = 'Przypomnienie: ';
  static const String testNotificationBody = 'Powiadomienie testowe (1 min po dodaniu).';
  static const String tomorrowDeadline = 'Jutro termin: ';
}