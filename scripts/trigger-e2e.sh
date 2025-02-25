#!/bin/sh
##
# Trigger CI to run e2e test
#

# Collect BE and FE test environment url.
# If it's a PR, programmatically determine the URL based on the autogenerated route rather then relying on $LAGOON_ROUTE.
# The reason is CMDB sometimes set develop LAGOON_ROUTE as a project-level variable.
PR_BRANCH_REGEX="pr-"
if [[ $(expr match "$LAGOON_GIT_SAFE_BRANCH" $PR_BRANCH_REGEX) != 0 ]]; then
  FE_URL=https://app.${LAGOON_GIT_SAFE_BRANCH}.ripple.sdp4.sdp.vic.gov.au
  BRANCH=$LAGOON_PR_HEAD_BRANCH
# else
  # TODO: No need to handle as we only trigger on release branch for now.
  # $LAGOON_ROUTE will return stroybook route, we need to check $LAGOON_ROUTES to find out the APP route.
  # FE_URL=$LAGOON_ROUTE
  # BRANCH=$LAGOON_GIT_BRANCH
fi

# Add basic auth credentials to the url if it's enabled.
if [ $BASIC_AUTH == '1' ]; then
  BE_URL=${CONTENT_API_SERVER/https:\/\//https:\/\/$CONTENT_API_AUTH_USER:$CONTENT_API_AUTH_PASS@}
  FE_URL=${FE_URL/https:\/\//https:\/\/$CONTENT_API_AUTH_USER:$CONTENT_API_AUTH_PASS@}
else
  BE_URL=$CONTENT_API_SERVER
fi

echo "Triggering end to end testing for $LAGOON_PROJECT..."

if [ -z $E2E_CI_TOKEN ]; then
  echo "Error: No E2E CI token found, end to end is not triggered. Please make sure E2E_CI_TOKEN is set up."
else
  # Trigger CircleCI to run the pipeline
  curl --location --request POST "https://circleci.com/api/v2/project/github/dpc-sdp/ripple/pipeline" \
    --header "Circle-Token: $E2E_CI_TOKEN" \
    --header 'content-type: application/json' \
    --data-raw '{
        "branch": "'"$BRANCH"'",
        "parameters": {
            "e2e": true,
            "e2e_be_url": "'"$BE_URL"'",
            "e2e_fe_url": "'"$FE_URL"'",
            "e2e_project": "reference"
        }
    }'
fi
