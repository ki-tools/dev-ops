#!/usr/bin/env Rscript

ensure_packages <- function() {
  packages <- c("optparse", "git2r", "jsonlite")
  
  for (package in packages) {
    installed <- require(package, character.only = TRUE)
    
    if (!installed) {
      install.packages(package, dependencies = TRUE, repos = "http://cran.us.r-project.org")
    }
  }
}

install_sysreqs_packages <- function(package_command, package_platform, dry_run) {
  # Create a temp directory to hold the GIT repo
  repo_path <- file.path(tempfile())
  dir.create(repo_path, recursive = TRUE)
  
  # Clone the GIT repo
  repo <- git2r::clone("https://github.com/r-hub/sysreqsdb", repo_path)
  
  json_dir_path <- paste(repo_path, 'sysreqs', sep = .Platform$file.sep)
  json_files <- list.files(json_dir_path, pattern = "\\.json$")
  
  failed <- list()
  
  # Install the packages
  for (file_name in json_files) {
    print(paste("Processing: ", file_name))
    
    full_file_name <- paste(json_dir_path, file_name, sep = .Platform$file.sep)
    json_data <- jsonlite::fromJSON(full_file_name)
    
    packages <- json_data[[1]]$platform[[package_platform]]
    
    # Check for distribution/release specific packages and warn the user.
    # TODO: Handle these packages.
    if (class(packages) == "data.frame") {
      msg <- "Distribution/Release specific. Needs manual install."
      print(paste(" ", msg))
      failed <- append(failed, paste(file_name, '->', msg))
      packages <- NULL
    }
    
    for (package in packages) {
      if (length(package) == 0) next
      
      print(paste("  Installing: ", package))
      
      command <- paste(package_command, package)
      
      if (dry_run) {
        print(paste("   ", command))
      } else {
        if (system(command) > 0) {
          failed <- append(failed, paste(file_name, '->', package))
        }
      }
    }
  }
  
  # Show any failed packages
  if (!!length(failed)) {
    print("Failed Packages:")
    
    for (package in failed) {
      print(paste(" -", package))
    }
  }
  
  # Delete the temp dir
  unlink(repo_path, recursive = TRUE)
}

main <- function() {
  ensure_packages()
  
  option_list <- list(
    make_option(c("-p", "--platform"), type="character", default="RPM",
                help="Package platform type [default: %default]"),
    make_option(c("-c", "--command"), type="character", default="yum install -y",
                help="Package manager install command [default: %default]"),
    make_option(c("-d", "--dry-run"), action="store_true", default=FALSE, dest="dry_run",
                help="Execute script but do not insall packages [default: %default]")
  )
  opt = parse_args(OptionParser(option_list=option_list))
  
  dry_run <- opt$dry_run
  package_command <- opt$command
  package_platform <- opt$platform
  
  if (.Platform$OS.type == "windows" || toupper(package_platform) == "WINDOWS") {
    stop("Windows is not currently supported by this script.")
  }
  
  if (dry_run) print(paste("Dry run: ", dry_run))
  print(paste("Package Install command: ", package_command))
  print(paste("Package platform: ", package_platform))
  
  install_sysreqs_packages(package_command, package_platform, dry_run)
}

main()
