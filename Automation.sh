#!/bin/bash

### Project Variables ###

project_name=""
project_description=""
Language=""
github=false
public=false
pipenv=false
description=false


### Functions ###

# Function to handle the case when required arguments are missing
no_args() {
  echo "Please add needed arguments"  # Inform the user that arguments are missing
  print_usage  # Display usage instructions
  echo "For further instructions, use '-h'"  # Suggest using '-h' for more details
  exit 1  # Exit the script with a non-zero status (error)
}

# Function to display a concise usage message
print_usage() {
  echo "Usage: script_name -n <project_name> [-d] [-g] -l <language> [-h] [-v]"  # Provide a concise usage message
}

# Function to display detailed help information
print_help() {
  echo "
  Following arguments can be provided:

    -n       Project name - will be used for the project folder

    -d       (optional) If you wish to apply a description to the project. It will be added to the README file.

    -g       (optional) If you wish to create a Github repository and add a remote connection. You will be asked if it should be public or not.

    -l       The programming language you wish to use. If not provided, you will be asked explicitly.
             Depending on your choice of language, certain files may be provided.
    
    -v       (optional) If you wish to create a virtual environment with pipenv.
             
             " 
  exit 1  # Exit the script with a non-zero status (error)
}

add_description() {
  echo "Enter your projectdescription. Type 'end' on a line by itself to finish."

  while IFS= read -r line; do
    if [ "$line" = "end" ]; then
      break  # Exit the loop when 'end' is entered
    fi
    project_description="${project_description}${line}\n"  # Append each line to the variable
  done

  # Remove the trailing newline character
  project_description="${project_description%\\n}"
}

# Function to create the project directory and initial project files
create_project() {

  # Create a local project directory with the provided project name
  mkdir "$project_name" || { echo "Error: Unable to create the project directory."; exit 1; }

  # Navigate to the project directory
  cd "$project_name" || { echo "Error: Unable to change directory to the project directory."; exit 1; }

  # Create a directory for project assets
  mkdir assets

  # Call the 'create_files' function to create project files
  create_files

  # Initialize Pipenv environment if the pipenv flag is raised
  if [ "$pipenv" = true ]; then
    pipenv shell 
  fi

  # Call the 'git_actions' function to initialize git
  git_actions

  if [ "$github" = true ]; then
    github # Call the 'github' function to create remote repository if the github flag is raised
  fi

  exit 0
}

# Function to create project-specific files based on the selected programming language
create_files() {

  # Create a README.md file with the project name
  echo "# $project_name" > README.md

  # If a description has been provided, add it to the README file while preserving existing line breaks
  if [ "$description" = true ]; then
    echo  -e "\n$project_description" >> README.md
  fi


  if [ "$language" = "Python" ]; then
    # Create Python-specific files
    echo '' > main.py
    echo '' > playground.py
  fi
}

# Function to handle Git actions
git_actions() {
  # Initialize a Git repository
  git init || { echo "Error: Unable to initialize a Git repository."; exit 1; }

  # Commit the present files
  git add .
  git commit -m "Initial commit" || { echo "Error: Unable to commit the initial commit."; exit 1; }
}

# Function to create a remote GitHub repository and initiate the connection
github() {
  # Create a remote GitHub repository using GitHub CLI with the project name and description
  if [ "$public" = true ]; then
    # Set the repository to be public if the public flag is set to true
    gh repo create "$project_name" --description "$project_description" --public || { echo "Error: Unable to create the GitHub repository."; exit 1; }
  else
    # Otherwise, set the repository to private
    gh repo create "$project_name" --description "$project_description" --private || { echo "Error: Unable to create the GitHub repository."; exit 1; }
  fi

  # Set the default branch name to 'main' and push your code to the remote repository
  git branch -M main

  # Add a remote named 'origin' with the correct SSH URL
  git remote add origin git@github.com:Rodhor/"$project_name".git

  # Push the code to the remote 'origin' repository
  git push -u origin main || { echo "Error: Unable to push code to the remote repository."; exit 1; }
}

# Parse command-line options
while getopts "n:dgv:l:h" opt; do
  case "${opt}" in
    n)
      project_name="${OPTARG}"  # Set the project name based on the provided argument
      ;;
    d)
      description=true  # Set the description flag to true
      ;;
    g)
      github=true  # Set the GitHub flag to true
      read -p "Should the repository be public? [y/n]: " public_choice  # Prompt the user for the 'public' choice
      if [ "$public_choice" = "y" ]; then
        public=true  # If the user enters 'y', set the 'public' flag to true
      fi
      ;;
    v)
      pipenv=true # Set the pipenv flag to true
      ;;
    l)
      if [ "${OPTARG}" = "p" ] || [ "${OPTARG}" = "P" ]|| [ "${OPTARG}" = "python" ]|| [ "${OPTARG}" = "Python" ]; then
        language="Python"  # If the argument is 'p' or 'python', set the language to 'Python'
      elif [ "${OPTARG}" = "b" ] || [ "${OPTARG}" = "B" ]|| [ "${OPTARG}" = "bash" ]|| [ "${OPTARG}" = "Bash" ]; then
        language="Bash" 
      elif [ -n "${OPTARG}" ]; then
        language="${OPTARG}"  # If 'language' is already set, update it with the provided argument
      else
        language=""  # If 'language' is not set, set it to an empty string
      fi
      ;;
    h)
      print_help  # Call the 'help' function if -h is used
      ;;
    \?)
      no_args  # Call the 'no_args' function if an invalid option is used
      ;;
  esac
done

# Check if the user used -l without an argument
if [ "$OPTIND" -gt 1 ] && [ "${OPTARG}" = ":" ]; then
  read -p "Which language will be used?: " language
fi



# Check for missing or empty required options
if [ -z "$project_name" ]; then
  no_args
fi

# Check if user wants to add a project description
if [ "$description" = true ]; then
  add_description
fi

# Confirm options with the user
echo "Project name: $project_name"
echo "Language: $language"

if [ -z "$project_description" ]; then
 echo "Project description will be added later"
else
  echo "Project description: $project_description"
fi

if [ "$github" = true ] && [ "$public" = true ]; then
 echo "A Public GitHub repository will be created."
elif [ "$github" = true ] && [ "$public" = false ]; then
 echo "A Private GitHub repository will be created."
else
  echo "No GitHub repository will be created."
fi

read -p "Proceed with these options? [y/n]: " confirm
if [ "$confirm" != "y" ]; then
  echo "Operation canceled."
  exit 0
fi

# Navigate to the Projectsfolder 
cd "/home/rodhor/Documents/Projects/$language/" || { echo "Error: Unable to change directory."; exit 1; }

create_project

# Display a success message
echo "Project '$project_name' created"
  

$SHELL