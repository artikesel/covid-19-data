# get_resources <- function() {
#     resources <- read_html("https://datos.ins.gob.pe/dataset?q=%22pruebas+moleculares%22&organization=covid-19&sort=metadata_modified+desc") %>%
#         html_nodes(".dataset-heading a") %>%
#         html_attr("href") %>%
#         paste0("https://datos.ins.gob.pe", .)
#     return(resources)
# }
#
# get_resource_url <- function(url) {
#     file_url <- read_html(url) %>%
#         html_nodes(".resource-item a") %>%
#         html_attr("href") %>%
#         str_subset("\\.csv$")
#     return(file_url)
# }
#
# resources <- get_resources()
# files <- sapply(resources, FUN = get_resource_url, USE.NAMES = FALSE)

process_file <- function(url) {
    df <- fread(url, showProgress = FALSE, select = c("FECHATOMAMUESTRA"))
    setnames(df, "Date")
    df[, Date := ymd(Date)]
    return(df)
}

files <- "https://datos.ins.gob.pe/dataset/666d1d60-a737-4729-a649-a8ad9ecd235a/resource/2e8d3d4e-4815-4dcc-950d-4619b49e179d/download/pm_27nov_2020.csv"
data <- rbindlist(lapply(files, FUN = process_file))
df <- data[, .(`Daily change in cumulative total` = .N), Date]

stopifnot(max(df$Date) >= today() - 10)

existing <- fread("automated_sheets/Peru.csv")
existing[, Date := ymd(Date)]
existing <- existing[Date < min(df$Date)]

df <- rbindlist(list(df, existing), fill = TRUE)
setorder(df, Date)

df[, Country := "Peru"]
df[, Units := "tests performed"]
df[, `Source URL` := "https://datos.ins.gob.pe/dataset?q=%22pruebas+moleculares%22&organization=covid-19"]
df[, `Source label` := "National Institute of Health"]
df[, `Testing type` := "PCR only"]
df[, Notes := NA]

fwrite(df, "automated_sheets/Peru.csv")
