# Как сохранение оценки связано с MVVM

Разбор текущего dev на моках. Указатели относятся к версии кода на 8 октября 2026 года; после изменения этих мест обновлять ссылки.

## От карточки до базы

1. [Кнопка «Оценить»:37](../AbsoluteCinema/Features/MovieDetails/MovieDetailsView.swift#L37) открывает форму RatingEditorView.
   Пользователь выбирает число в [RatingEditorView.swift:11](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift#L11).
   Привязка `$viewModel.draftRating` записывает выбор в свойство ViewModel. В этот момент база не меняется.
2. Аналогично [TextEditor:19](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift#L19) меняет `viewModel.comment`.
3. [Кнопка сохранения:29](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift#L29) вызывает `viewModel.save()`.
   View знает, какое действие произошло, и передаёт его ViewModel.
4. [MovieDetailsViewModel.save():80](../AbsoluteCinema/Features/MovieDetails/MovieDetailsViewModel.swift#L80) проверяет `canSave` и вызывает репозиторий.
   После успеха он обновляет сохранённую оценку и возвращает true: форма закрывается. После ошибки форма остаётся открытой с сообщением.
5. [RatingRepository.save():40](../AbsoluteCinema/Data/Repositories/RatingRepository.swift#L40) находит запись по ID, меняет её или создаёт новую.
   Вызов `context.save()` записывает изменения через SwiftData. При ошибке `rollback()` откатывает несохранённые изменения контекста.
6. Репозиторий возвращает обычную структуру SavedRating. ViewModel сохраняет её в `savedRating`, и SwiftUI обновляет зависимые элементы карточки.

Получается один путь: действие пользователя → View → ViewModel → RatingRepository → SwiftData.
Результат проходит обратно через состояние ViewModel к View.

## Что означают незнакомые конструкции

| Конструкция в проекте | Роль в этом сценарии |
| --- | --- |
| `@Observable` у ViewModel | Позволяет SwiftUI отслеживать изменения свойств, которые читает интерфейс |
| `@State private var viewModel` в карточке | Карточка владеет своим экземпляром ViewModel; ViewModel вкладок принадлежат ContentView |
| `@Bindable var viewModel` в форме | Форма использует существующую ViewModel карточки и получает привязки к её свойствам |
| `$viewModel.comment` | Связывает текстовое поле со свойством ViewModel для чтения и изменения |
| `private(set)` | Другой объект может прочитать свойство, но меняет его только сам владелец |
| `throws`, `try`, `do/catch` | Метод может завершиться ошибкой; вызывающий код обрабатывает этот случай |
| `@Model` у RatedMovie | Делает класс сохраняемой моделью SwiftData |
| `@Attribute(.unique)` у movieID | Задаёт уникальность ID в хранилище |
| `@MainActor` | Ограничивает работу с объектом главным actor, связанным с главным потоком приложения |

## Два состояния оценки

`draftRating` и `comment` — то, что пользователь сейчас редактирует.
`savedRating` — последняя прочитанная или успешно сохранённая запись.
Их сравнение в [hasChanges:27](../AbsoluteCinema/Features/MovieDetails/MovieDetailsViewModel.swift#L27) позволяет включить сохранение только при изменениях.
Разделение также сохраняет ввод пользователя, если запись в базу завершилась ошибкой.

`RatedMovie` представляет запись базы, `Movie` — сведения о фильме, `SavedRating` — результат чтения оценки вместе со сведениями о фильме.
[snapshot:37](../AbsoluteCinema/Data/Persistence/RatedMovie.swift#L37) переводит сохраняемый объект в обычную структуру для экрана.

## Кто создаёт объекты и обновляет список

[AbsoluteCinemaApp.swift:13](../AbsoluteCinema/AbsoluteCinemaApp.swift#L13) создаёт ModelContainer и общие RatingRepository и WatchlistRepository.
ContentView передаёт репозитории ViewModel карточки и списков, поэтому они обращаются к одному хранилищу.

При появлении карточки [onAppear:79](../AbsoluteCinema/Features/MovieDetails/MovieDetailsView.swift#L79) вызывает `loadRating()` и `loadWatchlist()`.
После записи репозиторий увеличивает `revision`; [RatingsView:46](../AbsoluteCinema/Features/Ratings/RatingsView.swift#L46) замечает изменение и вызывает `reload()`.
[RatingsViewModel.reload():21](../AbsoluteCinema/Features/Ratings/RatingsViewModel.swift#L21) перечитывает записи, и список отображает новое состояние.
`revision` — обычное число для уведомления об изменениях, введённое в этом проекте; это не специальный механизм SwiftData.

Для знакомства с кодом достаточно пройти этот сценарий в указанном порядке, начиная с уже знакомой кнопки во View.
Подключение сети позднее изменит источник сведений о фильме; граница между действиями View и логикой ViewModel сохранится.

## Как работает «Хочу посмотреть»

Кнопка карточки вызывает `toggleWatchlist()` в той же ViewModel. Он обращается к WatchlistRepository, который сохраняет или удаляет WatchlistMovie.
У этой модели нет обязательной личной оценки. WatchlistViewModel читает фильмы для списка; его revision обновляется независимо от репозитория оценок.
Список передаёт сохранённый Movie в навигацию, поэтому карточка не зависит от наличия фильма в моковом массиве.
