import 'seerr_discovery_schema.dart';

/// Versioned built-in fallback for Home Lab Discovery.
///
/// This is intentionally separate from the existing Moonbase Home/Movies/TV/
/// Anime editorial rows. It is the deep-browse catalogue used when a future
/// server-delivered catalogue is unavailable or invalid.
const homeLabDiscoveryCatalogue = SeerrDiscoveryCatalogue(
  schemaVersion: 1,
  tabs: [
    SeerrDiscoveryTab(
      id: 'for-you',
      title: 'For You',
      sections: [
        SeerrDiscoverySection(
          id: 'for-you-because-you-watched',
          title: 'Because You Watched',
          subtitle: 'Recommendations seeded from your recent viewing',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.personalised,
            mediaType: 'all',
            seedStrategy: 'history',
          ),
          dedupGroup: 'personal',
        ),
        SeerrDiscoverySection(
          id: 'for-you-favourites',
          title: 'More Like Your Favourites',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.personalised,
            mediaType: 'all',
            seedStrategy: 'favourites',
          ),
          dedupGroup: 'personal',
        ),
        SeerrDiscoverySection(
          id: 'for-you-watchlist',
          title: 'Inspired by Your Watchlist',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.personalised,
            mediaType: 'all',
            seedStrategy: 'watchlist',
          ),
          dedupGroup: 'personal',
        ),
        SeerrDiscoverySection(
          id: 'for-you-highly-rated-unseen',
          title: 'Highly Rated and Unseen',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.personalised,
            mediaType: 'all',
            seedStrategy: 'highly-rated-unseen',
          ),
          dedupGroup: 'personal',
        ),
        SeerrDiscoverySection(
          id: 'for-you-different',
          title: 'Something Different',
          subtitle: 'Strong picks outside your most-watched genres',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.personalised,
            mediaType: 'all',
            seedStrategy: 'novelty',
          ),
          dedupGroup: 'personal-novelty',
        ),
      ],
    ),
    SeerrDiscoveryTab(
      id: 'movies',
      title: 'Movies',
      sections: [
        SeerrDiscoverySection(
          id: 'movies-trending',
          title: 'Trending Movies',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.trending,
            mediaType: 'movie',
          ),
          dedupGroup: 'movies-main',
        ),
        SeerrDiscoverySection(
          id: 'movies-top-rated',
          title: 'Critically Acclaimed',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            sortBy: 'vote_average.desc',
            filters: {'voteCountGte': '1000', 'voteAverageGte': '7.5'},
          ),
          dedupGroup: 'movies-main',
        ),
        SeerrDiscoverySection(
          id: 'movies-hidden-gems',
          title: 'Hidden Gems',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            sortBy: 'vote_average.desc',
            filters: {
              'voteAverageGte': '7.0',
              'voteCountGte': '150',
              'voteCountLte': '1500',
            },
          ),
          dedupGroup: 'movies-deep',
        ),
        SeerrDiscoverySection(
          id: 'movies-short',
          title: 'Short and Brilliant',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            sortBy: 'vote_average.desc',
            filters: {
              'withRuntimeLte': '105',
              'voteAverageGte': '6.8',
              'voteCountGte': '150',
            },
          ),
          dedupGroup: 'movies-deep',
        ),
        SeerrDiscoverySection(
          id: 'movies-epics',
          title: 'Epic Movie Night',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            sortBy: 'vote_average.desc',
            filters: {
              'withRuntimeGte': '150',
              'voteAverageGte': '7.0',
              'voteCountGte': '500',
            },
          ),
          dedupGroup: 'movies-deep',
        ),
        SeerrDiscoverySection(
          id: 'movies-scifi-thrills',
          title: 'Science Fiction',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'genre': '878'},
          ),
          dedupGroup: 'movies-genres',
        ),
        SeerrDiscoverySection(
          id: 'movies-documentaries',
          title: 'Documentary Spotlight',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'genre': '99', 'voteCountGte': '30'},
          ),
          dedupGroup: 'movies-genres',
        ),
        SeerrDiscoverySection(
          id: 'movies-family',
          title: 'Family Movie Night',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'genre': '10751'},
          ),
          dedupGroup: 'movies-genres',
        ),
        SeerrDiscoverySection(
          id: 'movies-a24',
          title: 'A24',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'studio': '41077'},
          ),
          dedupGroup: 'movies-studios',
        ),
        SeerrDiscoverySection(
          id: 'movies-pixar',
          title: 'Pixar',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'studio': '3'},
          ),
          dedupGroup: 'movies-studios',
        ),
        SeerrDiscoverySection(
          id: 'movies-upcoming',
          title: 'Coming Soon',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.upcomingMovies,
            mediaType: 'movie',
          ),
          dedupGroup: 'movies-upcoming',
        ),
      ],
    ),
    SeerrDiscoveryTab(
      id: 'series',
      title: 'Series',
      sections: [
        SeerrDiscoverySection(
          id: 'series-trending',
          title: 'Trending Series',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.trending,
            mediaType: 'tv',
          ),
          dedupGroup: 'series-main',
        ),
        SeerrDiscoverySection(
          id: 'series-top-rated',
          title: 'Acclaimed Series',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            sortBy: 'vote_average.desc',
            filters: {'voteCountGte': '500', 'voteAverageGte': '7.5'},
          ),
          dedupGroup: 'series-main',
        ),
        SeerrDiscoverySection(
          id: 'series-crime-mystery',
          title: 'Crime and Mystery',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '80|9648'},
          ),
          dedupGroup: 'series-genres',
        ),
        SeerrDiscoverySection(
          id: 'series-comedy',
          title: 'Comedy Series',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '35'},
          ),
          dedupGroup: 'series-genres',
        ),
        SeerrDiscoverySection(
          id: 'series-documentary',
          title: 'Docuseries',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '99'},
          ),
          dedupGroup: 'series-genres',
        ),
        SeerrDiscoverySection(
          id: 'series-reality',
          title: 'Reality and Competition',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '10764'},
          ),
          dedupGroup: 'series-genres',
        ),
        SeerrDiscoverySection(
          id: 'series-upcoming',
          title: 'New and Returning Series',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.upcomingTv,
            mediaType: 'tv',
          ),
          dedupGroup: 'series-upcoming',
        ),
      ],
    ),
    SeerrDiscoveryTab(
      id: 'anime',
      title: 'Anime',
      sections: [
        SeerrDiscoverySection(
          id: 'anime-popular',
          title: 'Popular Anime',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16', 'language': 'ja'},
          ),
          dedupGroup: 'anime-main',
        ),
        SeerrDiscoverySection(
          id: 'anime-top-rated',
          title: 'Top Rated Anime',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            sortBy: 'vote_average.desc',
            filters: {
              'genre': '16',
              'language': 'ja',
              'voteCountGte': '100',
            },
          ),
          dedupGroup: 'anime-main',
        ),
        SeerrDiscoverySection(
          id: 'anime-action',
          title: 'Action-Packed Anime',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16,10759', 'language': 'ja'},
          ),
          dedupGroup: 'anime-genres',
        ),
        SeerrDiscoverySection(
          id: 'anime-fantasy',
          title: 'Fantasy Worlds',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16,10765', 'language': 'ja'},
          ),
          dedupGroup: 'anime-genres',
        ),
        SeerrDiscoverySection(
          id: 'anime-comedy',
          title: 'Comedy Anime',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16,35', 'language': 'ja'},
          ),
          dedupGroup: 'anime-genres',
        ),
        SeerrDiscoverySection(
          id: 'anime-drama',
          title: 'Drama and Romance',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16,18', 'language': 'ja'},
          ),
          dedupGroup: 'anime-genres',
        ),
        SeerrDiscoverySection(
          id: 'anime-mystery',
          title: 'Mystery and Supernatural',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverTv,
            mediaType: 'tv',
            filters: {'genre': '16,9648', 'language': 'ja'},
          ),
          dedupGroup: 'anime-genres',
        ),
        SeerrDiscoverySection(
          id: 'anime-movies',
          title: 'Anime Movies',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.discoverMovies,
            mediaType: 'movie',
            filters: {'genre': '16', 'language': 'ja'},
          ),
          dedupGroup: 'anime-movies',
        ),
      ],
    ),
    SeerrDiscoveryTab(
      id: 'new-upcoming',
      title: 'New & Upcoming',
      sections: [
        SeerrDiscoverySection(
          id: 'new-upcoming-movies',
          title: 'Upcoming Movies',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.upcomingMovies,
            mediaType: 'movie',
          ),
          dedupGroup: 'upcoming',
        ),
        SeerrDiscoverySection(
          id: 'new-upcoming-series',
          title: 'Upcoming Series',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.upcomingTv,
            mediaType: 'tv',
          ),
          dedupGroup: 'upcoming',
        ),
      ],
    ),
    SeerrDiscoveryTab(
      id: 'lists',
      title: 'Lists',
      sections: [
        SeerrDiscoverySection(
          id: 'lists-placeholder',
          title: 'Curated Lists',
          subtitle: 'MDBList, Letterboxd and Home Lab lists',
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.externalList,
            mediaType: 'all',
            listProvider: 'server',
            listId: 'curated',
          ),
          dedupGroup: 'lists',
        ),
      ],
    ),
  ],
);
