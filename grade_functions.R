#' Grade processing functions for CourseKata gradebook
#'
#' @author shawn schwartz
#' @date fall 2025
#'
#' These functions process CourseKata completion reports and merge them
#' with Canvas gradebooks to generate upload-ready gradebook files.

suppressPackageStartupMessages(library(tidyverse))

#' Extract maximum score from CourseKata format string
#'
#' @param str String in format "release/5.6.2-exp1:5, A:5, B:5"
#' @param release_version Release version prefix to remove (default: "release/5.6.2-exp1:")
#' @return Numeric maximum score
get_max_score <- function(str, release_version = "release/5.6.2-exp1:") {
  parsed <- gsub(release_version, "", str) |>
    substr(1, 2)

  if (substr(parsed, 2, 2) == ",") {
    return(substr(parsed, 0, 1) |> as.numeric())
  } else {
    return(substr(parsed, 0, 2) |> as.numeric())
  }
}

#' Compute scores from CourseKata completion report
#'
#' @param file Path to CourseKata CSV file
#' @param chs Vector of chapter prefixes to process
#' @param release_version Release version prefix (default: "release/5.6.2-exp1:")
#' @param threshold_cap Threshold cap for score adjustment (default: 0.9)
#' @param threshold_pass Threshold for passing score (default: 0.9)
#' @return List of dataframes with computed scores per chapter
compute_scores <- function(file, chs, release_version = "release/5.6.2-exp1:", threshold_cap = 0.9, threshold_pass = 0.9) {
  scores <- list()

  for (ch in chs) {
    ch_regex <- ch
    if (ch != "pre") ch_regex <- paste0("^", ch, "_")

    df <- read_csv(file, show_col_types = FALSE) |>
      select(-lms_id, -branch, -last_response) |>
      rename_with(~ gsub(" - complete", "", .)) |>
      rename_with(~ gsub("\\.", "_sec_", .)) |>
      rename_with(~ gsub("Page ", "ch_", .)) |>
      rename("pre_1" = "First Things First") |>
      rename("pre_2" = "Pre-Survey") |>
      mutate(sunet = gsub("@stanford.edu", "", email), .after = email) |>
      select(-email) |>
      select(first_name, last_name, sunet, matches(ch_regex))

    max_points <- df |>
      slice(1) |>
      mutate(across(starts_with(ch), ~ get_max_score(., release_version))) |>
      select(matches(ch_regex)) |>
      pivot_longer(cols = everything(), names_to = "page", values_to = "max")

    df <- df |>
      slice(-1) |>  # remove the points header (row 1)
      mutate(across(matches(ch), as.numeric))

    # special cases
    # pre-chapter 1 page 2 -> points encoded as 0 in header, manually set to
    # .5 of max score (since this is a survey), if they completed at least .5,
    # they should get credit (since there are questions they don't technically)
    # need to answer, which is why there's so much variability in the raw scores
    # for this section
    if (ch == "pre") {
      max_points[2,2] <- floor(0.5 * max(df$pre_2))
    }

    pages <- names(df)
    pages <- pages[4:length(pages)]

    for (p in pages) {
      page_max <- max_points |>
        filter(page == p) |>
        pull(max)

      df <- df |>
        mutate(!!paste0("score_", p) := pmin(.data[[p]] / page_max, 1)) |>
        mutate(!!paste0("qs_", p) := page_max)
    }

    df <- df |>
      mutate(total_resp = rowSums(across(starts_with(ch)))) |>
      mutate(total_qs = rowSums(across(starts_with("qs_")))) |>
      mutate(raw_avg = total_resp / total_qs) |>
      mutate(capped_avg = pmin(raw_avg, 1)) |>
      mutate(adjusted_score = if_else(capped_avg <= threshold_cap, capped_avg / threshold_cap, threshold_cap)) |>
      mutate(final_score = if_else(adjusted_score >= threshold_pass, 1, 0))

    scores[[ch]] <- df
  }

  return(scores)
}

#' Generate Canvas-ready gradebook from processed scores
#'
#' @param file Path to Canvas gradebook CSV
#' @param scores List of score dataframes from compute_scores()
#' @param ids Vector of Canvas assignment IDs
#' @return Dataframe formatted for Canvas upload
make_canvas_gradebook <- function(file, scores, ids) {
  canvas_gradebook <- read_csv(file, na = c("", NA), show_col_types = FALSE)

  if (length(scores) != length(ids)) {
    stop("scores and assignment ids are not the same length!")
  }

  scores_list <- list()

  for (i in seq_along(ids)) {
    new_names <- c("SIS Login ID", ids[i])

    scores_df <- scores[[i]] |>
      select(sunet, final_score) |>
      mutate(final_score = as.character(final_score)) |>
      `colnames<-`(new_names)

    scores_list[[i]] <- scores_df
  }

  scores_merged <- reduce(scores_list, full_join, by = "SIS Login ID")

  metadata_rows <- canvas_gradebook |>
    slice(c(1, 2))

  canvas_gradebook <- canvas_gradebook |>
    select(-all_of(ids))

  canvas_gradebook <- scores_merged |>
    right_join(canvas_gradebook, by = "SIS Login ID")

  canvas_gradebook <- bind_rows(
    metadata_rows, canvas_gradebook
  ) |>
    mutate(across(everything(), ~ replace(., is.na(.), "")))

  return(canvas_gradebook)
}
