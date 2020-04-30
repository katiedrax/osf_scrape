import json
import pandas
import glob

for filename in glob.glob('*.json'):
with open(os.path.join(os.cwd(), filename), 'r') as f: