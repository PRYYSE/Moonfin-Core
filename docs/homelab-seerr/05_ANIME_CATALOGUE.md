# 05 - Anime Discovery Catalogue

## Target

Anime must be a first-class discovery product, not one `Animation + Japanese` query repeated under different titles.

The first full catalogue should contain **120+ Anime discovery routes**, combining:

- broad TMDb/Seerr filters;
- moving seasonal/date windows;
- exact keyword/tag resolution;
- Movie and TV Anime;
- rating/popularity/vote-count lenses;
- runtime/era lenses;
- server-curated/external lists where TMDb taxonomy is insufficient;
- explicit-content safety rules.

A normal Anime session should show around 20-26 lanes chosen from this larger pool.

## Base Anime classification

### Series baseline

Use multiple signals rather than a single test:

- TV `genre=16` (Animation);
- original language `ja` for the main Japanese Anime corpus;
- keyword/tag evidence when a lane is theme-specific;
- allow server-curated/external-list sources to bring in titles whose TMDb language/genre metadata is imperfect;
- do not assume all Japanese TV is Anime;
- do not assume all Animation is Anime.

### Movie baseline

- Movie `genre=16` + `language=ja` for broad Japanese Anime films;
- curated studio/list data can supplement titles with imperfect metadata.

### Global animation

Chinese animation/donghua and other non-Japanese animation can have their own clearly labelled lanes rather than silently broadening every Anime row.

## A. Anchor/current lanes - 12

1. Popular Anime.
2. Top Rated Anime.
3. Trending Anime - derive from current discover/trending sources then keep Anime-classified items.
4. New This Season.
5. Fresh This Month.
6. Recent Seasonal Hits.
7. Upcoming Anime.
8. Fresh Discoveries.
9. Hidden Anime Gems.
10. Anime Movies.
11. Anime Classics.
12. Highly Rated and Unseen Anime - user-aware overlay.

## B. Seasonal/time lanes - 16

13. Current Season Anime - moving quarter/season dates.
14. Previous Season Highlights.
15. Last 6 Months.
16. Last 12 Months.
17. New Anime Movies.
18. Upcoming Anime Movies.
19. 2020s Anime Standouts.
20. Best of the 2010s.
21. Best of the 2000s.
22. '90s Anime.
23. '80s Anime.
24. '70s Anime.
25. Classic Anime Before 1970 - low-priority archival pool.
26. Recent Hidden Gems - last 3 years + low/moderate vote band.
27. New & Highly Rated - recent window + rating floor.
28. Recent Long-Running Hits - detail-enriched/generated lane.

Season windows should be date-token driven. Never bake a fixed year into a permanent row definition.

## C. Rating/discovery lenses - 12

29. Acclaimed Anime - high rating + meaningful votes.
30. Fan Favourites - higher vote count + strong rating.
31. Underseen Greats - strong rating + lower vote band.
32. Deep-Cut Anime - lower popularity/votes but viable rating.
33. Modern Anime Classics - 2000-present + strong rating.
34. Recent Breakouts - recent + rising popularity.
35. One to Watch - moderate votes, strong recent rating.
36. Popular but Not in Your Library - local ownership overlay.
37. Top Rated Anime Movies.
38. Hidden Anime Movies.
39. Acclaimed Older Anime.
40. Something Different - personal novelty engine.

## D. Direct genre/mix lanes - 20

TV IDs: Animation 16, Action & Adventure 10759, Comedy 35, Drama 18, Family 10751, Kids 10762, Mystery 9648, Sci-Fi & Fantasy 10765, War & Politics 10768.

41. Action-Packed Anime - 16 + 10759 + ja.
42. Adventure Anime - 16 + 10759 + adventure keyword refinement.
43. Comedy Anime - 16 + 35 + ja.
44. Drama Anime - 16 + 18 + ja.
45. Mystery Anime - 16 + 9648 + ja.
46. Sci-Fi Anime - 16 + 10765 + sci-fi keyword refinement.
47. Fantasy Anime - 16 + 10765 + fantasy/magic keyword refinement.
48. Family-Friendly Anime - 16 + 10751 + ja.
49. Kids Anime - 16 + 10762 + ja, lower priority.
50. War & Politics Anime - 16 + 10768 + ja.
51. Action Comedy Anime - 16 + 10759 + 35 + ja.
52. Action Drama Anime - 16 + 10759 + 18 + ja.
53. Mystery Drama Anime - 16 + 9648 + 18 + ja.
54. Sci-Fi Action Anime - 16 + 10765 + 10759 + ja.
55. Fantasy Adventure Anime - 16 + 10765 + 10759 + ja with fantasy refinement.
56. Comedy Drama Anime - 16 + 35 + 18 + ja.
57. Dark Mystery Anime - Mystery/Drama + dark/supernatural keyword pool.
58. Family Adventure Anime - Family + Action/Adventure + ja.
59. Historical Anime - Animation + historical/period keywords.
60. Music Anime - Animation + music keyword pool.

## E. Theme/tag lanes - 50 initial routes

TMDb's high-level TV genre list cannot express Anime subgenres well. These lanes should therefore author **human-readable keyword names**, resolve exact TMDb keyword IDs through Seerr's keyword search endpoint, cache those resolutions server-side and hide a lane if its exact tag cannot be resolved reliably.

61. Isekai.
62. Reincarnation.
63. Another World.
64. Magic.
65. Supernatural.
66. Demons.
67. Vampires.
68. Yokai / Spirits.
69. Ghost Stories.
70. Mecha.
71. Giant Robots.
72. Cyberpunk.
73. Post-Apocalyptic.
74. Dystopian.
75. Space Opera.
76. Space Travel.
77. Aliens.
78. Time Travel.
79. Parallel Worlds.
80. Virtual Reality.
81. Video Games.
82. Artificial Intelligence.
83. School Life.
84. High School.
85. Coming of Age.
86. Slice of Life.
87. Romance.
88. Romantic Comedy.
89. Love Triangle.
90. Sports.
91. Martial Arts.
92. Samurai.
93. Ninja.
94. Sword Fighting.
95. Tournament.
96. Superpowers.
97. Superheroes.
98. Mystery & Detective.
99. Psychological.
100. Thriller.
101. Survival.
102. Death Game.
103. Cooking & Food.
104. Music & Bands.
105. Idols.
106. Workplace.
107. Family.
108. Friendship.
109. Based on Manga.
110. Based on Light Novel.

### Keyword resolution rules

- exact-normalised name match first;
- optionally maintain a small server-side alias table (`isekai` -> exact TMDb tag result, etc.);
- never blindly choose the first fuzzy search result;
- cache successful keyword IDs for a long TTL;
- cache unresolved keywords briefly;
- a failed optional tag lane disappears for that session instead of generating broad unrelated search results.

## F. Format/runtime lanes - 12

111. Short-Form Anime - runtime <= 15 minutes.
112. Standard Episodes - runtime roughly 20-30 minutes.
113. Longer Episodes - runtime >= 35 minutes.
114. Quick Anime Movie - Movie runtime <= 100.
115. Epic Anime Movie - Movie runtime >= 120 + rating floor.
116. Anime Specials / TV Movies - server/list-derived where classification is reliable.
117. One-Season Anime - detail-enriched generated lane.
118. Long-Running Anime - detail-enriched generated lane.
119. Bingeable Anime - generated from episode/season counts and user context.
120. Completed Anime - status-aware if upstream semantics are validated.
121. Continuing Anime - status-aware if upstream semantics are validated.
122. Anime Miniseries / Short Runs - detail-enriched generated lane.

## G. Studio/creator/collection lanes

TMDb production company data for Anime is not always equivalent to the animation studio users care about, so this area should favour dynamic search/curated data rather than a large hardcoded studio-ID table.

Initial desired lanes include:

123. Studio Ghibli Films.
124. Kyoto Animation Spotlight.
125. MAPPA Spotlight.
126. ufotable Spotlight.
127. Bones Spotlight.
128. Madhouse Spotlight.
129. Production I.G Spotlight.
130. Trigger Spotlight.
131. Wit Studio Spotlight.
132. Sunrise Spotlight.

**Implementation rule:** validate whether TMDb company metadata yields a clean result before enabling any studio lane as a raw `studio=` filter. If not, source it through a curated external list or resolved search rather than publishing misleading results.

## H. Global/non-Japanese animation lanes - optional separate pool

133. Donghua / Chinese Animation - Animation + `language=zh`, clearly labelled.
134. Korean Animation - Animation + `language=ko`, clearly labelled.
135. International Anime-Influenced Animation - curated list, not automatically called Japanese Anime.

These should not replace or dilute the main Japanese Anime anchors.

## I. Personal Anime lanes

Generated separately from the static catalogue:

136. Because You Watched <anime>.
137. More Like Your Favourite Anime.
138. Inspired by Your Anime Watchlist.
139. More Action Anime for You.
140. More Fantasy Anime for You.
141. More Romance/Drama Anime for You.
142. Anime Outside Your Usual Genres.
143. Highly Rated Anime You Missed.
144. Similar to Anime You Rated Highly.
145. Recent Anime Based on Your Taste.
146. Older Anime Based on Your Taste.
147. Anime Movies Based on Your Taste.
148. Short Anime Based on Your Taste.

## J. External/curated Anime lanes

External list integration is especially valuable where TMDb tags are weak. Candidate server-curated categories:

149. Seasonal Staff Picks.
150. Essential Anime Starter Pack.
151. Modern Anime Essentials.
152. Classic Anime Essentials.
153. Best Anime Movies.
154. Best Sports Anime.
155. Best Mecha Anime.
156. Best Romance Anime.
157. Best Psychological Anime.
158. Best Sci-Fi Anime.
159. Best Fantasy Anime.
160. Best Comedy Anime.

These can be maintained as MDBList/TMDb/other supported server lists and updated without app rebuilds.

## Initial catalogue size

This document defines **160 Anime routes/lanes** before arbitrary user/external lists are counted.

A normal Anime session must not show 160 rows. It should show anchors plus a rotating mix of genre/theme/era/studio/list/personal lanes, with a deliberate Crunchyroll-like browsing density and a clear way to open category indexes.

## Explicit-content safety

Preserve the existing Home Lab policy:

- ordinary Anime catalogue should be broad;
- adult-adjacent titles are not automatically forbidden;
- obvious hentai/pornographic content must not dominate normal discovery;
- explicit block patterns remain intentionally narrow, including hentai, pornography/pornographic, XXX, sexually explicit, adult animation, eroge, futanari and tentacle sex;
- apply the explicit filter to previews and expanded normal-Anime surfaces;
- never fail the whole Anime tab because some candidates are rejected;
- user/server blocklists remain authoritative.

## Anime-specific dedup

Anime metadata often causes the same franchise to dominate several lanes. Dedup should therefore consider both:

- exact TMDb media ID; and
- optional franchise/title-normalisation grouping for previews (e.g. multiple seasons/editions of the same title), without hiding valid results in the expanded collection.

Franchise-level dedup must be conservative because unrelated titles can share similar names.

## Validation requirements

1. Test at least several independent seeds/pages per lane family, not only one top page.
2. Confirm Anime classification rather than trusting labels.
3. Measure explicit-content rejects without treating a few rejects as total failure.
4. Validate keyword exact-match resolution.
5. Validate moving season windows at year boundaries.
6. Confirm Movie Anime remains Movie and TV Anime remains TV.
7. Ensure normal Series destination is not fed these Anime-specific pools.
8. Preview and expanded query identity must match.
