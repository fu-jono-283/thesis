initial_dir <- "data/2_ccoal"
main_dir <- "data/5_concat/"

subdirs <- list.dirs(initial_dir, full.names = TRUE, recursive = TRUE) 

subdirs <- subdirs[!grepl("_ipynb_checkpoints", subdirs)]

for (subdir in subdirs) {
  consensus_file <- file.path(subdir, "full_haplotypes_dir", "full_hap.0001_consensus.fasta")
  if (file.exists(consensus_file)) {
    replicate_label <- basename(subdir)
    target_dir <- file.path(main_dir, replicate_label)
    if (!dir.exists(target_dir)) {
      dir.create(target_dir, recursive = TRUE)
    }
    file.copy(consensus_file, target_dir)
  }
}

main_subdirs <- list.dirs(main_dir, full.names = TRUE, recursive = FALSE)

subdir_identifiers <- list()

for (subdir in main_subdirs) {
  identifier <- gsub(".*(_pop\\d+_sites\\d+r)\\d+.*", "\\1", subdir)
  
  if (!(identifier %in% names(subdir_identifiers))) {
    subdir_identifiers[[identifier]] <- list()
  }
  
  subdir_identifiers[[identifier]] <- c(subdir_identifiers[[identifier]], subdir)
}

for (identifier in names(subdir_identifiers)) {
  subdir_w_identifiers <- subdir_identifiers[[identifier]]
  
   merged_folder <- file.path(main_dir, gsub("\\W", "", identifier))
  
  if (!file.exists(merged_folder)) {
    dir.create(merged_folder)
  }
  
  replicate_counter <- 1
  
  for (folder in subdir_w_identifiers) {
    files <- list.files(folder)
    
    for (file in files) {
      if (grepl("^full_hap\\.\\d+_consensus\\.fasta$", file)) {
        current_file <- file.path(folder, file)
        replicate_label <- sprintf("r%d", replicate_counter)
        new_file <- file.path(merged_folder, paste0("full_hap.0001_consensus_", replicate_label, ".fasta"))
        
        file.rename(current_file, new_file)
        cat("Moved", current_file, "to", new_file, "\n")
        
        replicate_counter <- replicate_counter + 1
      }
    }
    
    if (file.info(folder)$isdir) {
      unlink(folder, recursive = TRUE)
      cat("Removed folder:", folder, "\n")
    }
  }
    
  source_species_tree <- file.path("data/1_simphy", paste0(identifier, "1"), "s_tree.trees")
  print(paste("Debug - Source Species Tree for Characteristic", identifier, ":", source_species_tree))

  target_species_tree <- file.path(merged_folder, "s_tree.trees")

  if (file.exists(source_species_tree)) {
    file.copy(source_species_tree, target_species_tree)
    cat("Species tree copied to:", target_species_tree, "\n")
  } else {
    cat("Error: Species tree not found for identifier", identifier, "\n")
  }
}

concat_dir <- "data/5_concat/"
subdirs <- list.dirs(concat_dir, full.names = TRUE, recursive = FALSE)

for (subdir in subdirs) {
  if (grepl("r$", subdir)) {
    new_subdir <- gsub("r$", "", subdir)  
    if (subdir != new_subdir) {
      file.rename(subdir, new_subdir)
      cat("Renamed folder:", subdir, "to", new_subdir, "\n")
    }
  }
}

main_folder <- "data/5_concat"

subdirectories <- list.dirs(main_folder, full.names = TRUE, recursive = FALSE)

sequences <- list()

for (folder_path in subdirectories) {
  sequences <- list()
  
  fasta_files <- list.files(folder_path, pattern = ".fasta$", full.names = TRUE)
  
  for (file in fasta_files) {
    lines <- readLines(file)
    
    current_header <- NULL
    current_sequence <- NULL
    
    for (line in lines) {
      if (startsWith(line, ">")) {
        if (!is.null(current_header)) {
          sequences[[current_header]] <- paste(sequences[[current_header]], current_sequence, sep = "")
        }
        current_header <- line
        current_sequence <- ""
      } else {
        current_sequence <- paste(current_sequence, line, sep = "")
      }
    }
    
    sequences[[current_header]] <- paste(sequences[[current_header]], current_sequence, sep = "")
  }
  
  output_file <- file.path(folder_path, "concat.fasta")
  
  writeLines(paste(names(sequences), unlist(sequences), sep = "\n"), con = output_file)
}


