library("webshot")
library("leaps")
library("ggplot2")
library('dplyr')
library("kableExtra")
library("knitr")


# cleaning data 
data <- small_scores
data$individuals_per_taxa <- as.numeric(data$individuals_per_taxa)
data <- na.omit(data)

# singleGLM analysis
data$scSEQ_score <- 1 - data$scSEQ_score
single_data <- data[data$scSEQ_score != 2,] 
#& ! (data$effective_population_size %in% c(33305, 40092)), ]
singleglm <- glm(scSEQ_score~
                   no_of_taxa+
                   exponential_growth_rate+
                   individuals_per_taxa+
                   effective_population_size+
                   species_birth_rate+
                   tree_wide_sub_rate+
                   no_of_sites+
                   ado+
                   amplification_error+
                   sequencing_errors, 
                 data = single_data)
summary(singleglm)
#plot(singleglm)



# making the singleGLM table
glm_summary <- summary(singleglm)

parameter_labels <- data.frame(
  Parameter = c("(Intercept)", "no_of_taxa", "exponential_growth_rate",
                "individuals_per_taxa", "effective_population_size",
                "species_birth_rate", "tree_wide_sub_rate", "no_of_sites",
                "ado", "amplification_error", "sequencing_errors"),
  Label = c("Intercept","Number of Tumours", "Exponential Growth Rate",
            "Cells per Tumour", "Effective Population Size",
            "Metastatic Rate", "Mutation Rate", "Number of Sites",
            "Allelic Dropout", "Amplification Error", "Sequencing Errors")
)

rownames(glm_summary$coefficients) <- parameter_labels$Label[
  match(rownames(glm_summary$coefficients), parameter_labels$Parameter)
]

glm_summary_with_stars <- data.frame(
  glm_summary$coefficients,
  stars = ifelse(glm_summary$coefficients[, "Pr(>|t|)"] < 0.001, "***",
                 ifelse(glm_summary$coefficients[, "Pr(>|t|)"] < 0.01, "**",
                        ifelse(glm_summary$coefficients[, "Pr(>|t|)"] < 0.05, "*",
                               "")))
)

colnames(glm_summary_with_stars) <- gsub("Std..Error", "Standard Error", colnames(glm_summary_with_stars))
colnames(glm_summary_with_stars) <- gsub("t.value", "t-value", colnames(glm_summary_with_stars))
colnames(glm_summary_with_stars) <- gsub("Pr...t..", "p-value", colnames(glm_summary_with_stars))
colnames(glm_summary_with_stars)[colnames(glm_summary_with_stars) == "stars"] <- ""


kable_table <- kable(glm_summary_with_stars, format = "html", align = "c", caption = "GLM on Phylogenetic Accuracy of Reconstructed scSEQ Trees (MR-Full)", escape = FALSE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed", "responsive"),
    font_size = 20, 
    full_width = FALSE, 
    position = "center", 
    fixed_thead = TRUE 
  ) %>%
  column_spec(1:ncol(glm_summary_with_stars), extra_css = "font-family: 'Noto Serif Sinhala', serif; color: black;")


temp_html <- tempfile(fileext = ".html")
save_kable(kable_table, file = temp_html)

save_path_png <- "12/results/small_scores/singleGLM.png"
webshot(temp_html, file = save_path_png, zoom = 2)
unlink(temp_html)

# R^2 analysis

colnames(single_data) <- c("Taxa", "CellsPerTumour", "EffectivePopSize", "MetastaticRate",
                           "MutationRate", "NumberOfSites", "ExpGrowthRate", "ADO", "AmpError", "SeqError",
                           "Replicate", "scSEQ_score", "hapcon_tree_scores", "vcf_tree_scores")

single_r2 <- regsubsets(scSEQ_score ~ Taxa + CellsPerTumour +
                          EffectivePopSize + MetastaticRate + MutationRate + NumberOfSites +
                          ExpGrowthRate + ADO + AmpError + SeqError,
                        data = single_data)

reg.summary=summary(single_r2)


png("r2_plot.png", width = 10, height = 6, units = 'in', res = 300)
plot(single_r2, scale = "r2", main = "Subset Selection - Phylogenetic Accuracy of Reconstructed scSEQ Trees (MR-Full)")
dev.off()