#' CourseKata Gradebook Processor - Shiny App
#'
#' @author shawn schwartz
#' @date fall 2025
#'
#' A web application to process CourseKata gradebook files for Canvas upload.
#' Upload Canvas gradebook and CourseKata progress report to generate
#' a processed gradebook ready for Canvas import.
#'
library(shiny)
library(tidyverse)

# Source the grade processing functions
source("grade_functions.R")

# Define UI
ui <- fluidPage(
  # Custom CSS and JavaScript
  tags$head(
    tags$script(HTML("
      Shiny.addCustomMessageHandler('download', function(message) {
        var blob = new Blob([message.content], {type: 'text/csv'});
        var url = window.URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = message.filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      });
    ")),
    tags$style(HTML("
      body {
        background-color: #c9beb0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
        -webkit-font-smoothing: antialiased;
        padding: 20px;
      }
      .container-fluid {
        max-width: 1200px;
        margin: 0 auto;
        background: #f5f1ed;
        border-radius: 24px;
        padding: 40px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
      }
      .main-header {
        background: transparent;
        color: #2d3436;
        padding: 0 0 30px 0;
        margin-bottom: 30px;
        border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      }
      .main-header h1 {
        font-weight: 700;
        font-size: 28px;
        margin-bottom: 8px;
        color: #2d3436;
      }
      .main-header p {
        color: #636e72;
        font-size: 14px;
        margin: 0;
      }
      .upload-box {
        background: white;
        padding: 24px;
        border-radius: 20px;
        margin-bottom: 16px;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
        border: none;
        transition: transform 0.2s, box-shadow 0.2s;
      }
      .upload-box:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
      }
      .upload-box h3 {
        color: #2d3436;
        font-weight: 600;
        font-size: 16px;
        margin-bottom: 16px;
      }
      .btn-primary {
        background: #2d3436;
        border: none;
        padding: 14px 32px;
        font-size: 15px;
        font-weight: 600;
        border-radius: 12px;
        color: white;
        transition: all 0.2s;
      }
      .btn-primary:hover {
        background: #1e2325;
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(45, 52, 54, 0.3);
      }
      .btn-secondary {
        background: white;
        border: 1px solid #dfe6e9;
        color: #2d3436;
        padding: 8px 20px;
        font-size: 13px;
        font-weight: 500;
        border-radius: 10px;
        transition: all 0.2s;
      }
      .btn-secondary:hover {
        background: #2d3436;
        color: white;
        border-color: #2d3436;
      }
      .result-box {
        background: white;
        padding: 24px;
        border-radius: 20px;
        margin-top: 16px;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
        border-left: 4px solid #00b894;
      }
      .result-box h4 {
        color: #2d3436;
        font-weight: 600;
        margin-bottom: 12px;
      }
      .result-box p {
        color: #636e72;
        margin-bottom: 8px;
      }
      .error-box {
        background: white;
        padding: 24px;
        border-radius: 20px;
        margin-top: 16px;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
        border-left: 4px solid #ff7675;
      }
      .error-box h4 {
        color: #2d3436;
        font-weight: 600;
        margin-bottom: 12px;
      }
      .error-box p {
        color: #636e72;
      }
      .form-control {
        border: 1px solid #dfe6e9;
        border-radius: 12px;
        padding: 10px 14px;
        transition: all 0.2s;
      }
      .form-control:focus {
        border-color: #2d3436;
        outline: 0;
        box-shadow: 0 0 0 3px rgba(45, 52, 54, 0.1);
      }
      label {
        color: #2d3436;
        font-weight: 500;
        font-size: 14px;
        margin-bottom: 8px;
      }
      .help-block {
        color: #95a5a6;
        font-size: 12px;
      }
      hr {
        border-color: rgba(0, 0, 0, 0.08);
        margin: 24px 0;
      }
    "))
  ),

  # Header
  div(class = "main-header",
    h1(HTML("&#128202; CourseKata Gradebook Processor")),
    p("Upload your Canvas gradebook and CourseKata progress report to generate a processed gradebook for Canvas.")
  ),

  # Main content
  fluidRow(
    column(6,
      div(class = "upload-box",
        h3(HTML("&#128193; Canvas Gradebook")),
        fileInput("canvas_file",
                  "Upload Canvas Gradebook CSV",
                  accept = c(".csv")),
        helpText(HTML("Export from Canvas: Grades &rarr; Export &rarr; Export Entire Gradebook"))
      )
    ),
    column(6,
      div(class = "upload-box",
        h3(HTML("&#128200; CourseKata Progress Report")),
        fileInput("coursekata_file",
                  "Upload CourseKata Completion Report CSV",
                  accept = c(".csv")),
        helpText(HTML("Download from CourseKata: My Progress + Jupyter &rarr; Refresh &rarr; Completion Report"))
      )
    )
  ),

  fluidRow(
    column(12,
      div(class = "upload-box",
        h3(HTML("&#9881; Processing Options")),
        numericInput("week_number",
                    "Week Number:",
                    value = 1,
                    min = 1,
                    max = 12),
        hr(),
        h4(HTML("&#128295; Configuration")),
        actionButton("toggle_config",
                    "Show/Hide Advanced Configuration",
                    class = "btn btn-secondary btn-sm",
                    style = "margin-bottom: 15px;"),
        uiOutput("config_panel"),
        hr(),
        actionButton("process_btn",
                    "Process Gradebook",
                    class = "btn-primary btn-lg")
      )
    )
  ),

  # Results section
  fluidRow(
    column(12,
      uiOutput("result_message"),
      uiOutput("download_section")
    )
  ),

  # Footer
  hr(),
  p(style = "text-align: center; color: #666;",
    HTML("Made with &#10084; by Shawn Schwartz | "),
    tags$a(href = "https://github.com/shawntz", "GitHub", target = "_blank")
  )
)

# Define server logic
server <- function(input, output, session) {

  # Reactive value to store processed gradebook
  processed_gradebook <- reactiveVal(NULL)

  # Reactive value to track config panel visibility
  config_visible <- reactiveVal(FALSE)

  # Default configuration values
  default_canvas_ids <- paste(c(
    "CourseKata: Pre-Chapter 1 Modules (including survey) (637734)",
    "CourseKata: Chapter 1 Modules (637723)",
    "CourseKata: Chapter 2 Modules (637727)",
    "CourseKata: Chapter 3 Modules (637728)",
    "CourseKata: Chapter 4 Modules (637729)",
    "CourseKata: Chapter 5 Modules (637730)",
    "CourseKata: Chapter 6 Modules (637731)",
    "CourseKata: Chapter 7 Modules (637732)",
    "CourseKata: Chapter 9 Modules (637733)",
    "CourseKata: Chapter 10 Modules (637724)",
    "CourseKata: Chapter 11 Modules (637725)",
    "CourseKata: Chapter 12 Modules (637726)"
  ), collapse = "\n")

  default_ch_prefix <- paste(c(
    "pre", "ch_1", "ch_2", "ch_3", "ch_4", "ch_5",
    "ch_6", "ch_7", "ch_9", "ch_10", "ch_11", "ch_12"
  ), collapse = ", ")

  # Toggle configuration panel
  observeEvent(input$toggle_config, {
    config_visible(!config_visible())
  })

  # Render configuration panel
  output$config_panel <- renderUI({
    if (config_visible()) {
      div(style = "margin-top: 15px; padding: 15px; background: #f9f9f9; border-radius: 5px;",
        helpText("Enter each Canvas Assignment ID on a new line. Include the full text with ID in parentheses."),
        textAreaInput("canvas_ids",
                     "Canvas Assignment IDs:",
                     value = default_canvas_ids,
                     rows = 8,
                     width = "100%"),
        helpText("Enter chapter prefixes separated by commas (e.g., pre, ch_1, ch_2, ...)"),
        textInput("ch_prefix",
                 "Chapter Prefixes:",
                 value = default_ch_prefix,
                 width = "100%")
      )
    }
  })

  # Process gradebook when button is clicked
  observeEvent(input$process_btn, {
    # Reset previous results
    processed_gradebook(NULL)

    # Validate inputs
    req(input$canvas_file)
    req(input$coursekata_file)
    req(input$week_number)

    # Show processing message
    output$result_message <- renderUI({
      div(class = "result-box",
        h4(HTML("&#8987; Processing...")),
        p("Please wait while we process your gradebook files.")
      )
    })

    # Try to process the files
    tryCatch({
      # Read uploaded files
      canvas_path <- input$canvas_file$datapath
      coursekata_path <- input$coursekata_file$datapath

      # Get configuration values
      if (config_visible() && !is.null(input$canvas_ids) && !is.null(input$ch_prefix)) {
        # Use custom configuration
        canvas_ids <- trimws(strsplit(input$canvas_ids, "\n")[[1]])
        canvas_ids <- canvas_ids[canvas_ids != ""]  # Remove empty lines

        ch_prefix <- trimws(strsplit(input$ch_prefix, ",")[[1]])
        ch_prefix <- ch_prefix[ch_prefix != ""]  # Remove empty entries
      } else {
        # Use default configuration
        canvas_ids <- c(
          "CourseKata: Pre-Chapter 1 Modules (including survey) (637734)",
          "CourseKata: Chapter 1 Modules (637723)",
          "CourseKata: Chapter 2 Modules (637727)",
          "CourseKata: Chapter 3 Modules (637728)",
          "CourseKata: Chapter 4 Modules (637729)",
          "CourseKata: Chapter 5 Modules (637730)",
          "CourseKata: Chapter 6 Modules (637731)",
          "CourseKata: Chapter 7 Modules (637732)",
          "CourseKata: Chapter 9 Modules (637733)",
          "CourseKata: Chapter 10 Modules (637724)",
          "CourseKata: Chapter 11 Modules (637725)",
          "CourseKata: Chapter 12 Modules (637726)"
        )

        ch_prefix <- c(
          "pre", "ch_1", "ch_2", "ch_3", "ch_4", "ch_5",
          "ch_6", "ch_7", "ch_9", "ch_10", "ch_11", "ch_12"
        )
      }

      # Compute scores
      scores <- compute_scores(coursekata_path, ch = ch_prefix)

      # Generate Canvas gradebook
      result <- make_canvas_gradebook(canvas_path, scores, canvas_ids)

      # Store result
      processed_gradebook(result)

      # Show success message
      output$result_message <- renderUI({
        div(class = "result-box",
          h4(HTML("&#9989; Success!")),
          p(paste0("Gradebook processed successfully for Week ", input$week_number, ".")),
          p("Click the download button below to get your processed gradebook.")
        )
      })

      # Show download button (using actionButton instead of downloadButton for Shinylive)
      output$download_section <- renderUI({
        div(style = "text-align: center; margin-top: 20px;",
          actionButton("download_gradebook",
                      "Download Processed Gradebook",
                      class = "btn-primary btn-lg")
        )
      })

    }, error = function(e) {
      # Show error message
      output$result_message <- renderUI({
        div(class = "error-box",
          h4(HTML("&#10060; Error")),
          p("An error occurred while processing your files:"),
          p(style = "font-family: monospace; background: #fff; padding: 10px; border-radius: 4px;",
            as.character(e))
        )
      })

      output$download_section <- renderUI(NULL)
    })
  })

  # Download handler for Shinylive - uses browser download
  observeEvent(input$download_gradebook, {
    req(processed_gradebook())

    # Create temporary file
    temp_file <- tempfile(fileext = ".csv")
    write.csv(processed_gradebook(), temp_file, row.names = FALSE)

    # Read file as text
    csv_content <- paste(readLines(temp_file), collapse = "\n")

    # Generate filename
    filename <- paste0("week-", input$week_number, ".csv")

    # Use JavaScript to trigger download in browser
    session$sendCustomMessage("download", list(
      content = csv_content,
      filename = filename
    ))
  })
}

# Run the application
shinyApp(ui = ui, server = server)
