# Simple script to copy readme.html to index.html for GitHub Pages land on:
file.copy(from = here::here("readme.html"), to = here::here("index.html"), overwrite = T)

