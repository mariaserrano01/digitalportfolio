# ============================================================
# Script 3 - Choice-Based Conjoint: what a boot is worth, in dollars
# Open the project via "market-research-case.Rproj", run line by line.
# Data: data/survey_clean_data.xlsx, sheet "Conjoint_Choices"
#       (64 people x 8 choice screens x 4 options = 2,048 rows)
# ============================================================
library(tidyverse)
library(readxl)
library(survival)

cbc <- read_excel("data/survey_clean_data.xlsx", sheet = "Conjoint_Choices")

FAM <- if (Sys.info()[["sysname"]] == "Darwin") "Helvetica" else "sans"
ink <- "#051C2C"; ink2 <- "#50606B"; ink3 <- "#76777B"
navy <- "#002856"; steel <- "#50606B"; gray <- "#9FA0A2"; pop <- "#857650"

# --- 1. The model: conditional logit --------------------------------------------
# Each choice screen is its own mini-market (strata). The model learns how much
# each attribute pulled choices toward an option, holding the others constant.
cbc <- cbc |> mutate(bA = brand == "BrandA", bB = brand == "BrandB",
                     bC = brand == "BrandC", price100 = ifelse(brand == "None", 0, price / 100))

m <- clogit(chosen ~ bA + bB + bC + everyday + exotic + fitting + price100 +
              strata(choice_screen_id), data = cbc)
summary(m)        # LOOK AT: price100 is negative and p < .0001 (people mind price)
co <- coef(m)

# --- 2. Willingness to pay: divide any utility by the price utility --------------
wtp <- function(x) round(-x / co["price100"] * 100)
wtp(co["bATRUE"] - co["bCTRUE"])   # BrandA brand premium vs BrandC  ~ $329
wtp(co["bATRUE"] - co["bBTRUE"])   # vs BrandB                       ~ $153
wtp(co["fitting"])                     # fitting + lifetime resoling      ~ $304
wtp(co["everyday"])                    # everyday vs classic tall shaft   ~ $187
wtp(co["exotic"])                      # exotic leather                   ~ $50 (ns)

# --- 3. Chart: the price tags shoppers put on each element -----------------------
v <- vcov(m); se_wtp <- function(g) sqrt(t(g) %*% v %*% g)[1] / abs(co["price100"]) * 100
gv <- function(k) { g <- setNames(rep(0, length(co)), names(co)); g[k] <- 1; g }
wt <- tribble(
  ~effect,                                   ~dollars,                               ~g,
  "The BrandA name (vs. BrandC)",           wtp(co["bATRUE"] - co["bCTRUE"]),   gv("bATRUE") - gv("bCTRUE"),
  "Fitting appointment\n+ lifetime resoling", wtp(co["fitting"]),                    gv("fitting"),
  "Everyday silhouette\n(vs. classic tall shaft)", wtp(co["everyday"]),              gv("everyday"),
  "The BrandA name (vs. BrandB)",         wtp(co["bATRUE"] - co["bBTRUE"]),   gv("bATRUE") - gv("bBTRUE"),
  "Exotic leather (vs. cowhide)",            wtp(co["exotic"]),                      gv("exotic")) |>
  mutate(se = map_dbl(g, se_wtp), sig = abs(dollars) > 1.96 * se,
         effect = fct_reorder(effect, dollars))

ggplot(wt, aes(dollars, effect, fill = sig)) +
  geom_col(width = .58) +
  geom_errorbar(aes(xmin = dollars - 1.96*se, xmax = dollars + 1.96*se),
                width = .12, orientation = "y", colour = ink2, linewidth = .45) +
  geom_text(aes(x = dollars + 1.96*se + 14, label = paste0("$", dollars)), hjust = 0,
            size = 4.6, fontface = "bold", colour = ink, show.legend = FALSE) +
  geom_vline(xintercept = 0, colour = ink3, linewidth = .5) +
  scale_fill_manual(values = c(`TRUE` = navy, `FALSE` = gray),
                    labels = c(`TRUE` = "Statistically reliable", `FALSE` = "Within chance")) +
  scale_x_continuous(labels = scales::dollar, limits = c(-30, 560), breaks = seq(0, 500, 100)) +
  labs(title = "Shoppers put real price tags on brand and service",
       subtitle = "Willingness to pay per pair, from 512 real choices between competing boots",
       x = "Willingness to pay (whiskers = 95% confidence interval)", y = NULL,
       caption = "Choice-based conjoint, conditional logit | WTP = attribute utility / price utility | Fashion & Luxury Shopping Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11.5, lineheight = .95),
        axis.text.x = element_text(colour = ink3),
        axis.title.x = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F1F2", linewidth = .4),
        legend.position = "top", legend.justification = "left", legend.title = element_blank(),
        legend.text = element_text(size = 10, colour = ink2),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_cbc_wtp.png", width = 9.4, height = 5.4, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_cbc_wtp.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 4.45, dpi = 300, bg = "white")


# --- 4. Price simulator: what share does a BrandA everyday boot take? ----------
sim <- function(pL) {
  u <- c(BrandA = unname(co["bATRUE"] + co["everyday"] + co["fitting"] + co["price100"] * pL / 100),
         BrandB  = unname(co["bBTRUE"] + co["everyday"] + co["price100"] * 3.95),
         BrandC    = unname(co["bCTRUE"] + co["price100"] * 3.95),
         None     = 0)
  exp(u) / sum(exp(u))
}
grid <- tibble(price = seq(395, 1195, 25)) |>
  rowwise() |> mutate(share = sim(price)["BrandA"], revenue = price * share) |> ungroup()
best <- grid |> slice_max(revenue)

ggplot(grid, aes(price, share)) +
  annotate("rect", xmin = best$price - 100, xmax = best$price + 100, ymin = -Inf, ymax = Inf,
           fill = pop, alpha = .08) +
  geom_line(colour = navy, linewidth = 1.3) +
  geom_point(data = best, size = 3.6, colour = pop) +
  geom_text(data = best, aes(label = sprintf("Revenue peaks near $%d\n(%.0f%% still choose BrandA)", price, 100*share)),
            nudge_y = .09, size = 3.8, fontface = "bold", colour = ink, lineheight = 1.05) +
  scale_x_continuous(labels = scales::dollar) +
  scale_y_continuous(labels = scales::percent, limits = c(0, .62)) +
  labs(title = "An everyday BrandA with fitting holds its price",
       subtitle = "Simulated share choosing BrandA vs. BrandB and BrandC priced at $395, as the BrandA price rises",
       x = "BrandA price per pair", y = "Share choosing BrandA",
       caption = "Logit market simulator from the conjoint model; includes the option to buy nothing | Fashion & Luxury Shopping Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text = element_text(colour = ink3), axis.title = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#F1F1F2", linewidth = .4),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_cbc_price.png", width = 9.4, height = 5.4, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_cbc_price.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 4.45, dpi = 300, bg = "white")


# --- 5. Attribute importance: share of decision weight --------------------------
# Importance = each attribute's utility range (best minus worst level), as a share
# of all ranges. Price uses its full tested span ($395 to $995 = 6 x $100).
rng <- c(max(co[c("bATRUE","bBTRUE","bCTRUE")]) - min(co[c("bATRUE","bBTRUE","bCTRUE")]),
         abs(co["price100"]) * 6, abs(co["fitting"]), abs(co["everyday"]), abs(co["exotic"]))
imp <- tibble(attribute = c("Brand", "Price ($395-$995)", "Service (fitting + resole)",
                            "Style (everyday vs. classic)", "Leather (exotic vs. cowhide)"),
              importance = as.numeric(rng) / sum(rng)) |>
  mutate(top = importance == max(importance), attribute = fct_reorder(attribute, importance))
imp   # LOOK AT: price carries ~41%; brand (22%) + service (21%) together match it

ggplot(imp, aes(importance, attribute, fill = top)) +
  geom_col(width = .58, show.legend = FALSE) +
  geom_text(aes(label = scales::percent(importance, 1)), hjust = -.35, size = 4.6,
            fontface = "bold", colour = ink, family = FAM) +
  scale_fill_manual(values = c(`TRUE` = pop, `FALSE` = navy)) +
  scale_x_continuous(labels = scales::percent, limits = c(0, max(imp$importance) * 1.18),
                     expand = expansion(mult = c(0, .02))) +
  labs(title = "Price weighs heaviest; brand plus service weigh the same combined",
       subtitle = "Share of total decision weight for each attribute, from 512 real choices",
       x = "Relative importance (utility range / total)", y = NULL,
       caption = "Choice-based conjoint, conditional logit | importance = attribute utility range as share of all ranges | Fashion & Luxury Shopping Study, Oct 2026, n = 64") +
  theme_minimal(base_size = 13, base_family = FAM) +
  theme(text = element_text(colour = ink),
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(colour = ink2, size = 11, margin = margin(b = 16)),
        plot.caption = element_text(colour = ink3, size = 7.6, hjust = 0, margin = margin(t = 14)),
        plot.title.position = "plot", plot.caption.position = "plot",
        axis.text.y = element_text(colour = ink, size = 11.5),
        axis.text.x = element_text(colour = ink3),
        axis.title.x = element_text(colour = ink2, size = 10),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F1F2", linewidth = .4),
        plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(18, 24, 14, 24))

ggsave("output/figs/fig_cbc_importance.png", width = 9.4, height = 5, dpi = 220, bg = "white")
# Deck version: same chart, no subtitle, one-line source (slide title does the talking)
ggsave("output/figs_deck/fig_cbc_importance.png", plot = ggplot2::last_plot() + labs(title = NULL, subtitle = NULL, caption = NULL),
       width = 9.4, height = 4.05, dpi = 300, bg = "white")

