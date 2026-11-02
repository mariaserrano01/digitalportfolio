# ============================================================
# Script 5 - TURF: which 3 levers reach the most shoppers
# Open the project via "market-research-case.Rproj", run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Luxury_Study" (n = 64)
# ============================================================
library(tidyverse)
library(readxl)

q <- read_excel("data/survey_clean_data.xlsx", sheet = "Luxury_Study")

FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; gray <- "#9FA0A2"; pop <- "#857650"

# --- 1. The target market and the 10 levers --------------------------------------
tgt <- q |> filter(western_open, !is.na(levers_picked))   # shoppers open to Western style
levers <- c("A fitting appointment"  = "Fitting appointment",
            "Personalization"        = "Personalization",
            "Limited-edition"        = "Limited editions",
            "collaboration"          = "Artist collab",
            "university or team"     = "University collection",
            "installments"           = "Installments",
            "Lifetime care"          = "Lifetime care & resoling",
            "Styling ideas"          = "Styling ideas",
            "handmade"               = "Seeing them handmade",
            "Events and community"   = "Events & community")
M <- sapply(names(levers), function(k) str_detect(tgt$levers_picked, fixed(k)))
colnames(M) <- levers

# --- 2. TURF: reach of every possible bundle of 3 ---------------------------------
# Reach = share of the target touched by AT LEAST ONE lever in the bundle.
combos <- combn(colnames(M), 3, simplify = FALSE)                 # all 120 bundles
reach  <- sapply(combos, function(cc) mean(rowSums(M[, cc]) > 0))
best3  <- combos[[which.max(reach)]]
best3; scales::percent(max(reach))                                 # the winning bundle

# --- 3. The reach ladder: build the bundle greedily from the data -----------------
# Step 1: the single lever with the widest reach. Step 2: the lever that ADDS the most
# new people. Step 3: the next best addition.
picks <- character(0)
for (i in 1:3) {
  cand <- setdiff(colnames(M), picks)
  add  <- sapply(cand, function(l) mean(rowSums(M[, c(picks, l), drop = FALSE]) > 0))
  picks <- c(picks, names(which.max(add)))
}
step <- tibble(
  stage = factor(c(picks[1], paste("+", picks[2]), paste("+", picks[3])),
                 levels = c(picks[1], paste("+", picks[2]), paste("+", picks[3]))),
  reach = sapply(1:3, function(i) mean(rowSums(M[, picks[1:i], drop = FALSE]) > 0)))
step

ggplot(step, aes(stage, reach)) +
  geom_col(fill = c(gray, "#50606B", navy), width = .55) +
  geom_text(aes(label = scales::percent(reach, 1)), vjust = -.7, size = 5.4,
            fontface = "bold", colour = ink) +

  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, .25)) +
  labs(title = "Three levers reach 9 in 10 open shoppers",
       subtitle = "Share of Western-open shoppers who picked at least one lever in the bundle (TURF)",
       x = NULL, y = "Combined reach",
       caption = "TURF over all 120 three-lever bundles; levers chosen from 'what would make you most likely to buy' (up to 3 of 10) | Western-open shoppers, n = 45 | Oct 2026") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.x = element_text(colour = ink, size = 12, face = "bold"),
        axis.text.y = element_text(colour = ink3),
        axis.title.y = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "#F1F1F2", linewidth = .4),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_turf.png", width = 9.2, height = 5.4, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_turf.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.2, height = 4.45, dpi = 300, bg = "white")

