import logging

from git import Repo
from git.exc import GitCommandError

from client.ssm_client import SsmClient


class GitClient:
    def __init__(self):
        self.repo_url = self._create_authenticated_url()

    def commit(self, video_title, md_file_content, repo: Repo):
        path = repo.working_tree_dir

        with open(f"{path}/rename_file.md", "w+") as f:
            f.write(md_file_content)

        repo.index.add("rename_file.md")
        commit_info = repo.index.commit(
            "Initial Commit of Post for video, %s", video_title
        )

        logging.info("File & Commit created successfully!")

        return commit_info

    def push(self, repo: Repo):
        origin = repo.remote("origin")
        origin.push()
        logging.info("Push to GitHub happened successfully!")

    def clone(self, branch_name):
        try:
            repo = Repo.clone_from(self.repo_url, "/tmp")
            logging.info("Repository cloned successfully!")

            # Checkout a new branch
            new_branch = repo.create_head(branch_name)
            repo.head.reference = new_branch
            repo.head.reset(index=True, working_tree=True)

            return repo
        except GitCommandError as e:
            logging.error(f"Error cloning repository: {e}")
            raise e

    def _create_authenticated_url(self):
        username = SsmClient().get_parameter(name="/credentials/git/username")
        token = SsmClient().get_parameter(name="/credentials/git/auth_token")
        repo_url = f"https://{username}:{token}@github.com/The-DevSec-Blueprint/dsb-digest.git"  # Replace with your repository URL
        return repo_url


if __name__ == "__main__":
    GitClient().clone()
    GitClient().commit()
    GitClient().push()
    print("Done!")
