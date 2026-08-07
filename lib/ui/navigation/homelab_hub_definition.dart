/// Home Lab prototype destinations. Keeping these definitions in a tiny file
/// avoids coupling the router to the hub UI implementation and keeps upstream
/// rebases straightforward.
enum HomelabHubKind { movies, tv, anime }

abstract final class HomelabHubRoutes {
  static const movies = '/hub/movies';
  static const tv = '/hub/tv';
  static const anime = '/hub/anime';
}

extension HomelabHubKindX on HomelabHubKind {
  String get title => switch (this) {
        HomelabHubKind.movies => 'Movies',
        HomelabHubKind.tv => 'TV',
        HomelabHubKind.anime => 'Anime',
      };

  String get route => switch (this) {
        HomelabHubKind.movies => HomelabHubRoutes.movies,
        HomelabHubKind.tv => HomelabHubRoutes.tv,
        HomelabHubKind.anime => HomelabHubRoutes.anime,
      };
}
