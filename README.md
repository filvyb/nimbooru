# Nimbooru

A Nim library for searching and retrieving posts from multiple boorus.

## Supported Sites

Gelbooru, Safebooru, Danbooru, Yandere, Konachan, E621, Sankaku, IdolComplex, Zerochan, Rule34Paheal

## Installation

```bash
nimble install nimbooru
```

## Usage

```nim
import nimbooru
import std/options

var client = initBooruClient(Safebooru)

# Search posts
let posts = client.searchPosts(limit = 20)
for post in posts:
  echo post.file_url

# Search with tags
let filtered = client.searchPosts(
  tags = some @["green eyes"],
  exclude_tags = some @["hat"]
)

# Get single post
let post = client.getPost("12345")
```

### Async

```nim
import std/asyncdispatch

let posts = waitFor client.asyncSearchPosts(limit = 50)
let post = waitFor client.asyncGetPost("12345")
```

### Authentication

```nim
var client = initBooruClient(
  Gelbooru,
  apiKey = some "key",
  userId = some "id"
)
```

### Custom URL

```nim
var client = initBooruClient(
  "https://safebooru.donmai.us/",
  Danbooru
)
```

## License

LGPL-3.0-or-later
