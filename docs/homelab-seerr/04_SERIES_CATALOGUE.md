# 04 - Series Discovery Catalogue

## Target

The first full Series catalogue should contain **100+ useful discovery routes**, with roughly 18-24 selected for a normal Series session. Anime-specific rows remain in the Anime destination and should not dominate normal TV discovery.

Standard TV genre IDs used below:

- Action & Adventure 10759
- Animation 16
- Comedy 35
- Crime 80
- Documentary 99
- Drama 18
- Family 10751
- Kids 10762
- Mystery 9648
- News 10763
- Reality 10764
- Sci-Fi & Fantasy 10765
- Soap 10766
- Talk 10767
- War & Politics 10768
- Western 37

For normal Series lanes, Animation can be excluded or down-weighted where the row would otherwise become Anime-heavy. Do not globally remove Animation from all TV because Western animation is legitimate TV content.

## A. Anchor/current lanes - 10

1. Trending Series.
2. Popular Series.
3. Acclaimed Series - high rating/vote floor.
4. New & Returning Series - rolling first-air window/current discovery.
5. Fresh Premieres - first air within roughly 90 days.
6. Upcoming Series - future first-air dates.
7. Binge-Worthy - high-rated Drama/Crime/Comedy/Sci-Fi pool; later enrich with episode-count/runtime data where available.
8. Limited-Series Spotlight - server composition using Seerr/TMDb detail metadata; hide if reliable classification is unavailable.
9. Recently Added Series - local/Jellyfin overlay.
10. Continue Exploring Series - recent Seerr/detail contexts, not playback Continue Watching.

## B. Rating/discovery lanes - 10

11. Hidden Series Gems - high rating, moderate/low vote count.
12. Underseen Greats - stronger rating, lower vote band.
13. Crowd Favourites - very high vote count + solid rating.
14. Critics' Picks - rating >= 8 with meaningful votes.
15. Great but Not Obvious - rating >= 7.3, moderate votes.
16. Modern TV Classics - 2000-present, strong rating/votes.
17. Recent Breakouts - last 24 months + rising popularity/rating.
18. One-Season Wonders - requires detail-derived season count, optional generated lane.
19. Long-Running Favourites - requires detail-derived season count, generated lane.
20. Worth Catching Up On - complete/older acclaimed shows, status-aware when reliable.

## C. Episode/runtime style lanes - 8

21. Half-Hour Comedy - Comedy + runtime <= 35.
22. Short Episodes - runtime <= 30, exclude Kids/Animation when normal Series context demands it.
23. Easy 45-Minute Watch - runtime 35-50.
24. Hour-Long Drama - Drama + runtime 45-70.
25. Long-Form Drama - runtime >= 60 + Drama.
26. Quick Crime Fix - Crime + runtime <= 45.
27. Quick Reality Watch - Reality + runtime <= 50.
28. Weekend Binge - generated from season/episode count where detail enrichment allows it.

## D. Eras - 8

29. 2020s Standouts.
30. Best of the 2010s.
31. Best of the 2000s.
32. '90s TV Favourites.
33. '80s Television.
34. '70s Television.
35. Classic TV 1950s-1960s.
36. Vintage Television - pre-1950, low-priority archival lane.

## E. Primary genre lanes - 16

37. Action & Adventure.
38. Comedy.
39. Crime.
40. Documentary.
41. Drama.
42. Family.
43. Mystery.
44. Reality.
45. Sci-Fi & Fantasy.
46. War & Politics.
47. Western.
48. Animation - Western/general animation lane, kept separate from Anime.
49. Kids.
50. Soap.
51. Talk.
52. News / Current Affairs - low priority and region-sensitive.

## F. Genre-combination lanes - 16

53. Crime & Mystery - 80 + 9648 or a controlled OR/AND variant depending desired breadth.
54. Crime Drama - 80 + 18.
55. Mystery Drama - 9648 + 18.
56. Sci-Fi Drama - 10765 + 18.
57. Fantasy Drama - 10765 + 18 with fantasy keyword resolver where needed.
58. Action Drama - 10759 + 18.
59. Action Comedy - 10759 + 35.
60. Comedy Drama - 35 + 18.
61. Family Comedy - 10751 + 35.
62. Political Drama - 10768 + 18.
63. War Drama - 10768 + 18.
64. Western Drama - 37 + 18.
65. Documentary Crime - 99 + 80.
66. Reality Competition - Reality + keyword resolver `competition`.
67. Mystery Sci-Fi - 9648 + 10765.
68. Adventure Fantasy - 10759 + 10765.

## G. Theme/keyword lanes - initial 18

Use readable keyword names in Home Lab config, resolved/cached server-side.

69. Time Travel.
70. Space & Deep Space.
71. Dystopian Futures.
72. Post-Apocalyptic Series.
73. Artificial Intelligence.
74. Robots & Androids.
75. Superheroes.
76. Serial Killers.
77. Detectives & Investigations.
78. Legal Drama.
79. Medical Drama.
80. Workplace Comedy.
81. Coming of Age.
82. High School / Teen Drama.
83. Survival.
84. Based on True Events.
85. Espionage & Spies.
86. Supernatural Mysteries.

## H. Network/service-origin lanes - 22 confirmed current Moonfin IDs

87. Netflix - network 213.
88. Disney+ - 2739.
89. Prime Video - 1024.
90. Apple TV+ - 2552.
91. Hulu - 453.
92. HBO - 49.
93. Discovery+ - 4353.
94. ABC - 2.
95. FOX - 19.
96. Cinemax - 359.
97. AMC - 174.
98. Showtime - 67.
99. Starz - 318.
100. The CW - 71.
101. NBC - 6.
102. CBS - 16.
103. Paramount+ - 4330.
104. BBC One - 4.
105. Cartoon Network - 56.
106. Adult Swim - 80.
107. Nickelodeon - 13.
108. Peacock - 3353.

These IDs are already present in current Moonfin Seerr discovery code. Keep them as a known initial network pool; future server-delivered config can add/remove networks without client releases.

## I. International/original-language lanes - 10

109. Korean Series - `language=ko`.
110. Japanese Live-Action Series - `language=ja`, exclude/down-weight Animation.
111. French Series - `language=fr`.
112. Spanish-Language Series - `language=es`.
113. Hindi Series - `language=hi`.
114. Chinese-Language Series - `language=zh`.
115. German-Language Series - `language=de`.
116. Scandinavian Series - rotating `sv`, `no`, `da` sub-pool.
117. International Crime - Crime + rotating non-English language.
118. International Drama - Drama + rotating non-English language.

## J. Australian provider lenses - dynamic IDs

Resolve AU providers from the server and build optional rotating provider lanes such as:

119. Netflix Series.
120. Prime Video Series.
121. Disney+ Series.
122. Apple TV+ Series.
123. BINGE Series.
124. Stan Series.
125. Paramount+ Series.
126. SBS On Demand Series.
127. ABC iview Series.
128. Shudder Series where TV inventory exists.

Provider lanes describe external availability metadata only. They do not change Jellyfin playback ownership.

## K. Occasion/discovery mixes - 12

129. Friday Night Binge - high-popularity Drama/Crime/Comedy blend.
130. Easy Background Comedy - Comedy + shorter runtime, later personalised.
131. Edge-of-Your-Seat - Crime/Mystery/Action mix.
132. Big Sci-Fi Night - Sci-Fi & Fantasy + rating floor.
133. Family Series Night - Family + Comedy/Adventure mix.
134. Documentary Weekend - top Documentary.
135. Reality Competition Night - Reality + competition keyword.
136. Prestige Drama - Drama, strong rating/votes, recent decades.
137. Comfort Rewatch Candidates - personalised/local, not static Seerr.
138. Dark & Twisty - Mystery/Crime/Drama + selected keywords.
139. Light & Funny - Comedy + rating/popularity floor.
140. Something Completely Different - novelty/personalisation engine.

## Initial catalogue size

The plan defines **140 Series routes/lanes**, before dynamic external lists or user-derived rows.

The normal Series landing page should display only a well-balanced session subset. Network, genre, international and provider pools rotate. The user can explicitly open those category collections if they want the full list of lanes.

## Anime isolation rule

Normal Series session composition should:

- not select Anime-specific keyword/language+Animation lanes;
- avoid several Animation-heavy rows at once;
- allow one general Animation/Adult Swim/Cartoon Network lane when selected;
- keep Japanese live-action discovery separate from Anime by excluding/down-weighting Animation for that row;
- never treat all Japanese TV as Anime.

## Generated personal Series lanes

- Because You Watched <series>
- More Like Your Favourite Series
- More From a Favourite Network
- Highly Rated Series You Missed
- Short Episodes Based on Your Taste
- Another Crime/Mystery Pick for You
- Something Outside Your Normal Genres
- Similar to a Recently Highly Rated Series
- From Actors/Creators You Keep Watching (later detail-person affinity)

## Validation requirements

- each lane returns Series, not Movie;
- Anime contamination is measured for normal-TV lanes;
- provider/network title accurately represents query semantics;
- moving dates do not age out;
- runtime filters behave with TV metadata limitations;
- shallow optional lanes are hidden instead of blocking the tab;
- preview/expanded query identity matches;
- D-pad clients do not mount all 140 lanes simultaneously.
