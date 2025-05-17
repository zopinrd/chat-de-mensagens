# app_chat

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuração do WebSocket AWS

Adicione ao arquivo `.env` a variável `WS_ENDPOINT` com o endpoint fornecido pelo API Gateway WebSocket:

```
WS_ENDPOINT=wss://SEU-ENDPOINT-WEBSOCKET.amazonaws.com/dev
```

O app utiliza esse endpoint para chat em tempo real.
