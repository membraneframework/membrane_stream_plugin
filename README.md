# Membrane Stream Plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_stream_plugin.svg)](https://hex.pm/packages/membrane_stream_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_stream_plugin)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_stream_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_stream_plugin)

Plugin for recording the entire stream sent through Membrane pads into a binary format and replaying it.
This capability might be useful for creating snapshots of the stream at a given point in the pipeline for usage in tests, or for communication between two parts of the pipeline without using BEAM clusters.

The format used by Membrane Stream Plugin features:
- header with version information, allowing for backwards compatibility
- self delimitation, so buffers sent out of `Membrane.Stream.Serializer` are suitable to be saved to a file or sent over UDP
- Consistency checks in the form of a magic keyword repeated before every term

As of version 1, Membrane Stream Format supports buffers, stream formats and events. Dynamic pads are not supported.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

The package can be installed by adding `membrane_stream_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
	  {:membrane_stream_plugin, "~> 0.3.1"}
  ]
end
```

## Usage

For usage example, please refer to [`examples/split_pipeline.exs`](examples/split_pipeline.exs).
To run it, simply execute:

```bash
$ elixir examples/split_pipeline.exs
```

The example demonstrates a simple pipeline playing the H264 file using SDL Player, split in half using Membrane Stream Plugin capabilities.

## Credits

This plugin has been built thanks to the support from [dscout](https://dscout.com/) and [Software Mansion](https://swmansion.com).

<div style="display: flex; flex-flow: row; gap: 20px">
  <img alt="dscout" height="100" src="./.github/dscout_logo.png"/>
  <img alt="Software Mansion" src="https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=membrane_stream_plugin"/>
</div>

## Copyright and License

Copyright 2022, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_stream_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_stream_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
