import requests
import json
import pandas

# empty list to add all titles from downloaded registrations to

all_title = []
all_desc = []
all_id = []
all_public = []
all_emb = []
all_type = []
all_withdrawn = []
all_auth = []
all_pre = []
all_tags = []
all_proj = []

# get search resutls from first page
print("Downloading first page of results")
url = "https://api.osf.io/v2/registrations/?filter%5Bdate_created%5D%5Bgt%5D=2019-12-31&format=json&page=540"
r = requests.get(url)
data = r.json()

# store first page of values
 store values from next page
for i in data["data"]:
    all_title.append(i["attributes"]["title"])
    all_desc.append(i["attributes"]["description"])
    all_id.append(i["id"])
    all_public.append(i["attributes"]["public"])
    all_emb.append(i["attributes"]["embargoed"])
    all_type.append(i["attributes"]["registration_supplement"])
    all_withdrawn.append(i["attributes"]["withdrawn"])
    all_auth.append(i["relationships"]["contributors"]["links"]["related"]["href"])
    try:
        all_pre.append(i["attributes"]["registered_meta"]["q10"]["value"])
    except:
        all_pre.append(None)
    try:
        all_tags.append(i["attributes"][tags])
    except:
        all_tags.append(None)
    all_proj.append(i["relationships"]["registered_from"]["data"]["id"])

#######################
# save all json files ####
########################

# "next" elements gives link to next page >
# as long as next isn't empty download the next page's data and store only the titles


while data["links"]["next"] is not None:
    page = int(data["links"]["next"].rpartition("=")[-1]) - 1
    page = str(page)
    filename = "osf_pg_" + page + ".json"
    with open(filename, "w") as f:
        json.dump(data, f)
    print("Next page found, getting", data["links"]["next"])
    response = requests.get(data["links"]["next"])
    data = response.json()
    # store values from next page
    for i in data["data"]:
        all_title.append(i["attributes"]["title"])
        all_desc.append(i["attributes"]["description"])
        all_id.append(i["id"])
        all_public.append(i["attributes"]["public"])
        all_emb.append(i["attributes"]["embargoed"])
        all_type.append(i["attributes"]["registration_supplement"])
        all_withdrawn.append(i["attributes"]["withdrawn"])
        all_auth.append(i["relationships"]["contributors"]["links"]["related"]["href"])
        try:
            all_pre.append(i["attributes"]["registered_meta"]["q10"]["value"])
        except:
            all_pre.append(None)
        try:
            all_tags.append(i["attributes"][tags])
        except:
            all_tags.append(None)
        all_proj.append(i["relationships"]["registered_from"]["data"]["id"])

# save with UTF-8 encoding 

df = pandas.DataFrame(data={"title":all_title, "description": all_desc, "id": all_id, "public":all_public, "embargoed":all_emb, "type":all_type, "withdrawn":all_withdrawn, "authors":all_auth, "pre":all_pre})
df.to_csv("preregs.csv", sep = ",", index=False, encoding="utf-8")

