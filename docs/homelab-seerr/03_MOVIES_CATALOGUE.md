# 03 - Movies Discovery Catalogue

## Target

The first full Movie catalogue should contain **at least 80 useful lane definitions**, with roughly 18-24 selected for a normal session. Every deterministic lane is expandable into the full paginated result set.

This replaces the first-pass assumption that ~11 Movie lanes were enough for Seerr Discovery. The existing nine Moonbase Movie destination rows remain separate and unchanged.

## Filter conventions

Current Seerr forwards TMDb discovery syntax. Use:

- comma-separated genres when all are desired (AND-style combination);
- pipe-separated genres for alternatives (OR-style grouping) where supported;
- moving date tokens in Home Lab config, resolved before Seerr receives the query;
- keyword **names** in catalogue authoring where possible, resolved/cached to TMDb keyword IDs server-side rather than hand-maintaining opaque IDs;
- provider IDs resolved for Australia (`AU`) rather than assuming US provider IDs/availability.

Standard Movie genre IDs used below:

- Action 28
- Adventure 12
- Animation 16
- Comedy 35
- Crime 80
- Documentary 99
- Drama 18
- Family 10751
- Fantasy 14
- History 36
- Horror 27
- Music 10402
- Mystery 9648
- Romance 10749
- Science Fiction 878
- TV Movie 10770
- Thriller 53
- War 10752
- Western 37

## A. Anchor/current lanes - 10

1. Trending Movies - mixed trending filtered to Movie.
2. Popular Movies - `sortBy=popularity.desc`.
3. Critically Acclaimed - rating >= 7.5, votes >= 1000, rating descending.
4. Audience Favourites - rating >= 7.0, votes >= 5000, popularity/rating blend.
5. New Releases - release date within roughly the last 6 months.
6. Fresh This Month - release date from `$monthsAgo:1` through `$today`.
7. In Cinemas / Current Releases - rolling recent/current release window, region-aware when practical.
8. Coming Soon - release >= `$today`.
9. Highly Anticipated - upcoming + higher vote/popularity threshold.
10. Recently Added to Your Library - local/Jellyfin overlay lane; not a Seerr-only query.

## B. Discovery/rating lanes - 10

11. Hidden Gems - rating >= 7.0, votes 150-1500.
12. Deep Cuts - rating >= 6.8, votes 50-500.
13. Underseen Masterpieces - rating >= 7.8, votes 100-1000.
14. Crowd-Pleasing Picks - votes >= 10000, rating >= 6.8.
15. Critics' Corner - rating >= 8.0, votes >= 1000.
16. Great but Not Obvious - rating >= 7.2, votes 500-3000.
17. Polarising Movies - later enrichment lane using rating-source disagreement if MDBList data is available; not a raw Seerr filter.
18. Modern Classics - 2000-present, rating >= 7.5, votes >= 3000.
19. Cult Favourites - keyword resolver (`cult film`) plus minimum vote threshold.
20. One to Watch - recent 24 months, medium vote count, strong rating.

## C. Runtime lanes - 8

21. Under 90 Minutes - runtime <= 90, rating >= 6.0.
22. Short and Brilliant - runtime <= 105, rating >= 6.8, votes >= 150.
23. Easy Two-Hour Watch - runtime 90-125.
24. Long but Worth It - runtime 125-160, rating >= 7.0.
25. Epic Movie Night - runtime >= 150, rating >= 7.0, votes >= 500.
26. Three-Hour Epics - runtime >= 175, rating >= 7.0.
27. Quick Comedy - Comedy + runtime <= 100.
28. Quick Thriller - Thriller + runtime <= 105.

## D. Eras - 8

29. 2020s Standouts - 2020 through current date, rating/vote floor.
30. Best of the 2010s - 2010-2019.
31. Best of the 2000s - 2000-2009.
32. '90s Essentials - 1990-1999.
33. '80s Favourites - 1980-1989.
34. '70s Cinema - 1970-1979.
35. Mid-Century Classics - 1940-1969.
36. Early Cinema - before 1940, meaningful vote floor.

## E. Primary genre lanes - 19

37. Action.
38. Adventure.
39. Animation.
40. Comedy.
41. Crime.
42. Documentary.
43. Drama.
44. Family.
45. Fantasy.
46. History.
47. Horror.
48. Music & Musicals.
49. Mystery.
50. Romance.
51. Science Fiction.
52. Thriller.
53. War.
54. Western.
55. TV Movies - lower priority rotating lane.

Genre-only lanes should usually apply a modest popularity/vote floor so obscure metadata noise does not dominate the preview. The expanded screen can loosen that floor if the user explicitly chooses broader discovery controls.

## F. Genre-combination lanes - 16

56. Action Comedy - 28 + 35.
57. Action Thriller - 28 + 53.
58. Action Adventure - 28 + 12.
59. Sci-Fi Thriller - 878 + 53.
60. Sci-Fi Adventure - 878 + 12.
61. Sci-Fi Horror - 878 + 27.
62. Horror Comedy - 27 + 35.
63. Psychological Mystery - 9648 + 53 plus keyword resolver `psychological` where viable.
64. Crime Thriller - 80 + 53.
65. Crime Drama - 80 + 18.
66. Romantic Comedy - 10749 + 35.
67. Romantic Drama - 10749 + 18.
68. Fantasy Adventure - 14 + 12.
69. Family Animation - 10751 + 16.
70. Historical Drama - 36 + 18.
71. War Drama - 10752 + 18.

## G. Theme/keyword rabbit-hole lanes - initial 16

These should use the Home Lab keyword-name resolver so the catalogue remains readable and IDs can be cached/resolved centrally.

72. Space & Deep Space - keyword names such as `space`, `outer space`.
73. Time Travel.
74. Superheroes.
75. Post-Apocalyptic.
76. Dystopian Futures.
77. Cyberpunk.
78. Artificial Intelligence.
79. Robots & Androids.
80. Aliens & First Contact.
81. Heist Movies.
82. Serial Killers.
83. Survival Stories.
84. Based on a True Story.
85. Coming of Age.
86. Road Movies.
87. Martial Arts.

Keyword lanes require exact-result validation. If an exact keyword cannot be resolved or produces too little useful content, hide the optional lane for that session rather than broad text-searching into unrelated results.

## H. Studio lanes - 11 confirmed current IDs

88. Disney - studio 2.
89. 20th Century Studios - 127928.
90. Sony Pictures - 34.
91. Warner Bros. Pictures - 174.
92. Universal - 33.
93. Paramount - 4.
94. Pixar - 3.
95. DreamWorks - 521.
96. Marvel Studios - 420.
97. DC - 9993.
98. A24 - 41077.

These IDs already exist in current Moonfin's Seerr studio list and therefore do not need a new lookup system for v1.

## I. International/original-language lanes - 10

99. Korean Cinema - `language=ko`.
100. Japanese Cinema - `language=ja`, without forcing Animation.
101. French Cinema - `language=fr`.
102. Spanish-Language Cinema - `language=es`.
103. Hindi Cinema - `language=hi`.
104. Chinese-Language Cinema - `language=zh`.
105. Italian Cinema - `language=it`.
106. German-Language Cinema - `language=de`.
107. Scandinavian Picks - rotating `sv`, `no`, `da` lanes or combined server composition.
108. International Acclaim - rotate non-English language pools with rating/vote floor.

The Seerr `language` parameter is being used as original-language filtering, matching current Moonfin's existing comment/behaviour. UI labels must make this clear.

## J. Provider lanes - dynamic Australian IDs

Provider availability should be resolved from Seerr/TMDb for region `AU` and stored as server config. Initial provider pool should include, where available:

109. Netflix Movies.
110. Prime Video Movies.
111. Disney+ Movies.
112. Apple TV+ Movies.
113. BINGE Movies.
114. Stan Movies.
115. Paramount+ Movies.
116. Shudder Movies.
117. SBS On Demand Movies.
118. ABC iview Movies/Films where provider data is meaningful.

Do not hardcode US availability or assume a provider exists in AU. These are rotating discovery lenses, not statements that Moonfin can play those services.

## K. Occasion/seasonal lanes - 12

119. Friday Night Popcorn - high-popularity Action/Comedy/Adventure mix.
120. Family Weekend - Family/Animation/Adventure with runtime cap.
121. Date Night - Romance/Comedy/Drama, rating floor.
122. Late-Night Thrillers - Thriller/Mystery/Crime.
123. Horror Night - Horror with rating/vote floor.
124. Halloween Rotation - Horror + relevant keyword pool, seasonally boosted in October.
125. Christmas Movies - keyword resolver, seasonally boosted November-December.
126. Summer Blockbusters - Action/Adventure/Sci-Fi, high popularity.
127. Rainy-Day Comfort Movies - Comedy/Family/Romance; personalised later.
128. Documentary Night - high-rated Documentary.
129. Awards Season - external curated list/keyword/event data where available.
130. Festival & Indie Spotlight - A24 plus rotating lower-vote critically rated independent films.

## Initial catalogue size

The plan above defines **130 Movie discovery routes/lanes** before external lists generate additional dynamic entries.

Not all 130 should appear simultaneously. The session composer should normally surface 18-24, preserve anchors, rotate the rest by pool and avoid adjacent near-duplicates.

## Personal Movie lanes generated separately

The following are not static catalogue definitions and should be generated by the personalisation engine:

- Because You Watched <movie>
- More From <director/person> after a detail visit
- More Like Your Favourites
- Inspired by Your Watchlist
- Unwatched From Genres You Love
- Something Different From Your Usual Picks
- Highly Rated Movies You Missed
- Rediscover a Favourite Era
- Similar to Recently Rated Highly
- Short Picks Based on Your Taste

## Validation requirements

For each static/dynamic Movie lane before enabling it server-side:

- query parses through the allow-list;
- first pages return enough valid Movie items;
- title is not misleading relative to actual filter semantics;
- no accidental Anime-only contamination unless intended;
- no adult-content dominance;
- preview/expanded query keys match;
- optional empty/shallow lane can fail independently;
- provider lanes are checked with Australian region semantics.
