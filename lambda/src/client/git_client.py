from git import Repo
from git.exc import GitCommandError

# TODO: Create another "user" that can push to the repo.
# Provide authentication credentials if needed
username = "damienjburks"
password = (
    "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"  # TODO: Upload into SSM and rotate
)

# Repository URL
repo_url = f"https://{username}:{password}@github.com/The-DevSec-Blueprint/dsb-digest.git"  # Replace with your repository URL

# Clone the repository
try:
    # Clone the repository
    Repo.clone_from(repo_url, ".test_folder/")
    print("Repository cloned successfully.")
except GitCommandError as e:
    print("Error:", e)
