import jwt, time, requests, sys, json, base64

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
APP_ID = '6772718096'
BUILD_NUMBER = sys.argv[1]

p8 = open('/tmp/asc_key.p8').read()

def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )

def headers():
    return {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}

def api(method, path, **kwargs):
    r = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}',
        headers=headers(), **kwargs)
    return r

if APP_ID == 'PENDING':
    # Try to find app by bundle ID
    r = api('GET', '/apps?filter[bundleId]=com.tokyonasu.eigamachinegun')
    data = r.json()
    if data.get('data'):
        APP_ID = data['data'][0]['id']
        print(f'Found APP_ID: {APP_ID}')
    else:
        print('App not found in ASC. Create it first.')
        sys.exit(0)

print(f'Waiting for build {BUILD_NUMBER} to be processed...')
build_id = None
for i in range(80):
    r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
    data = r.json()
    if data.get('data'):
        build_id = data['data'][0]['id']
        print(f'Build ready: {build_id}')
        break
    print(f'  Waiting... ({i+1}/80)')
    time.sleep(30)

if not build_id:
    print('WARNING: Build not found after 40 minutes. Check ASC manually.')
    sys.exit(0)

# Set export compliance
r = api('PATCH', f'/builds/{build_id}',
    json={'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}})
print(f'Export compliance: {r.status_code}')

# Find version
version_id = None
version_state = None
r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
data = r.json()
if data.get('data'):
    version_id = data['data'][0]['id']
    version_state = data['data'][0]['attributes']['appStoreState']
    print(f'Found version: {version_id} state={version_state}')

if version_state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
    print(f'Already in review ({version_state}). Nothing to do.')
    sys.exit(0)

if not version_id or version_state in ('READY_FOR_DISTRIBUTION',):
    print('Creating new version...')
    r = api('POST', '/appStoreVersions', json={
        'data': {
            'type': 'appStoreVersions',
            'attributes': {'platform': 'IOS', 'versionString': '1.0'},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code not in (200, 201):
        print(f'Failed to create version: {r.text[:300]}')
        sys.exit(1)
    version_id = r.json()['data']['id']
    version_state = 'PREPARE_FOR_SUBMISSION'

print(f'Version ID: {version_id} state={version_state}')

# ---- First-time setup (idempotent) ----

# Set content rights
r = api('PATCH', f'/apps/{APP_ID}', json={'data': {
    'type': 'apps', 'id': APP_ID,
    'attributes': {'contentRightsDeclaration': 'DOES_NOT_USE_THIRD_PARTY_CONTENT'}
}})
print(f'Content rights: {r.status_code}')

# Set copyright
r = api('PATCH', f'/appStoreVersions/{version_id}', json={'data': {
    'type': 'appStoreVersions', 'id': version_id,
    'attributes': {'copyright': '2026 tokyonasu'}
}})
print(f'Copyright: {r.status_code}')

# Set category
r = api('GET', f'/apps/{APP_ID}/appInfos')
info_id = r.json()['data'][0]['id']
r = api('PATCH', f'/appInfos/{info_id}', json={'data': {
    'type': 'appInfos', 'id': info_id,
    'relationships': {'primaryCategory': {'data': {'type': 'appCategories', 'id': 'ENTERTAINMENT'}}}
}})
print(f'Category: {r.status_code}')

# Set age rating
r = api('GET', f'/appInfos/{info_id}/ageRatingDeclaration')
ard_id = r.json()['data']['id']
r = api('PATCH', f'/ageRatingDeclarations/{ard_id}', json={'data': {
    'type': 'ageRatingDeclarations', 'id': ard_id,
    'attributes': {
        'sexualContentGraphicAndNudity': 'NONE',
        'gamblingSimulated': 'NONE',
        'violenceRealisticProlongedGraphicOrSadistic': 'NONE',
        'matureOrSuggestiveThemes': 'NONE',
        'alcoholTobaccoOrDrugUseOrReferences': 'NONE',
        'medicalOrTreatmentInformation': 'NONE',
        'contests': 'NONE',
        'violenceRealistic': 'NONE',
        'gunsOrOtherWeapons': 'NONE',
        'violenceCartoonOrFantasy': 'NONE',
        'sexualContentOrNudity': 'NONE',
        'horrorOrFearThemes': 'NONE',
        'profanityOrCrudeHumor': 'NONE',
        'lootBox': False,
        'unrestrictedWebAccess': False,
        'gambling': False,
        'healthOrWellnessTopics': False,
        'ageAssurance': False,
        'messagingAndChat': False,
        'parentalControls': False,
        'advertising': True,
        'userGeneratedContent': False,
    }
}})
print(f'Age rating: {r.status_code}')

# Set privacy policy URL
r = api('GET', f'/appInfos/{info_id}/appInfoLocalizations?limit=10')
for il in r.json().get('data', []):
    r2 = api('PATCH', f'/appInfoLocalizations/{il["id"]}', json={'data': {
        'type': 'appInfoLocalizations', 'id': il['id'],
        'attributes': {'privacyPolicyUrl': 'https://snarfnet.github.io/EigaMachineGun/privacy'}
    }})
    print(f'Privacy URL ({il["attributes"]["locale"]}): {r2.status_code}')

# Set version localizations
r = api('GET', f'/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=10')
for loc in r.json().get('data', []):
    locale = loc['attributes']['locale']
    if locale.startswith('ja'):
        desc = "映画を次々と自動で紹介するアプリ。スピードトリガーで速度を自由に調整。アクション、ホラー、SF、コメディなどジャンル別フィルターで好みの映画を発見。気になった映画はタップで詳細やプレビューを確認。"
        keywords = "映画,ムービー,映画紹介,映画発見,映画おすすめ,映画情報,映画レビュー,映画ランキング,映画検索,マシンガン"
    else:
        desc = "Discover movies at machine gun speed. Auto-scrolling movie showcase with adjustable speed trigger. Filter by genre - Action, Horror, Sci-Fi, Comedy and more. Tap any movie for details, trailers, and iTunes Store links."
        keywords = "movie,movies,film,cinema,discover,recommendation,trailer,genre,action,horror"

    r2 = api('PATCH', f'/appStoreVersionLocalizations/{loc["id"]}', json={'data': {
        'type': 'appStoreVersionLocalizations', 'id': loc['id'],
        'attributes': {
            'description': desc,
            'keywords': keywords,
            'supportUrl': 'https://snarfnet.github.io/',
            'marketingUrl': 'https://snarfnet.github.io/'
        }
    }})
    print(f'Localization ({locale}): {r2.status_code}')

# Set review detail
r = api('POST', '/appStoreReviewDetails', json={'data': {
    'type': 'appStoreReviewDetails',
    'attributes': {
        'contactFirstName': 'Tokyo', 'contactLastName': 'Nasu',
        'contactEmail': 'snarfnet@gmail.com',
        'contactPhone': '+14155550000',
        'demoAccountRequired': False,
        'demoAccountName': '', 'demoAccountPassword': '',
        'notes': 'This app uses iTunes Search API to display movie information. Speed slider controls auto-advance interval.'
    },
    'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}}
}})
print(f'Review detail: {r.status_code}')

# Set pricing (free)
pp_data = {'s': APP_ID, 't': 'USA', 'p': '10000'}
pp_id = base64.b64encode(json.dumps(pp_data, separators=(',', ':')).encode()).decode().rstrip('=')
r = api('POST', '/appPriceSchedules', json={
    'data': {
        'type': 'appPriceSchedules',
        'relationships': {
            'app': {'data': {'type': 'apps', 'id': APP_ID}},
            'baseTerritory': {'data': {'type': 'territories', 'id': 'USA'}},
            'manualPrices': {'data': [{'type': 'appPrices', 'id': '${usa-free}'}]}
        }
    },
    'included': [{
        'type': 'appPrices',
        'id': '${usa-free}',
        'attributes': {'startDate': None, 'endDate': None},
        'relationships': {
            'territory': {'data': {'type': 'territories', 'id': 'USA'}},
            'appPricePoint': {'data': {'type': 'appPricePoints', 'id': pp_id}}
        }
    }]
})
print(f'Pricing: {r.status_code}')

# ---- Assign build and submit ----

# Assign build
r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
    json={'data': {'type': 'builds', 'id': build_id}})
print(f'Build assigned: {r.status_code}')

# Cancel any blocking reviewSubmissions
canceled_any = False
for state_filter in ['UNRESOLVED_ISSUES', 'READY_FOR_REVIEW']:
    r = api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[state]={state_filter}')
    if r.status_code == 200:
        for sub in r.json().get('data', []):
            sid = sub['id']
            st = sub['attributes']['state']
            cr = api('PATCH', f'/reviewSubmissions/{sid}', json={
                'data': {'type': 'reviewSubmissions', 'id': sid, 'attributes': {'canceled': True}}
            })
            print(f'Cancel {sid} state={st}: {cr.status_code}')
            canceled_any = True

if canceled_any:
    print('Waiting 30s for cancellations to propagate...')
    time.sleep(30)
    r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
    data = r.json()
    if data.get('data'):
        version_id = data['data'][0]['id']
        version_state = data['data'][0]['attributes']['appStoreState']
        print(f'Version after cancel: {version_id} state={version_state}')
    r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
        json={'data': {'type': 'builds', 'id': build_id}})
    print(f'Build re-assigned: {r.status_code}')

# Submit
submission_id = None
for attempt in range(5):
    r = api('POST', '/reviewSubmissions', json={
        'data': {
            'type': 'reviewSubmissions',
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code == 201:
        submission_id = r.json()['data']['id']
        print(f'ReviewSubmission created: {submission_id}')
        break
    print(f'Create reviewSubmission attempt {attempt+1}/5 failed: {r.status_code} {r.text[:200]}')
    if attempt < 4:
        time.sleep(15)

if not submission_id:
    print('Could not create reviewSubmission after 5 attempts.')
    sys.exit(0)

item_added = False
for attempt in range(5):
    r = api('POST', '/reviewSubmissionItems', json={
        'data': {
            'type': 'reviewSubmissionItems',
            'relationships': {
                'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission_id}},
                'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}
            }
        }
    })
    print(f'Add item attempt {attempt+1}/5: {r.status_code}')
    if r.status_code == 201:
        item_added = True
        break
    if attempt < 4:
        time.sleep(15)

if not item_added:
    print(f'Failed to add item: {r.text[:300]}')
    sys.exit(0)

r = api('PATCH', f'/reviewSubmissions/{submission_id}', json={
    'data': {
        'type': 'reviewSubmissions',
        'id': submission_id,
        'attributes': {'submitted': True}
    }
})
if r.status_code == 200:
    state = r.json()['data']['attributes']['state']
    print(f'Submitted! State: {state}')
else:
    print(f'Submit failed: {r.status_code} {r.text[:300]}')
