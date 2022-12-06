# This code sample uses the 'requests' library:
# http://docs.python-requests.org
import requests
import json
from subprocess import PIPE, run

command = ["git", "branch", "--show-current"]

command_qa = ["git", "branch", "--show-current"]
command_qa2 = ["git", "branch", "--show-current"]
result = run(command, stdout=PIPE)
if(result.returncode == 0):
    branch_name = result.stdout.decode('utf-8')
    branch_name = branch_name.strip().split('/')[1]
    branch_merge_develop = 'mergedevelop/' + branch_name
    branch_merge_qa2 = 'mergeqa2/' + branch_name
    branch_merge_qa = 'mergeqa/' +  branch_name
    command_develop_1 = ["git", "checkout", "develop"]
    command_develop_2 = ["git", "checkout", branch_merge_develop]
    command_push = ["git", "push", "origin", branch_merge_develop]
    run(command_develop_1)
    run(command_develop_2)
    run(command_push)
# value = subprocess.call(["git", "branch", "--show-current"])
# print(value.__str__())

url = "https://api.bitbucket.org/2.0/repositories/nescara/agrogalaxy-sf/pullrequests"

headers = {
  "Accept": "application/json",
  "Content-Type": "application/json",
  "Authorization": "Bearer WTZ5iFK9ADQZvUfKEjT2"
}
branch_merge = "mergeqa/testeAutomation"
dict_payload = {
    "title": "Teste",
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
dict_payload["source"]["branch"]["name"] = branch_merge_develop
payload = json.dumps(dict_payload)


# payload2 = json.dumps( {
#     "title": "Teste",
#     "source": {
#         "branch": {
#             "name": {branch_merge}
#         }
#     },
#     "destination": {
#         "branch": {
#             "name": "qa2"
#         }
#     },
#     "reviewers": [
#         {
#            "uuid": "{2da56f29-e684-4a8c-9c8c-8d12857e9838}"
#         }
#     ]
# } )

# payload3 = json.dumps( {
#     "title": "Teste",
#     "source": {
#         "branch": {
#             "name": {branch_merge}
#         }
#     },
#     "destination": {
#         "branch": {
#             "name": "qa"
#         }
#     },
#     "reviewers": [
#         {
#            "uuid": "{2da56f29-e684-4a8c-9c8c-8d12857e9838}"
#         }
#     ]
# } )

response = requests.request(
   "POST",
   url,
   data=payload,
   headers=headers
)

print(json.dumps(json.loads(response.text), sort_keys=True, indent=4, separators=(",", ": ")))