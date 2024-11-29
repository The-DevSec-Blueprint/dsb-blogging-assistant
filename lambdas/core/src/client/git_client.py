"""
Git client for checking in blog posts into the dsb-digest repository.
"""

import os
import logging
import string
import random

from git import Repo
from git.exc import GitCommandError

from client.ssm_client import SsmClient

logging.getLogger().setLevel(logging.INFO)


class GitClient:
    """
    Git client class for checking in blog posts into the dsb-digest repository.
    """

    def __init__(self):
        self.repo_url = self._create_authenticated_url()

    def commit(self, video_title, md_file_content, repo: Repo):
        """
        This function commits the blog post to the dsb-digest repository.
        """

        path = repo.working_tree_dir

        with open(f"{path}/rename_file.md", "w+", encoding="utf-8") as f:
            f.write(md_file_content)

        repo.index.add("rename_file.md")
        commit_info = repo.index.commit(
            message=f"Initial commit of blog for video: {video_title}", skip_hooks=True
        )

        logging.info("Commit created successfully!")

        return commit_info

    def push(self, repo: Repo):
        """
        This function pushes the changes to the dsb-digest repository.
        """

        origin = repo.remote("origin")
        repo.git.push("--set-upstream", "-f", origin.name, repo.active_branch.name)
        logging.info("Push to GitHub successfully!")

    def clone(self, branch_name):
        """
        This function clones the dsb-digest repository.
        """

        try:
            dir_name = f"/tmp/{self._create_folder_name()}"
            os.mkdir(dir_name)
            repo = Repo.clone_from(self.repo_url, dir_name)
            logging.info("Repository cloned successfully!")

            # Checkout a new branch
            new_branch = repo.create_head(branch_name, force=True)
            repo.head.reference = new_branch
            repo.head.reset(index=True, working_tree=True)

            return repo
        except GitCommandError as e:
            logging.error("Error cloning repository: %s", str(e))
            raise e

    def _create_authenticated_url(self):
        """
        This function creates an authenticated URL for the dsb-digest repository.
        """

        username = SsmClient().get_parameter(name="/credentials/git/username")
        token = SsmClient().get_parameter(name="/credentials/git/auth_token")
        repo_url = (
            f"https://{username}:{token}@github.com/The-DevSec-Blueprint/dsb-digest.git"
        )

        return repo_url

    def _create_folder_name(
        self, size=10, chars=string.ascii_uppercase + string.digits
    ):
        """
        Private function to create a random folder name to temporarily clone the repository.
        """

        return "".join(random.choice(chars) for _ in range(size))
