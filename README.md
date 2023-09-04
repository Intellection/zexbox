# Zexbox

[![Hex.pm](https://img.shields.io/hexpm/v/zexbox.svg)](https://hex.pm/packages/zexbox)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/Intellection/zexbox/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/Intellection/zexbox/tree/master)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/zexbox/api-reference.html)

## Installation

The package is [available in Hex](https://hex.pm/docs/publish) and can be installed
by adding `zexbox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zexbox, "~> 0.4.0"}
  ]
end
```

## Docker Compose

- Run

```
docker compose up
```

- For grafana browse to `http://localhost:3000/`
- use `http://influxdb:8086` as a data source

## Copyright and License

Copyright (c) 2023, Zappistore.

Zexbox source code is licensed under the [MIT License](LICENSE.md).
