# Let's Play Cities

This project is a next generation of my android game "Let's Play Cities"
<https://github.com/AlexanderShirokih/letsplaycities2_android>

## Build

The server address is set at build time with `--dart-define`:

| Flag | Default | Meaning |
|---|---|---|
| `LPS_HOST` | `api.qdstudio.ru` | Host of the main server |
| `LPS_PORT` | `443` | Port of the REST API and the game WebSocket |
| `LPS_SECURE` | `true` | `https`/`wss` instead of `http`/`ws` |

```sh
flutter run --dart-define=LPS_HOST=lps.example.com
```

Without `LPS_HOST` the app connects to `api.qdstudio.ru`.
