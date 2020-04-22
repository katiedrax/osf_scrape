import requests
import json
import io

# empty list to add all titles from downloaded registrations to

all_titles = []

# get search resutls from first page
print("Downloading first page of results")
url = "https://api.osf.io/v2/registrations/?filter%5Bdate_created%5D%5Bgt%5D=2019-12-31&format=json"
r = requests.get(url)
data = r.json()

# store first page of titles

for i in data["data"]:
    all_titles.append(i["attributes"]["title"])

# "next" elements gives link to next page >
# as long as next isn't empty download the next page's data and store only the titles

while data["links"]["next"] is not None:
    print("Next page found, getting", data["links"]["next"])
    response = requests.get(data["links"]["next"])
    data = response.json()
    # store titles from next page
    for i in data["data"]:
        all_titles.append(i["attributes"]["title"])

## it takes about 15 minutes for this loop to run through all 540 pages of registrations

# save with UTF-8 encoding to avoid error thrown by non-english characters

with io.open('prereg_titles.txt', 'w', encoding = "utf-8") as f:
    for title in all_titles:
        f.write(title)
        f.write("\n")
    f.close()
