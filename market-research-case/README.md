# Market Research Case: when the brand gives you no data

A team case for a marketing case competition at UT Austin McCombs (Fall 2026). The client was a heritage Western-boot brand with more than a century of history. We received no internal data, no customer lists and no sales history, so we designed and fielded our own research and built the recommendation on it.

This folder shows the **methods**: the research design, the R code for every analysis, and the figures that carried the argument. The client, its competitors, the raw survey data and the final deck are not here (see *What is not here, and why* below).

## The question

How does a premium heritage brand grow beyond its core customer without discounting or diluting what makes it premium?

## Research design

Two original surveys, fielded in October 2026, both anonymous and screened for U.S. adults.

| Study | Who | Clean n | Built to answer |
|---|---|---|---|
| Fashion & Luxury Shopping Study (quantitative) | Luxury-capable shoppers, 18–45, household income $70K+, from a national panel plus campus and personal networks | 64 of 66 | Which features and prices win a boot choice; which motivations segment the market; which message works |
| Western Boots & Identity Survey (attitudes + qualitative) | Community and campus sample plus a matched national panel | 98 of 100 | Why people feel in or out of Western style: identity, gifting, budgets, brand familiarity |

Quality rules were set before fielding and applied unchanged: an embedded attention check removed 2 of 66 quantitative responses. A stricter screen (also dropping straight-liners and speeders, n = 59) reproduces every headline finding and ships as a robustness check. Randomization was checked (age × arm, p = .78) and no respondent could enter more than one study.

## Methods, in the order the argument uses them

| # | Method | Script | Figure | What it established |
|---|---|---|---|---|
| 1 | Aided brand-familiarity funnel + unaided recall | `script6_boots_identity.R` | — (brand-level, not published) | The problem was **reach, not appeal**: fewer than half of luxury-capable shoppers had heard of the client, yet it won the most choices when brands competed on equal footing |
| 2 | Attitude battery contrast (wearers vs. non-wearers) | `script6_boots_identity.R` | `03_identity_gap_wearers_vs_nonwearers.png` | The widest gap was “boots on me would feel like a costume”: **identity is the gate** |
| 3 | OLS driver regression (n = 64, R² = .59) | `script2_drivers.R` | `04_what_drives_interest_regression.png` | Already wearing Western style adds +1.7 points of interest (p < .001), being curious +1.5 (p = .005); age, gender, residence and luxury spend add nothing once identity is in the model |
| 4 | Choice-based conjoint, conditional logit (`survival::clogit`), WTP by delta method | `script3_conjoint.R` | `06_conjoint_attribute_importance.png` | 512 choice sets, 8 per respondent, 3 brands × style × leather × service × price ($395–$995) + “none”. Price p < .0001, hit rate 44% vs. 25% chance. A fitting appointment + lifetime resoling is worth **$304**; the everyday silhouette beats the classic tall shaft by $187; exotic leather adds only $55 (n.s.) |
| 5 | Factor analysis (3 factors, 55% of variance, α = .88) + k-means (k = 2 by silhouette, .33; 91% agreement with Ward) | `script4_segments.R` | `01_two_shopper_segments.png`, `02_segment_motivations_heatmap.png` | Two segments: **experience-led shoppers (70%)** and **craft traditionalists (30%)**. The shoppers most moved by craftsmanship-and-heritage language were the least likely to buy |
| 6 | Randomized between-subjects message A/B test | `script1_ab_test.R` | `05_message_ab_test.png` | Heritage vs. lifestyle copy: no significant difference (interest p = .19, fit p = .70; MDE d ≈ .71). Message explains nothing once identity is controlled |
| 7 | TURF (total unduplicated reach), all 120 three-lever bundles | `script5_turf.R` | `07_turf_best_bundle.png` | Fitting appointment + personalization + styling ideas reaches **89%** of the open market |
| 8 | Banded willingness-to-pay + conjoint price curve | `script3_conjoint.R`, `script6_boots_identity.R` | — (brand-level, not published) | Newcomers cap a first pair under $300; luxury-capable shoppers sustain $595–$895 when brand and service are present: a two-tier price architecture |

## The recommendation the research supported

Not a discount. A fit-first, personalized, styled entry experience aimed at experience-led shoppers, priced with the service premium shoppers already value, with the hand-made flagship line protected at full price. Lead with “people like you wear these”; let heritage close the sale in-store. Gifting as the front door: 36% got their most expensive pair as a gift or inheritance.

## Limitations, stated plainly

Samples are modest (64 + 98) and skew young and online; stated choices are not purchases; the A/B test is powered only for large effects; segments at this n are directional and validated by agreement between methods, not by test–retest.

## Reproducibility

Each script reads one sheet of a cleaned workbook (`data/survey_clean_data.xlsx`, not published) and writes its figure to `output/figs/`. Packages: `tidyverse`, `readxl`, `survival`, `cluster`, `broom`, `scales`. Brand names in the code are replaced by `BrandA` (the client), `BrandB`–`BrandF` (competitors) and `RetailerG`; everything else is as it ran.

## AI-use disclosure

AI (Claude) was used as an analytics engineer and tutor: drafting and debugging the R pipeline, turning the team’s question lists into survey instruments, generating figures and formatting documents. Every script was run by the team; every number was checked against the raw exports. No survey response, data point or recommendation was generated by AI.

## What is not here, and why

- **The client’s name and its competitors’ names.** The work was done for a case competition; the brand did not commission it and has not endorsed it. Brand-level results (awareness, brand premium) stay out of the public version.
- **Raw and cleaned survey data.** Respondent-level data from the panels and from personal networks is not published, to protect respondents.
- **The deck and the financial model.** Team deliverables for the competition, shared with the judges only.
- **Brand assets.** Chart colors in the code are plain hex values; no brand guideline material is included.

Team project; methods and code by the research team. Maintained by María Serrano, MS in Marketing, UT Austin McCombs.
