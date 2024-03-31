import logging

from git import Repo
from git.exc import GitCommandError

from client.ssm_client import SsmClient


class GitClient:
    def __init__(self):
        self.repo_url = self._create_authenticated_url()

    def commit(self):
        pass

    def push(self):
        pass

    def clone(self):
        try:
            cloned_repo = Repo.clone_from(self.repo_url, "/tmp")
            logging.info("Repository cloned successfully!")
            return cloned_repo
        except GitCommandError as e:
            logging.error(f"Error cloning repository: {e}")
            raise e

    def _create_authenticated_url(self):
        username = SsmClient.get_parameter(name="credentials/git/username")
        token = SsmClient.get_parameter(name="credentials/git/auth_token")
        repo_url = f"https://{username}:{token}@github.com/The-DevSec-Blueprint/dsb-digest.git"  # Replace with your repository URL
        return repo_url
