suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tidyr)
})

repo_root <- normalizePath(system("git rev-parse --show-toplevel", intern = TRUE), mustWork = TRUE)

data_dir <- file.path(repo_root, "artifacts", "data")
figure_dir <- file.path(repo_root, "artifacts", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(figure_dir, "figure-3-runs"), recursive = TRUE, showWarnings = FALSE)

theme_paper <- function() {
  theme_bw(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey92", color = "grey70"),
      strip.text = element_text(face = "bold")
    )
}

save_pdf <- function(plot, filename, width = 8.5, height = 5.2) {
  ggsave(file.path(figure_dir, filename), plot, width = width, height = height, device = cairo_pdf)
}

read_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }
  read_csv(path, show_col_types = FALSE)
}

series_labels <- c(
  potential_real_rate_taste_shock_only = "Potential real rate (taste shock only)",
  nominal_interest_rate_taste_shock_only = "Nominal interest rate (taste shock only)",
  potential_real_rate_1_percent_g_increase = "Potential real rate -1% g(t) increase",
  potential_real_rate_2_percent_g_increase = "Potential real rate -2% g(t) increase",
  both_shocks = "Both shocks",
  taste_shock_only = "Taste shock only",
  government_shock_only = "Government shock only"
)

figure_1a <- read_if_exists(file.path(data_dir, "figure-1a.csv"))
if (!is.null(figure_1a)) {
  p <- figure_1a %>%
    mutate(series = recode(series, !!!series_labels)) %>%
    ggplot(aes(quarter, value, color = series, linetype = series)) +
    geom_line(na.rm = TRUE, linewidth = 0.9) +
    scale_x_continuous(breaks = c(0, 4, 8, 12)) +
    scale_y_continuous(breaks = seq(-10, 0, 2), limits = c(-10, 0)) +
    coord_cartesian(xlim = c(0, 12), clip = "off") +
    labs(
      title = "Negative Taste Shock and Fiscal Response",
      x = "Quarters",
      y = NULL
    ) +
    guides(
      color = guide_legend(nrow = 2, byrow = TRUE),
      linetype = guide_legend(nrow = 2, byrow = TRUE)
    ) +
    theme_paper() +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 9),
      legend.box.margin = margin(t = 4)
    )
  save_pdf(p, "figure-1a.pdf", width = 8.5, height = 5.8)
}

figure_1b <- read_if_exists(file.path(data_dir, "figure-1b.csv"))
if (!is.null(figure_1b)) {
  base <- ggplot(figure_1b, aes(potential_real_interest_rate, liquidity_trap_duration)) +
    scale_x_continuous(breaks = seq(-14, 0, 2)) +
    scale_y_continuous(breaks = seq(0, 15, 5)) +
    coord_cartesian(xlim = c(-14, 0), ylim = c(0, 15)) +
    labs(
      title = "Liquidity Trap Duration and Potential Real Interest Rate",
      x = "Potential Real Interest Rate",
      y = "Liquidity trap duration"
    ) +
    theme_paper() +
    theme(legend.position = "none")

  save_pdf(base + geom_line(color = "#1f78b4", linewidth = 0.9), "figure-1b.pdf")
  save_pdf(base + geom_point(color = "#1f78b4", size = 1.2, alpha = 0.8), "figure-1b-scatter.pdf")
}

plot_figure_2 <- function(path) {
  df <- read_csv(path, show_col_types = FALSE) %>%
    mutate(
      variable = recode(
        variable,
        real_interest_rate = "Real Interest Rate",
        output_gap = "Output Gap",
        inflation = "Inflation",
        government_debt_to_gdp = "Government Debt/GDP"
      ),
      variable = factor(variable, levels = c(
        "Real Interest Rate", "Output Gap", "Inflation", "Government Debt/GDP"
      )),
      series = recode(series, !!!series_labels)
    )

  title <- if (unique(df$figure_id) == "figure-2-5-quarter-price-contract") {
    "5 Quarter Price Contracts"
  } else {
    "No Inflation Response"
  }

  p <- ggplot(df, aes(quarter, value, color = series, linetype = series)) +
    geom_line(na.rm = TRUE, linewidth = 0.8) +
    facet_wrap(~variable, scales = "free_y", ncol = 2) +
    scale_x_continuous(breaks = c(0, 4, 8, 12, 16), limits = c(0, 18)) +
    labs(title = title, x = "Quarters", y = NULL) +
    theme_paper()

  save_pdf(p, paste0(unique(df$figure_id), ".pdf"), width = 9, height = 6.2)
}

walk_files <- list.files(data_dir, pattern = "^figure-2.*\\.csv$", full.names = TRUE)
invisible(lapply(walk_files, plot_figure_2))

read_many <- function(pattern) {
  files <- list.files(data_dir, pattern = pattern, full.names = TRUE)
  if (!length(files)) {
    return(NULL)
  }
  bind_rows(lapply(files, read_csv, show_col_types = FALSE))
}

contract_labels <- c(
  `1` = "No inflation response",
  `0.9` = "10 qtr contracts",
  `0.8` = "5 qtr contracts",
  `0.75` = "4 qtr contracts"
)

multiplier <- read_many("^figure-3-multiplier-xip-.*\\.csv$")
if (!is.null(multiplier)) {
  multiplier <- multiplier %>%
    mutate(contract = recode(as.character(xip), !!!contract_labels))

  for (xip_value in unique(multiplier$xip)) {
    df <- filter(multiplier, xip == xip_value) %>%
      pivot_longer(
        c(marginal_multiplier, average_multiplier),
        names_to = "series",
        values_to = "value"
      ) %>%
      mutate(series = recode(
        series,
        marginal_multiplier = "Marginal multiplier",
        average_multiplier = "Average multiplier"
      ))

    p <- ggplot(df, aes(shock, value, color = series, linetype = series)) +
      geom_line(na.rm = TRUE, linewidth = 0.9) +
      scale_x_continuous(breaks = seq(-0.5, 0.5, 0.25), labels = c("-10", "-5", "0", "5", "10")) +
      labs(
        title = if (xip_value == 1) "No Inflation Response" else unique(filter(multiplier, xip == xip_value)$contract),
        x = "% Change in Govt Spend (Share of GDP)",
        y = "Government Spending Multiplier"
      ) +
      theme_paper()
    save_pdf(p, file.path("figure-3-runs", sprintf("multiplier-xip-%0.2f.pdf", xip_value)))
  }

  alt <- multiplier %>%
    filter(xip != 1) %>%
    mutate(contract = factor(contract, levels = c("10 qtr contracts", "5 qtr contracts", "4 qtr contracts")))

  p_alt <- ggplot(alt, aes(shock, marginal_multiplier, color = contract, linetype = contract)) +
    geom_line(na.rm = TRUE, linewidth = 0.9) +
    scale_x_continuous(breaks = seq(-0.5, 0.5, 0.25), labels = c("-10", "-5", "0", "5", "10")) +
    labs(
      title = "Alternative Price Contract Durations",
      x = "% Change in Govt Spend (Share of GDP)",
      y = "Government Spending Multiplier"
    ) +
    theme_paper()
  save_pdf(p_alt, "figure-3-alternative-contract-durations-multiplier.pdf")
}

debt <- read_many("^figure-3-government-debt-xip-.*\\.csv$")
if (!is.null(debt)) {
  debt <- debt %>%
    mutate(contract = recode(as.character(xip), !!!contract_labels))

  p_no_inflation <- debt %>%
    filter(xip == 1, shock >= 0) %>%
    ggplot(aes(shock, government_debt_multiplier)) +
    geom_line(color = "#1f78b4", linewidth = 0.9) +
    scale_x_continuous(breaks = seq(0, 0.5, 0.1), labels = c("0", "2", "4", "6", "8", "10")) +
    scale_y_continuous(breaks = seq(0, 1, 0.2)) +
    coord_cartesian(ylim = c(0, 1)) +
    labs(
      title = "No Inflation Response",
      x = "% Change in Govt Spend (Share of GDP)",
      y = "Government Debt to Actual GDP"
    ) +
    theme_paper() +
    theme(legend.position = "none")
  save_pdf(p_no_inflation, "figure-3-no-inflation-response-government-debt.pdf")

  p_alt_debt <- debt %>%
    filter(xip != 1, shock >= 0) %>%
    mutate(contract = factor(contract, levels = c("10 qtr contracts", "5 qtr contracts", "4 qtr contracts"))) %>%
    ggplot(aes(shock, government_debt_multiplier, color = contract, linetype = contract)) +
    geom_line(na.rm = TRUE, linewidth = 0.9) +
    scale_x_continuous(breaks = seq(0, 0.5, 0.1), labels = c("0", "2", "4", "6", "8", "10")) +
    scale_y_continuous(breaks = seq(-1, 0.5, 0.5)) +
    coord_cartesian(ylim = c(-1, 0.5)) +
    labs(
      title = "Alternative Price Contract Durations",
      x = "% Change in Govt Spend (Share of GDP)",
      y = "Government Debt to Actual GDP"
    ) +
    theme_paper()
  save_pdf(p_alt_debt, "figure-3-alternative-contract-durations-government-debt.pdf")
}

duration <- read_many("^figure-3-liquidity-trap-duration-xip-.*\\.csv$")
if (!is.null(duration)) {
  p <- duration %>%
    filter(xip == 1) %>%
    ggplot(aes(shock, liquidity_trap_duration)) +
    geom_line(color = "#1f78b4", linewidth = 0.9) +
    scale_x_continuous(breaks = seq(-0.5, 0.5, 0.25), labels = c("-10", "-5", "0", "5", "10")) +
    labs(
      x = "% Change in Govt Spend (Share of GDP)",
      y = "Liquidity trap duration"
    ) +
    theme_paper() +
    theme(legend.position = "none")
  save_pdf(p, "figure-3-liquidity-trap-duration.pdf")
}
