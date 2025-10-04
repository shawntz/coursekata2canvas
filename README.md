# CourseKata ➡️ Gradebook Processor App

A web app to process CourseKata gradebook files for Canvas upload.

## 🌟 Use it here or deploy your own fork!

🌐 https://shawnschwartz.shinyapps.io/coursekata2canvas/

## Deployment

### ➡️ ShinyApps.io

1. **Install `rsconnect`:**

   ```r
   install.packages("rsconnect")
   ```

2. **Set up your `shinyapps.io` account:**
   - Create account at <https://www.shinyapps.io/>
   - Get your token and secret from Account → Tokens

3. **Deploy:**

   ```bash
   make deploy
   ```

   or...

   ```r
   library(rsconnect)
   setAccountInfo(name="<ACCOUNT>", token="<TOKEN>", secret="<SECRET>")
   deployApp("coursekata2canvas")
   ```

### ➡️ Local development

Run the app locally:

   ```bash
   make run
   ```
   
   or...
   
   ```r
   library(shiny)
   runApp("app.R")
   ```

## How to use the app

1. **Export Canvas Gradebook:**
   - In Canvas, go to Grades → Export → Export Entire Gradebook
   - Save the CSV file

2. **Download CourseKata Progress Report:**
   - Go to "My Progress + Jupyter" module in CourseKata
   - Click "Refresh Reports"
   - Download the "Completion" report

3. **Upload to the App:**
   - Upload both CSV files
   - Select the week number
   - Click "Process Gradebook"
   - Download the processed file

4. **Upload to Canvas:**
   - In Canvas, go to Grades → Import
   - Upload the processed CSV file
   - Review and confirm the import

## Requirements

- R >= 4.0
- tidyverse
- shiny
