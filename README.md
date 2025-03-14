1. Build
docker build --no-cache --platform linux/amd64 -f Dockerfile.16 -t postgres-ssl:16 .

2. (docker login to longlake ghcr with personal access token from github)
```
Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
Create a new token with at least the following permissions:
read:packages
write:packages
delete:packages
```
(this is also set on Railway > postgres > settings)

3. Tag
docker tag postgres-ssl:16 ghcr.io/longlaketech/postgres-ssl:16

4. Push
docker push ghcr.io/longlaketech/postgres-ssl:16
