# Reverse proxy (using Traefik)

Automatic domains for accessing the dev server inside agent containers.

When creating an agent container with pi.ps1 script, the name of the folder is used as subdomain for localhost.
For example the **svelte-cannon** project becomes http://**svelte-cannon**.localhost

## Usage

The domain routes to port **5173**, inside the agent container run:

```sh
vite dev --host
```

or

```sh
next dev --port 5173
```
