# ChartMuseum Auth Server Example

Example server providing JWT tokens for [ChartMuseum](https://github.com/helm/chartmuseum) auth.


## Running the example

### Source Code

Check out the source code for the auth server [here](authserver/main.go).

This makes use of the [chartmuseum/auth](https://github.com/chartmuseum/auth) Go library in order to generate valid JWT tokens.

### Getting started

System requirements to run example:

- [docker-compose](https://docs.docker.com/compose/) (version 3)
- [jq](https://stedolan.github.io/jq/)
- curl

In the root of this repo, run the following commands to start both the auth server and ChartMuseum:

```
docker-compose pull  # get the latest images
docker-compose up
```
### Steps

#### Step 1: Making an unauthenticated request to ChartMuseum

ChartMuseum server is configured to use bearer auth.

In order to access protected resources, a JWT token must be supplied in the `Authorization` header that indicates access to perform a specific action against a specific resource.

However, in order to obtain the `scope` required to obtain a token, we first make an unautheticated request.

For example:
```
curl -v http://localhost:8080/org1/repo1/index.yaml
```

The output should contain the following:
```
< HTTP/1.1 401 Unauthorized
< Content-Type: application/json; charset=utf-8
< Www-Authenticate: Bearer realm="http://localhost:5001/oauth/token",service="localhost:5001",scope="artifact-repository:org1/repo1:pull"
```

The result is an expected `401 Unauthorized`.

Look at the contents of the `Www-Authenticate` response header. You will see that `realm` and `scope` fields are defined.

`realm` -> `http://localhost:5001/oauth/token`

`scope` -> `artifact-repository:org1/repo1:pull`

These values will be used in the next step.

#### Step 2: Requesting a token from the auth server

After obtaining the `realm` and `scope`, we make a request to the auth server (`realm`) to obtain a token.

Run the following:

```
REALM="http://localhost:5001/oauth/token"
SCOPE="artifact-repository:org1/repo1:pull"

curl -s -X POST -H "Authorization: Bearer MASTERKEY" \
  "$REALM?grant_type=client_credentials&scope=$SCOPE" | jq .
```

*Note: "MASTERKEY" is a hardcoded token in the auth server which is required to authenticate.*

This should output something like the following:

```
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NDM5OTU3NzAsImlhdCI6MTU0Mzk5NTQ3MCwiYWNjZXNzIjpbeyJ0eXBlIjoiYXJ0aWZhY3QtcmVwb3NpdG9yeSIsIm5hbWUiOiJvcmcxL3JlcG8xIiwiYWN0aW9ucyI6WyJwdWxsIl19XX0.0Ajgwy5Yhl_HwF3yKoggicpxCiFTffiGcWVxhttR_SU3czn2WogkRazXAAQE2CuIzganw5u5WDuZIBPC2RucP8KT5uKvKDiakDsVYHMACCDjpTotAWamZF2MFCTpXzhpCLkcv_dgGHnInGV_VYJj1xhD6B4ksuxMpDflLCNPqV4GyTxdrIplRxurePNLs5yLKngMXs42eAsD44FGDSLbW65RLM7QFZaUvwlbcst0g9KsVxN4NJ4uIPS-dC0HOvdf6bw2E_GTbpTcpzgn5gMXKzKGFxTi8Tch-NA9t6jghsEDUk3WYJGH1Ko0-xI8XpjYf6l4wQ6_Yg2dGrMBxFqfmQ"
}
```

`access_token` is a signed JWT token that indicates access to perform the action `pull` on the `org1/repo1` namespace. It is set to expire in 5 minutes.

You can decode this token on [https://jwt.io](http://jwt.io/#id_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NDM5OTU3NzAsImlhdCI6MTU0Mzk5NTQ3MCwiYWNjZXNzIjpbeyJ0eXBlIjoiYXJ0aWZhY3QtcmVwb3NpdG9yeSIsIm5hbWUiOiJvcmcxL3JlcG8xIiwiYWN0aW9ucyI6WyJwdWxsIl19XX0.0Ajgwy5Yhl_HwF3yKoggicpxCiFTffiGcWVxhttR_SU3czn2WogkRazXAAQE2CuIzganw5u5WDuZIBPC2RucP8KT5uKvKDiakDsVYHMACCDjpTotAWamZF2MFCTpXzhpCLkcv_dgGHnInGV_VYJj1xhD6B4ksuxMpDflLCNPqV4GyTxdrIplRxurePNLs5yLKngMXs42eAsD44FGDSLbW65RLM7QFZaUvwlbcst0g9KsVxN4NJ4uIPS-dC0HOvdf6bw2E_GTbpTcpzgn5gMXKzKGFxTi8Tch-NA9t6jghsEDUk3WYJGH1Ko0-xI8XpjYf6l4wQ6_Yg2dGrMBxFqfmQ) or with something like [jwt-cli](https://github.com/mike-engel/jwt-cli).

If you examine the token payload, it will resemble the following:

```
{
  "exp": 1543995770,
  "iat": 1543995470,
  "access": [
    {
      "type": "artifact-repository",
      "name": "org1/repo1",
      "actions": [
        "pull"
      ]
    }
  ]
}
```

#### Step 3. Making an authenticated request to ChartMuseum

Once you have obtained a token from the auth server, simply retry the original request, this time sending the token in the `Authorization` header:

```
TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NDM5OTU3NzAsImlhdCI6MTU0Mzk5NTQ3MCwiYWNjZXNzIjpbeyJ0eXBlIjoiYXJ0aWZhY3QtcmVwb3NpdG9yeSIsIm5hbWUiOiJvcmcxL3JlcG8xIiwiYWN0aW9ucyI6WyJwdWxsIl19XX0.0Ajgwy5Yhl_HwF3yKoggicpxCiFTffiGcWVxhttR_SU3czn2WogkRazXAAQE2CuIzganw5u5WDuZIBPC2RucP8KT5uKvKDiakDsVYHMACCDjpTotAWamZF2MFCTpXzhpCLkcv_dgGHnInGV_VYJj1xhD6B4ksuxMpDflLCNPqV4GyTxdrIplRxurePNLs5yLKngMXs42eAsD44FGDSLbW65RLM7QFZaUvwlbcst0g9KsVxN4NJ4uIPS-dC0HOvdf6bw2E_GTbpTcpzgn5gMXKzKGFxTi8Tch-NA9t6jghsEDUk3WYJGH1Ko0-xI8XpjYf6l4wQ6_Yg2dGrMBxFqfmQ"

curl -v -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/org1/repo1/index.yaml
```

This should result in a `200 OK` and return the repo index contents as expected:

```
apiVersion: v1
entries:
  mychart:
  - created: "2018-12-05T06:57:46Z"
    digest: 159ba395ef891a90339f5d8a6ff964fb38265ec24a2e1d09fe6c390cda75b17c
    name: mychart
    urls:
    - charts/mychart-0.1.0.tgz
    version: 0.1.0
generated: "2018-12-05T07:04:40Z"
serverInfo: {}
```

## Using with helm-push

There is currently no way to pass this token via Helm CLI.

However, if you are using the [helm-push](https://github.com/chartmuseum/helm-push) plugin, you are able to add your repo with the `cm://` protocol. This, in combination with the `HELM_REPO_ACCESS_TOKEN` environment variable, will allow you to use this token for all repo-related requests:

```
# export necessary vars
export HELM_REPO_USE_HTTP="true"        # needed if repo running over http vs https
export HELM_REPO_ACCESS_TOKEN="$TOKEN"  # token created above

# Add the repo with cm protocol
helm repo add chartmuseum cm://localhost:8080/org1/repo1

# Run repo-related helm commands
helm push mychart/ chartmuseum
helm repo update
helm fetch chartmuseum/mychart
```

The `scope` to use when requesting a token to perform `pull` and `push` actions (see step #2) will look like the following:

```
artifact-repository:org1/repo1:pull,push
```

The suported scope format looks like:

```
artifact-repository:<namespace>:<action[s]>
```

where "repo" is the default, single-tenant `<namespace>`.

## Helm 3

The following diagram shows an example of how repo auth might work between Helm 3 and ChartMuseum 1.0:

<img src="https://github.com/chartmuseum/auth-server-example/raw/master/helm_cli_repo_auth.png">

The specifics behind the `helm login` command which will be introduced in Helm 3 is still to be determined.

*"Auth flow" section in the image above stolen shamelessly from [Docker docs](https://docs.docker.com/registry/spec/auth/token/).*
