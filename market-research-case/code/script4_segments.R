# ============================================================
# Script 4 - Segmentation: factor analysis + k-means clusters
# Open the project via "market-research-case.Rproj", run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Luxury_Study" (n = 64)
# ============================================================
library(tidyverse)
library(readxl)
library(cluster)

q <- read_excel("data/survey_clean_data.xlsx", sheet = "Luxury_Study")

# Design constants (shared look)
FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; steel <- "#50606B"; gray <- "#9FA0A2"; pop <- "#857650"

# --- 1. The segmentation base: 12 motivation items (1-7) -----------------------
items <- q |> select(starts_with("motiv_"))
X <- items |> drop_na()
Z <- scale(X)                               # z-scores: every item weighs the same

# Reliability: do the items hang together? (Cronbach's alpha, ~.88 = very good)
k <- ncol(X); (k/(k-1)) * (1 - sum(apply(X, 2, var)) / var(rowSums(X)))

# --- 2. Factor analysis: compress 12 items into 2 dimensions -------------------
fa <- factanal(X, factors = 2, rotation = "promax", scores = "regression")
print(fa$loadings, cutoff = .4)             # which items define each factor
scores <- as_tibble(fa$scores)              # each person's position on the 2 factors

# --- 3. How many clusters? Silhouette score for k = 2..5 ------------------------
D <- dist(Z)
sapply(2:5, function(k) mean(silhouette(kmeans(Z, k, nstart = 50)$cluster, D)[, 3]))
# k = 2 is the clear winner (~.33 vs ~.18)

# --- 4. Final clusters + stability check ----------------------------------------
set.seed(2026)
km <- kmeans(Z, 2, nstart = 100)
table(km$cluster, cutree(hclust(D, method = "ward.D2"), 2))   # Ward agrees

seg_names <- c("Experience-led shoppers", "Craft traditionalists")
if (mean(rowMeans(X)[km$cluster == 1]) < mean(rowMeans(X)[km$cluster == 2])) seg_names <- rev(seg_names)
cl <- tibble(scores, segment = seg_names[km$cluster])
shares <- cl |> count(segment) |> mutate(p = n / sum(n))

# --- 5. THE cluster map: every shopper in motivation space ----------------------
# Plotted on the two principal components of the same 12 z-scored items the
# clusters were built on, so the separation k-means found is visible (the
# standard cluster plot). PC1 = overall motivation strength; PC2 = craft focus.
pc <- prcomp(Z)
cl <- cl |> mutate(PC1 = pc$x[, 1], PC2 = pc$x[, 2])
cents <- cl |> group_by(segment) |> summarise(F1 = mean(PC1), F2 = mean(PC2), .groups = "drop") |>
  left_join(shares, by = "segment") |>
  mutate(lab = sprintf("%s\n%d%% of shoppers", segment, round(100 * p)))

ggplot(cl, aes(PC1, PC2, colour = segment, fill = segment)) +
  stat_ellipse(geom = "polygon", type = "norm", level = .82, alpha = .10, colour = NA) +
  stat_ellipse(type = "norm", level = .82, linewidth = .5, linetype = "22") +
  geom_point(size = 2.9, alpha = .85) +
  geom_point(data = cents, aes(F1, F2), size = 5.5, shape = 18, colour = ink, show.legend = FALSE) +
  geom_label(data = cents, aes(F1, F2, label = lab), nudge_y = 1.05, size = 3.8,
             fontface = "bold", colour = "white", label.size = 0, label.padding = unit(.45, "lines"),
             label.r = unit(.35, "lines"), show.legend = FALSE) +
  scale_colour_manual(values = setNames(c(pop, navy), seg_names), guide = "none") +
  scale_fill_manual(values = setNames(c(pop, navy), seg_names), guide = "none") +
  scale_x_continuous(breaks = seq(-6, 4, 2)) +
  labs(title = "Two tribes in the luxury market",
       subtitle = "Each dot is one shopper, placed by their answers to 12 luxury-motivation questions.\nK-means clustering finds two groups; the diamonds mark each group's center.",
       x = "Luxury motivation overall (weak \u2192 strong)",
       y = "What moves them: community & status (low) \u2192 craftsmanship (high)",
       caption = "K-means (k = 2, silhouette = .33), Ward clustering agrees | axes: first two principal components of the 12 items | ellipses ~80% of each group | Fashion & Luxury Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 14)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.title = element_text(colour = ink2, size = 10),
        axis.text = element_text(colour = ink3, size = 9),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#F1F1F2", linewidth = .4),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_cluster_map.png", width = 9.4, height = 6.4, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_cluster_map.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 5.45, dpi = 300, bg = "white")


# --- 6. Who are they? Profile the segments on behavior ---------------------------
qX <- q |> filter(complete.cases(items)) |> mutate(segment = seg_names[km$cluster])
qX |> group_by(segment) |>
  summarise(n = n(),
            open_to_western   = mean(western_open),
            bought_luxury_2yr = mean(luxury_buyer),
            chose_brand_a    = mean(brand_a_take_rate, na.rm = TRUE),
            interest          = mean(interest_1to7, na.rm = TRUE))
# The punchline: the craft-minded segment is the LEAST likely to buy.
# The experience-led 68% is open to Western (88%), buys luxury (92%)
# and picks BrandA in 40% of its conjoint choices.

# --- 7. Theme heatmap: what each tribe cares about --------------------------------
THEMES <- list(Craftsmanship = c("motiv_craft_pay_more", "motiv_craft_one_good_item"),
               Heritage = c("motiv_heritage_history", "motiv_heritage_where_made"),
               `Self-expression` = c("motiv_express_who_i_am", "motiv_express_stand_out"),
               Exclusivity = c("motiv_exclusive_limited", "motiv_exclusive_collect"),
               Community = c("motiv_community_events", "motiv_community_experiences"),
               Status = c("motiv_status_signal", "motiv_status_notice_brands"))
heat <- imap_dfr(THEMES, function(cols, th)
  qX |> group_by(segment) |> summarise(mean = mean(rowMeans(pick(all_of(cols)))), .groups = "drop") |> mutate(theme = th)) |>
  mutate(theme = factor(theme, names(THEMES)),
         seg_lab = sprintf("%s\n(%s)", segment, scales::percent(shares$p[match(segment, shares$segment)], 1)))

ggplot(heat, aes(theme, seg_lab, fill = mean)) +
  geom_tile(colour = "white", linewidth = 1.4) +
  geom_text(aes(label = sprintf("%.1f", mean), colour = mean > 4.6), size = 4.1, fontface = "bold") +
  scale_fill_gradient(low = "#E6E8E9", high = "#002856", limits = c(1, 7), guide = "none") +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = ink), guide = "none") +
  labs(title = "Two kinds of luxury shopper walk past a BrandA store",
       subtitle = "Average agreement with each motivation theme (1 = low, 7 = high)",
       x = NULL, y = NULL,
       caption = "K-means segments on 12 motivation items | Fashion & Luxury Shopping Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 14)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11, face = "bold", lineheight = .95),
        axis.text.x = element_text(colour = ink, size = 10),
        panel.grid = element_blank(),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))
ggsave("output/figs/fig_segments_heat.png", width = 9.4, height = 4.6, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_segments_heat.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 3.65, dpi = 300, bg = "white")


# --- 8. Targeting: where the opportunity concentrates ------------------------------
prof <- qX |> group_by(segment) |>
  summarise(share = n() / nrow(qX), open = mean(western_open),
            take = mean(brand_a_take_rate, na.rm = TRUE), .groups = "drop")
ggplot(prof, aes(take, open, size = share, colour = segment)) +
  geom_point(alpha = .9) +
  geom_text(aes(label = str_wrap(sprintf("%s - %s of shoppers", segment, scales::percent(share, 1)), 24)),
            vjust = -1.6, size = 3.9, fontface = "bold", lineheight = .95, show.legend = FALSE) +
  scale_colour_manual(values = setNames(c("#857650", "#002856"), seg_names), guide = "none") +
  scale_x_continuous(labels = scales::percent, limits = c(0, .52)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.15)) +
  scale_size_area(max_size = 24, guide = "none") +
  labs(title = "Where the opportunity concentrates",
       subtitle = "Bubble size = share of shoppers",
       x = "Share of conjoint choices won by BrandA", y = "Open to Western style",
       caption = "Fashion & Luxury Shopping Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 14)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text = element_text(colour = ink3), axis.title = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#F1F1F2", linewidth = .4),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))
ggsave("output/figs/fig_targeting.png", width = 9.2, height = 5.8, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_targeting.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.2, height = 4.85, dpi = 300, bg = "white")

