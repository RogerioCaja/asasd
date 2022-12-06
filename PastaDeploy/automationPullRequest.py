# This code sample uses the 'requests' library:
# http://docs.python-requests.org
import requests
import json
from subprocess import PIPE, run

# command = ["git", "branch", "--show-current"]
# result = run(command, stdout=PIPE)
# if(result.returncode == 0):
#     branch_name = result.stdout.decode('utf-8')
#     branch_safe = branch_name.strip()
#     print(branch_safe)
#     branch_name = branch_name.strip().split('/')[1]
#     branch_merge_develop = 'mergedevelop/' + branch_name
#     branch_merge_qa2 = 'mergeqa2/' + branch_name
#     branch_merge_qa = 'mergeqa/' +  branch_name
    
#     command_develop_1 = ["git", "checkout", "develop"]
#     command_develop_2 = ["git", "checkout",  branch_merge_develop]
#     command_develop_3 = ["git", "merge", branch_safe]
#     command_push_develop = ["git", "push", "origin", branch_merge_develop]
    
#     command_qa_1 = ["git", "checkout", "qa"]
#     command_qa_2 = ["git", "checkout", branch_merge_qa]
#     command_qa_3 = ["git", "merge", branch_safe]
#     command_push_qa = ["git", "push", "origin", branch_merge_qa]

#     command_qa2_1 = ["git", "checkout", "qa2"]
#     command_qa2_2 = ["git", "checkout", branch_merge_qa2]
#     command_qa2_3 = ["git", "merge", branch_safe]
#     command_push_qa2 = ["git", "push", "origin", branch_merge_qa2]

#     run(command_develop_1)
#     run(command_develop_2)
#     run(command_develop_3)
#     run(command_push_develop)

#     run(command_qa_1)
#     run(command_qa_2)
#     run(command_qa_3)
#     run(command_push_qa)

#     run(command_qa2_1)
#     run(command_qa2_2)
#     run(command_qa2_3)
#     run(command_push_qa2)
    
# # value = subprocess.call(["git", "branch", "--show-current"])
# # print(value.__str__())

# url = "https://api.bitbucket.org/2.0/repositories/nescara/agrogalaxy-sf/pullrequests"

# headers = {
#   "Accept": "application/json",
#   "Content-Type": "application/json",
#   "Authorization": "Bearer WOLmAMNOG0YXCBQyKkbu"
# }

# dict_payload = {
#     "title": "",
#     "source": {
#         "branch": {
#             "name":""
#         }
#     },
#     "destination": {
#         "branch": {
#             "name": "develop"
#         }
#     },
#     "reviewers": [
#         {
#            "uuid": "{2da56f29-e684-4a8c-9c8c-8d12857e9838}"
#         }
#     ]
# }
# dict_payload["source"]["branch"]["name"] = branch_merge_develop
# dict_payload["title"] = branch_merge_develop.capitalize()
# payload = json.dumps(dict_payload)

# dict_payload["destination"]["branch"]["name"] = "qa2"
# dict_payload["source"]["branch"]["name"] = branch_merge_qa2
# dict_payload["title"] = branch_merge_qa2.capitalize()

# payload2 = json.dumps(dict_payload)

# dict_payload["destination"]["branch"]["name"] = "qa"
# dict_payload["source"]["branch"]["name"] = branch_merge_qa
# dict_payload["title"] = branch_merge_qa.capitalize()

# payload3 = json.dumps(dict_payload)

# response = requests.request(
#    "POST",
#    url,
#    data=payload,
#    headers=headers
# )

# response2 = requests.request(
#    "POST",
#    url,
#    data=payload2,
#    headers=headers
# )

# response3 = requests.request(
#    "POST",
#    url,
#    data=payload3,
#    headers=headers
# )

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
            self.branch_name = self.branch_name.strip().split('/')[1]
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
        command_3 = ["git", "merge", self.branch_safe_name]
        command_push = ["git", "push", "origin", branch_merge]
        run(command_1)
        run(command_2)
        run(command_3)
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
            url,
            data=payload,
            headers=headers
        )

        requests.request(
            "POST",
            url,
            data=payload2,
            headers=headers
        )

        requests.request(
            "POST",
            url,
            data=payload3,
            headers=headers
        )

if __name__ == '__main__':
    ProcessAutomation.prepare_data_git()