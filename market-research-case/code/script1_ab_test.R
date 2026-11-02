# ============================================================
# Script 1 - A/B Message Test: Heritage vs. Lifestyle
# Open the project via "market-research-case.Rproj", then run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Luxury_Study" (n = 64)
# ============================================================
library(tidyverse)
library(readxl)

q <- read_excel("data/survey_clean_data.xlsx", sheet = "Luxury_Study")

# --- 1. Randomization check ----------------------------------------------------
table(q$ab_message_arm)                           # 37 Heritage vs 27 Lifestyle
chisq.test(table(q$ab_message_arm, q$age_group))  # p = .78 -> groups comparable

# --- 2. The test ----------------------------------------------------------------
t.test(interest_1to7 ~ ab_message_arm, data = q)   # p = .19 -> no significant difference
t.test(brand_fit_1to7 ~ ab_message_arm, data = q)  # p = .70

# --- 3. Effect size (Cohen's d) --------------------------------------------------
means <- tapply(q$interest_1to7, q$ab_message_arm, mean, na.rm = TRUE)
round((means[1] - means[2]) / sd(q$interest_1to7, na.rm = TRUE), 2)   # ~0.38

# --- 4. Chart (business style: navy = ours, gray = context) ----------------------
FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; gray <- "#9FA0A2"

absum <- q |>
  filter(!is.na(ab_message_arm)) |>
  pivot_longer(c(interest_1to7, brand_fit_1to7), names_to = "outcome") |>
  mutate(outcome = ifelse(outcome == "interest_1to7",
                          "How interested are you in this brand?",
                          "Is this a brand for people like you?"),
         arm = str_remove(ab_message_arm, " message")) |>
  group_by(outcome, arm) |>
  summarise(m = mean(value, na.rm = TRUE),
            se = sd(value, na.rm = TRUE) / sqrt(sum(!is.na(value))), .groups = "drop") |>
  mutate(ypos = as.numeric(factor(outcome)) + ifelse(arm == "Heritage", .16, -.16))

ggplot(absum, aes(m, ypos, fill = arm)) +
  geom_col(orientation = "y", width = .28) +
  geom_errorbar(aes(xmin = m - 1.96*se, xmax = m + 1.96*se), width = .07,
                orientation = "y", colour = ink2, linewidth = .45, show.legend = FALSE) +
  geom_text(aes(x = m + 1.96*se + .12, label = sprintf("%.1f", m)), hjust = 0,
            size = 3.9, fontface = "bold", colour = ink, show.legend = FALSE) +
  scale_fill_manual(values = c(Heritage = gray, Lifestyle = navy),
                    labels = c(Heritage  = "Heritage message \u00b7 n = 37",
                               Lifestyle = "Lifestyle message \u00b7 n = 27")) +
  scale_x_continuous(limits = c(0, 7.3), breaks = 1:7,
                     name = "Average rating (1 = not at all \u00b7 7 = extremely), whiskers = 95% CI") +
  scale_y_continuous(breaks = 1:2, labels = sort(unique(absum$outcome))) +
  guides(fill = guide_legend(nrow = 2)) +
  labs(title = "The story barely matters \u2014 the audience does",
       y = NULL,
       caption = "Randomized A/B test \u00b7 differences within chance (interest p = .19, brand fit p = .70) \u00b7 Fashion & Luxury Shopping Study \u00b7 Oct 2026 \u00b7 n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.caption = element_text(colour = ink3, size = 8, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11.5, face = "bold"),
        axis.text.x = element_text(colour = ink2),
        axis.title.x = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#F1F1F2", linewidth = .45),
        legend.position = "top", legend.justification = "left",
        legend.title = element_blank(), legend.text = element_text(size = 10, colour = ink2),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_abtest.png", width = 9, height = 4.9, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_abtest.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.0, height = 3.95, dpi = 300, bg = "white")

