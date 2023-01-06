# This code sample uses the 'requests' library:
# http://docs.python-requests.org
import requests
import json
from subprocess import PIPE, run

class ProcessAutomation:
    branch_name=""
    branch_safe_name=""
    branch_merge_develop=""
    branch_merge_qa2=""
    branch_merge_qa=""
    url = "https://api.bitbucket.org/2.0/repositories/nescara/agrogalaxy-sf/pullrequests"

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer WOLmAMNOG0YXCBQyKkbu"
    }

    dict_payload = {
        "title": "",
        "source": {
            "branch": {
                "name":""
            }
        },
        "destination": {
            "branch": {
                "name": "develop"
            }
        },
        "close_source_branch": True,
        "reviewers": [
            {
            "uuid": "{2da56f29-e684-4a8c-9c8c-8d12857e9838}"
            }
        ]
    }

    def __init__(self) -> None:
        command = ["git", "branch", "--show-current"]
        result = run(command, stdout=PIPE)
        if(result.returncode == 0):
            self.branch_name = result.stdout.decode('utf-8')
            self.branch_safe_name = self.branch_name.strip()
            self.branch_name = self.branch_name.strip()
            self.branch_merge_develop = 'mergedevelop/' + self.branch_name
            self.branch_merge_qa2 = 'mergeqa2/' + self.branch_name
            self.branch_merge_qa = 'mergeqa/' +  self.branch_name

    def prepare_data_git(self) -> None:
        self.prepare_enviroments("develop", self.branch_merge_develop)
        self.prepare_enviroments("qa2", self.branch_merge_qa2)
        self.prepare_enviroments("qa", self.branch_merge_qa)
        self.prepare_pull_request()
    
    def prepare_enviroments(self, env, branch_merge) -> None:
        command_1 = ["git", "checkout", env]
        command_2 = ["git", "checkout","-b", branch_merge, env]
        command_3 = ["git", "switch", branch_merge]
        command_4 = ["git", "merge", self.branch_safe_name]
        command_push = ["git", "push", "origin", branch_merge]
        run(command_1)
        run(command_2)
        run(command_3)
        run(command_4)
        run(command_push)

    def prepare_pull_request(self) -> None:
        self.dict_payload["source"]["branch"]["name"] = self.branch_merge_develop
        self.dict_payload["title"] = self.branch_merge_develop.capitalize()
        payload = json.dumps(self.dict_payload)

        self.dict_payload["destination"]["branch"]["name"] = "qa2"
        self.dict_payload["source"]["branch"]["name"] = self.branch_merge_qa2
        self.dict_payload["title"] = self.branch_merge_qa2.capitalize()

        payload2 = json.dumps(self.dict_payload)

        self.dict_payload["destination"]["branch"]["name"] = "qa"
        self.dict_payload["source"]["branch"]["name"] = self.branch_merge_qa
        self.dict_payload["title"] = self.branch_merge_qa.capitalize()

        payload3 = json.dumps(self.dict_payload)

        requests.request(
            "POST",
            self.url,
            data=payload,
            headers=self.headers
        )

        requests.request(
            "POST",
            self.url,
            data=payload2,
            headers=self.headers
        )

        requests.request(
            "POST",
            self.url,
            data=payload3,
            headers=self.headers
        )

if __name__ == '__main__':
    ProcessAutomation().prepare_data_git()