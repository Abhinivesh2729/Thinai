/// Copyable code samples for the Server page.
///
/// Every sample is built twice from the same template: once with a masked
/// key for the screen and once with the real token for the clipboard, so a
/// screenshot of the page never leaks a working token.
library;

/// Clients that insist on an API key get this on loopback, where none is
/// checked.
const kLoopbackKey = 'thinai';

typedef KeyedText = String Function(String key);

class QuickStartSample {
  const QuickStartSample({
    required this.label,
    required this.filename,
    required this.language,
    required this.build,
  });

  final String label;
  final String filename;
  final String language;
  final KeyedText build;
}

/// Samples for the Connect card. [auth] is true when the server checks a
/// bearer token (LAN sharing on).
List<QuickStartSample> quickStartSamples({
  required String base,
  required String model,
  required bool auth,
}) {
  final v1 = '$base/v1';
  return [
    QuickStartSample(
      label: 'cURL',
      filename: 'request.sh',
      language: 'bash',
      build: (key) =>
          'curl $v1/chat/completions \\\n'
          '  -H "Content-Type: application/json" \\\n'
          '${auth ? '  -H "Authorization: Bearer $key" \\\n' : ''}'
          '  -d \'{\n'
          '    "model": "$model",\n'
          '    "messages": [{"role": "user", "content": "Hello from my PC!"}],\n'
          '    "stream": false\n'
          '  }\'',
    ),
    QuickStartSample(
      label: 'Python',
      filename: 'client.py',
      language: 'python',
      build: (key) =>
          'from openai import OpenAI\n'
          '\n'
          'client = OpenAI(\n'
          '    base_url="$v1",\n'
          '    api_key="$key",\n'
          ')\n'
          '\n'
          'response = client.chat.completions.create(\n'
          '    model="$model",\n'
          '    messages=[{"role": "user", "content": "Hello from my PC!"}],\n'
          ')\n'
          'print(response.choices[0].message.content)',
    ),
    QuickStartSample(
      label: 'JavaScript',
      filename: 'client.mjs',
      language: 'javascript',
      build: (key) =>
          'import OpenAI from "openai";\n'
          '\n'
          'const client = new OpenAI({\n'
          '  baseURL: "$v1",\n'
          '  apiKey: "$key",\n'
          '});\n'
          '\n'
          'const response = await client.chat.completions.create({\n'
          '  model: "$model",\n'
          '  messages: [{ role: "user", content: "Hello from my PC!" }],\n'
          '});\n'
          'console.log(response.choices[0].message.content);',
    ),
    QuickStartSample(
      label: 'VS Code Continue',
      filename: '~/.continue/config.yaml',
      language: 'yaml',
      build: (key) =>
          'models:\n'
          '  - name: Thinai\n'
          '    provider: openai\n'
          '    model: $model\n'
          '    apiBase: $v1\n'
          '    apiKey: $key\n'
          '    roles:\n'
          '      - chat\n'
          '      - edit',
    ),
    QuickStartSample(
      label: 'Ollama',
      filename: 'terminal',
      language: 'bash',
      // OLLAMA_HOST alone sends no Authorization header, so with LAN sharing
      // on only a client that can add one works.
      build: (key) => auth
          ? '# LAN sharing is on, so every request needs the token.\n'
                '# The ollama CLI cannot send it; ollama-python can:\n'
                '#   Client(host="$base",\n'
                '#          headers={"Authorization": "Bearer $key"})\n'
                'export OLLAMA_HOST=$base'
          : '# PowerShell: \$env:OLLAMA_HOST="$base"\n'
                'export OLLAMA_HOST=$base\n'
                'ollama list',
    ),
  ];
}

class EndpointSample {
  const EndpointSample({
    required this.method,
    required this.path,
    required this.curl,
    this.request,
    required this.response,
  });

  final String method;
  final String path;
  final KeyedText curl;
  final String? request;
  final String response;
}

/// The four endpoints most clients use, with full request/response samples.
List<EndpointSample> endpointSamples({
  required String base,
  required String model,
  required bool auth,
}) {
  String authLine(String key) =>
      auth ? '  -H "Authorization: Bearer $key" \\\n' : '';
  KeyedText post(String path, String body) =>
      (key) =>
          'curl $base$path \\\n'
          '  -H "Content-Type: application/json" \\\n'
          '${authLine(key)}'
          '  -d \'$body\'';

  return [
    EndpointSample(
      method: 'POST',
      path: '/v1/chat/completions',
      curl: post(
        '/v1/chat/completions',
        '{\n'
            '    "model": "$model",\n'
            '    "messages": [{"role": "user", "content": "Hello!"}],\n'
            '    "stream": false\n'
            '  }',
      ),
      request:
          '{\n'
          '  "model": "$model",\n'
          '  "messages": [\n'
          '    {"role": "system", "content": "You are a helpful assistant."},\n'
          '    {"role": "user", "content": "Hello!"}\n'
          '  ],\n'
          '  "temperature": 0.7,\n'
          '  "stream": false\n'
          '}',
      response:
          '{\n'
          '  "id": "chatcmpl-thinai",\n'
          '  "object": "chat.completion",\n'
          '  "created": 1728400000,\n'
          '  "model": "$model",\n'
          '  "choices": [\n'
          '    {\n'
          '      "index": 0,\n'
          '      "message": {\n'
          '        "role": "assistant",\n'
          '        "content": "Hello! How can I assist you today?"\n'
          '      },\n'
          '      "finish_reason": "stop"\n'
          '    }\n'
          '  ],\n'
          '  "usage": {\n'
          '    "prompt_tokens": 12,\n'
          '    "completion_tokens": 9,\n'
          '    "total_tokens": 21\n'
          '  }\n'
          '}',
    ),
    EndpointSample(
      method: 'POST',
      path: '/api/chat',
      curl: post(
        '/api/chat',
        '{\n'
            '    "model": "$model",\n'
            '    "messages": [{"role": "user", "content": "Why is the sky blue?"}],\n'
            '    "stream": false\n'
            '  }',
      ),
      request:
          '{\n'
          '  "model": "$model",\n'
          '  "messages": [\n'
          '    {"role": "user", "content": "Why is the sky blue?"}\n'
          '  ],\n'
          '  "stream": false\n'
          '}',
      response:
          '{\n'
          '  "model": "$model",\n'
          '  "created_at": "2026-10-08T17:30:00Z",\n'
          '  "message": {\n'
          '    "role": "assistant",\n'
          '    "content": "The sky is blue due to Rayleigh scattering."\n'
          '  },\n'
          '  "done": true,\n'
          '  "total_duration": 482000000,\n'
          '  "eval_count": 28\n'
          '}',
    ),
    EndpointSample(
      method: 'POST',
      path: '/v1/embeddings',
      curl: post(
        '/v1/embeddings',
        '{\n'
            '    "model": "$model",\n'
            '    "input": "Search query text"\n'
            '  }',
      ),
      request:
          '{\n'
          '  "model": "$model",\n'
          '  "input": "Search query text"\n'
          '}',
      response:
          '{\n'
          '  "object": "list",\n'
          '  "data": [\n'
          '    {\n'
          '      "object": "embedding",\n'
          '      "index": 0,\n'
          '      "embedding": [0.01248, -0.04582, 0.08912, -0.01734]\n'
          '    }\n'
          '  ],\n'
          '  "model": "$model",\n'
          '  "usage": {\n'
          '    "prompt_tokens": 4,\n'
          '    "total_tokens": 4\n'
          '  }\n'
          '}',
    ),
    EndpointSample(
      method: 'GET',
      path: '/v1/models',
      curl: (key) => auth
          ? 'curl $base/v1/models \\\n'
                '  -H "Authorization: Bearer $key"'
          : 'curl $base/v1/models',
      response:
          '{\n'
          '  "object": "list",\n'
          '  "data": [\n'
          '    {\n'
          '      "id": "$model",\n'
          '      "object": "model",\n'
          '      "created": 1728400000,\n'
          '      "owned_by": "local"\n'
          '    }\n'
          '  ]\n'
          '}',
    ),
  ];
}
