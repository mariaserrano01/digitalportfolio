# ============================================================
# Script 2 - What drives interest in the brand?
# Open the project via "market-research-case.Rproj", then run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Luxury_Study" (n = 64)
# ============================================================
library(tidyverse)
library(readxl)
library(broom)

q <- read_excel("data/survey_clean_data.xlsx", sheet = "Luxury_Study")

# --- 1. Build the predictors --------------------------------------------------
d <- q |>
  filter(!is.na(interest_1to7)) |>
  mutate(
    wearer  = western_relationship %in% c("Longtime wearer", "New wearer"),
    curious = western_relationship == "Curious",
    woman   = str_detect(coalesce(gender, ""), "Woman"),
    spend1k = !is.na(luxury_spend_usd) & luxury_spend_usd >= 1000
  )

# --- 2. The regression ---------------------------------------------------------
mod <- lm(interest_1to7 ~ ab_message_arm + wearer + curious + luxury_buyer +
            spend1k + age_group + texas + woman, data = d)

summary(mod)                        # LOOK AT: R-squared (~.59) and the p-values
res <- tidy(mod, conf.int = TRUE)
res

# --- 3. Chart: coefficient plot -------------------------------------------------
FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; gray <- "#9FA0A2"

plot_d <- res |>
  filter(term != "(Intercept)") |>
  mutate(label = recode(term,
    "ab_message_armLifestyle message" = "Saw lifestyle (vs. heritage) message",
    "wearerTRUE"       = "Already wears Western style",
    "curiousTRUE"      = "Curious about Western style",
    "luxury_buyerTRUE" = "Bought luxury in past 2 years",
    "spend1kTRUE"      = "Spends $1,000+/yr on luxury",
    "age_group30-45"   = "Age 30-45 (vs. 18-29)",
    "age_group46+"     = "Age 46+ (vs. 18-29)",
    "texasTRUE"        = "Lives in Texas",
    "womanTRUE"        = "Woman"),
    sig = p.value < .05,
    label = fct_reorder(label, estimate))

ggplot(plot_d, aes(estimate, label, colour = sig)) +
  geom_vline(xintercept = 0, colour = "#C8C9CA", linewidth = .6) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = .14,
                orientation = "y", linewidth = .5) +
  geom_point(size = 3.4) +
  geom_text(aes(label = sprintf("%+.1f", estimate)), vjust = -1.1, size = 3.4,
            fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = navy, `FALSE` = gray), guide = "none") +
  labs(title = "Identity predicts interest; demographics barely matter",
       subtitle = "Effect on interest rating (1-7) \u00b7 navy = statistically significant \u00b7 95% CI",
       x = "Change in interest, in points on the 1-7 scale", y = NULL,
       caption = sprintf("OLS regression, R\u00b2 = %.2f \u00b7 Fashion & Luxury Shopping Study \u00b7 Oct 2026 \u00b7 n = %d",
                         summary(mod)$r.squared, nrow(d))) +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 14)),
        plot.caption = element_text(colour = ink3, size = 8, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#F1F1F2", linewidth = .45),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_drivers.png", width = 9, height = 5.2, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_drivers.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.0, height = 4.25, dpi = 300, bg = "white")

