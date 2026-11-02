# ============================================================
# Script 6 - Boots & Identity survey: the identity gate + brand funnel
# Open the project via "market-research-case.Rproj", run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Boots_Identity_Study" (n = 98)
# ============================================================
library(tidyverse)
library(readxl)

b <- read_excel("data/survey_clean_data.xlsx", sheet = "Boots_Identity_Study")

FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; gray <- "#9FA0A2"; pop <- "#857650"

# --- 1. The identity gate: 8 statements, wearers vs non-wearers --------------------
DLAB <- c(D1 = "People like me wear boots",
          D2 = "Boots on me would feel like a costume",
          D3 = "Boots are earned, not bought",
          D4 = "$1,000 boots are mainly status",
          D5 = "One pair for life over several cheap pairs",
          D6 = "Where a boot is made matters",
          D7 = "Boots connect me to family or roots",
          D8 = "Western boots belong in high fashion")

dd <- b |> filter(wearer_group != "Newcomer") |>
  pivot_longer(D1:D8, names_to = "item", values_to = "v") |>
  group_by(item, wearer_group) |>
  summarise(m = mean(v, na.rm = TRUE), .groups = "drop") |>
  mutate(lab = DLAB[item])
gapdf <- dd |> pivot_wider(names_from = wearer_group, values_from = m) |>
  mutate(gap = abs(Wearer - `Non-wearer`), widest = gap == max(gap))
dd <- dd |> left_join(gapdf |> select(item, gap, widest), by = "item") |>
  mutate(lab = factor(lab, gapdf$lab[order(gapdf$gap)]))

ggplot(dd, aes(m, lab)) +
  geom_line(aes(group = lab, linewidth = widest, colour = widest), show.legend = FALSE) +
  geom_point(aes(shape = wearer_group), size = 3.6, colour = ink, fill = "white", stroke = 1.1) +
  geom_point(data = dd |> filter(widest),
             aes(shape = wearer_group), size = 3.6, colour = pop, stroke = 1.2) +
  geom_text(data = gapdf |> filter(widest),
            aes(x = (Wearer + `Non-wearer`)/2, y = lab, label = sprintf("the widest gap: %.1f points", gap)),
            vjust = -1.3, size = 3.8, fontface = "bold", colour = pop) +
  scale_linewidth_manual(values = c(`TRUE` = 2.6, `FALSE` = 1.4)) +
  scale_colour_manual(values = c(`TRUE` = scales::alpha(pop, .35), `FALSE` = "#C8C9CA")) +
  scale_shape_manual(values = c(Wearer = 16, `Non-wearer` = 21),
                     labels = c(Wearer = "Boot wearers", `Non-wearer` = "Non-wearers")) +
  scale_x_continuous(limits = c(1, 7), breaks = 1:7,
                     name = "Average agreement (1 = strongly disagree, 7 = strongly agree)") +
  labs(title = "\u201cIt would feel like a costume\u201d is the gate into Western style",
       subtitle = "Agreement with eight identity statements, boot wearers vs. non-wearers",
       y = NULL,
       caption = "Western Boots & Identity Survey, Oct 2026, n = 98 (newcomers shown in neither group excluded from this contrast)") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11),
        axis.text.x = element_text(colour = ink3),
        axis.title.x = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F1F2", linewidth = .4),
        legend.position = "top", legend.justification = "left", legend.title = element_blank(),
        legend.text = element_text(size = 10.5, colour = ink2),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_identity_gap.png", width = 9.6, height = 5.8, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_identity_gap.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.6, height = 4.85, dpi = 300, bg = "white")


# --- 2. Brand funnel: the client brand's bottleneck is awareness ----------------------------
BR <- c(F2_BrandA = "BrandA", F2_BrandB = "BrandB", F2_BrandC = "BrandC",
        F2_BrandD = "BrandD", F2_BrandE = "BrandE",
        F2_BrandF = "BrandF", F2_RetailerG = "RetailerG")
fun <- imap_dfr(BR, function(name, col) {
  v <- b[[col]]; v <- v[!is.na(v) & v != ""]
  tibble(brand = name,
         `Has heard of it`        = mean(v != "Never heard of it"),
         `Knows it`               = mean(v %in% c("Know a bit about it", "Own a pair", "Would consider buying")),
         `Owns or would consider` = mean(v %in% c("Own a pair", "Would consider buying")))
})

fun |> pivot_longer(-brand, names_to = "stage") |>
  mutate(stage = factor(stage, c("Has heard of it", "Knows it", "Owns or would consider")),
         brand = fct_reorder(brand, value, max), is_client = brand == "BrandA") |>
  ggplot(aes(value, brand, fill = is_client)) +
  geom_col(width = .62) +
  geom_text(aes(label = scales::percent(value, 1)), hjust = -.15, size = 3.2,
            fontface = "bold", colour = ink) +
  facet_wrap(~stage) +
  scale_fill_manual(values = c(`TRUE` = pop, `FALSE` = "#C8C9CA"), guide = "none") +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1.14), breaks = c(0, .5, 1)) +
  labs(title = "The problem is reach, not appeal",
       subtitle = "Brand familiarity: BrandA (gold) trails the category at every stage",
       x = NULL, y = NULL,
       caption = "Western Boots & Identity Survey, Oct 2026, n = 98") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        strip.text = element_text(face = "bold", size = 11.5, colour = ink, hjust = 0),
        axis.text.y = element_text(colour = ink, size = 10.5),
        axis.text.x = element_text(colour = ink3, size = 8.5),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F1F2", linewidth = .4),
        panel.spacing = unit(1.6, "lines"),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_funnel.png", width = 10.6, height = 5.2, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_funnel.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 10.6, height = 4.25, dpi = 300, bg = "white")


# --- 7e. Price ceiling by wearer group -----------------------------------------
# Replaces the old pipeline version of fig_price_ceiling, whose band matching
# broke under a non-UTF-8 locale (en dashes in the labels). Bands are matched
# on digits only, so this renders the same everywhere.
band_of <- function(x) case_when(
  str_detect(coalesce(x, ""), "wouldn't")  ~ NA_character_,
  str_detect(x, "Under")  ~ "Under $150",
  str_detect(x, "150")    ~ "$150-299",
  str_detect(x, "300")    ~ "$300-499",
  str_detect(x, "500")    ~ "$500-799",
  str_detect(x, "800")    ~ "$800-1,199",
  str_detect(x, "1,200")  ~ "$1,200+",
  TRUE ~ NA_character_)
bands <- c("Under $150", "$150-299", "$300-499", "$500-799", "$800-1,199", "$1,200+")

pc <- b |>
  mutate(band = factor(band_of(B3), bands),
         wearer_group = factor(wearer_group, c("Wearer", "Newcomer", "Non-wearer"))) |>
  filter(!is.na(band)) |>
  count(wearer_group, band, .drop = FALSE) |>
  group_by(wearer_group) |> mutate(p = n / sum(n)) |> ungroup()
grp_n <- pc |> group_by(wearer_group) |> summarise(n = sum(n))
grp_n   # LOOK AT: Wearers 32, Newcomers 30, Non-wearers 27 buyers (10 non-wearers would not buy)

ggplot(pc, aes(band, p, fill = wearer_group)) +
  geom_col(position = position_dodge(.72), width = .62) +
  geom_vline(xintercept = 2.5, colour = pop, linetype = "42", linewidth = .7) +
  annotate("text", x = 2.44, y = .455, label = "the $300 line", hjust = 1,
           size = 3.6, fontface = "bold.italic", colour = pop, family = FAM) +
  geom_text(aes(label = ifelse(p > 0, scales::percent(p, 1), "")),
            position = position_dodge(.72), vjust = -.55, size = 2.9,
            colour = ink2, family = FAM) +
  scale_fill_manual(values = c(Wearer = navy, Newcomer = ink2, `Non-wearer` = gray),
                    breaks = c("Wearer", "Newcomer", "Non-wearer"),
                    labels = c("Wearers (n = 31)", "Newcomers (n = 30)", "Non-wearers (n = 27)")) +
  scale_y_continuous(labels = scales::percent, limits = c(0, .5),
                     expand = expansion(mult = c(0, .02))) +
  labs(title = "Most will not cross $300 - until the boot feels like them",
       subtitle = "\"The most you would pay for the right pair of Western boots\" - share of each group per price band",
       x = NULL, y = "Share of group",
       caption = "Western Boots & Identity Survey, Oct 2026, n = 88 would-be buyers (10 who would not buy Western boots excluded)") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 17),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.x = element_text(colour = ink, size = 10.5),
        axis.text.y = element_text(colour = ink3),
        axis.title.y = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "#F1F1F2", linewidth = .4),
        legend.position = "top", legend.justification = "left", legend.title = element_blank(),
        legend.text = element_text(size = 10, colour = ink2),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_price_ceiling.png", width = 9.4, height = 5.4, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_price_ceiling.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 4.45, dpi = 300, bg = "white")

