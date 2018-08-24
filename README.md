# ChartMuseum Auth Server Example

Example server providing JWT tokens for [ChartMuseum](https://github.com/helm/chartmuseum) auth.

## Background

ChartMuseum repo server currently only allows for HTTP basic authentication. Users would like a more robust authentication system, which allows them to specify which users have access to perform which actions (`helm fetch` vs `helm push`) against which repos. Please see https://github.com/helm/chartmuseum/issues/59 for more info.

The way this will be handled is via JWT tokens, provided by some external authentication service. The tokens must contain a set of claims specific to ChartMusuem, indicating which actions (if any) the authenticated user is allowed to perform. 

The exact format of this set of claims is still being determined. They might look something like the following:

*Single-tenant:*

```
"access": [
    "push"
]
```

*Multi-tenant:*

```
"access": [
    "myorg/myrepo:push",
    "myfriendsorg/myfriendsrepo:pull"
]
```

ChartMuseum server will be configured with a public key that will verify the authenticity of the token provided (which will be sent by HTTP clients in the `Authorization` header). If the token is valid, ChartMuseum will either allow or deny the action based on then token claims.

The "latest" ChartMuseum image has the preliminary ability to be configured with a public key and to verify JWT tokens (thank you @zachpuck). For now, the token is only verified (no inspection of claims). The next steps are to define a Chartmuseum-specific claimset and inspect the claims to determine a given user's access level.

This example stands up an instance of [cesanta/docker_auth](https://github.com/cesanta/docker_auth) configured with a private key, which provides signed tokens that can be used for making requests against a ChartMuseum instance which is configured for bearer auth with the corresponding public key.

## Running the example

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

### Requesting a token

The auth server is currently configured to be wide open. Run the following command to obtain a signed JWT token:

```
export CM_TOKEN="$(curl -sk https://localhost:5001/auth | jq -r '.token')"
```

Examining the token payload:

```
echo $CM_TOKEN | cut -d "." -f 2 | base64 -D | jq
```

### Making HTTP requests

Once you have obtained a token form the auth server, send the token in HTTP headers when making requests to ChartMuseum:

*Requesting the repository index:*

```
curl -v -H "Authorization: Bearer $CM_TOKEN" http://localhost:8080/index.yaml
```

There is currently no way to pass this token via Helm CLI.

However, if you are using the [helm-push](https://github.com/chartmuseum/helm-push) plugin, you are able to add your repo with the `cm://` protocol. This, in combination with the `HELM_REPO_ACCESS_TOKEN` environment variable, will allow you to use this token for all repo-related requests:

```
# export necessary vars
export HELM_REPO_USE_HTTP="true"           # needed if repo running over http vs https
export HELM_REPO_ACCESS_TOKEN="$CM_TOKEN"  # token created above

# Add the repo with cm protocol
helm repo add chartmuseum cm://localhost:8080

# Run repo-related helm commands
helm push mychart/ chartmuseum
helm repo update
helm fetch chartmuseum/mychart
```

## Helm 3

The following diagram shows an example of how repo auth might work between Helm 3 and ChartMuseum 1.0:

<img src="https://github.com/chartmuseum/auth-server-example/raw/master/helm_cli_repo_auth.png">

The specifics behind the `helm login` command which will be introduced in Helm 3 is still to be determined.

*"Auth flow" section in the image above stolen shamelessly from [Docker docs](https://docs.docker.com/registry/spec/auth/token/).*
