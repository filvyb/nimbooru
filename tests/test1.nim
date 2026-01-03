import unittest
import std/asyncdispatch
import std/options
import std/os

import Nimbooru

# Helper to validate common BooruImage fields are populated
proc validateImage(img: BooruImage) =
  check img.id != ""
  check img.file_url != "" or img.preview_url != ""  # Some posts may lack file_url
  check img.height > 0
  check img.width > 0
  check img.rating != ""
  check img.tags.len > 0

# Note: Gelbooru requires API key authentication.
# To test Gelbooru, set GELBOORU_API_KEY and GELBOORU_USER_ID env vars.
suite "Gelbooru":
  var apiKey = ""
  var userId = ""

  # Check for API credentials
  try:
    apiKey = getEnv("GELBOORU_API_KEY")
    userId = getEnv("GELBOORU_USER_ID")
  except:
    discard

  test "searchPosts returns posts":
    if apiKey == "":
      skip()
    else:
      let client = initBooruClient(Gelbooru, apiKey = some apiKey, userId = some userId)
      let posts = client.searchPosts(limit = 10)
      check posts.len == 10

  test "searchPosts with pagination":
    if apiKey == "":
      skip()
    else:
      let client = initBooruClient(Gelbooru, apiKey = some apiKey, userId = some userId)
      let page0 = client.searchPosts(limit = 5, page = 0)
      let page1 = client.searchPosts(limit = 5, page = 1)
      check page0.len == 5
      check page1.len == 5
      check page0[0].id != page1[0].id

  test "getPost returns valid image":
    if apiKey == "":
      skip()
    else:
      let client = initBooruClient(Gelbooru, apiKey = some apiKey, userId = some userId)
      let posts = client.searchPosts(limit = 1)
      let post = client.getPost(posts[0].id)
      validateImage(post)
      check post.id == posts[0].id

  test "asyncSearchPosts returns posts":
    if apiKey == "":
      skip()
    else:
      let client = initBooruClient(Gelbooru, apiKey = some apiKey, userId = some userId)
      let posts = waitFor client.asyncSearchPosts(limit = 10)
      check posts.len == 10

suite "Safebooru":
  var client = initBooruClient(Safebooru)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 0)
    let page1 = client.searchPosts(limit = 5, page = 1)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    validateImage(post)

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "Danbooru":
  var client = initBooruClient(Danbooru)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 1)
    let page1 = client.searchPosts(limit = 5, page = 2)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    check post.id == posts[0].id
    check post.rating != ""
    check post.tags.len > 0

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "Yandere":
  var client = initBooruClient(Yandere)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 1)
    let page1 = client.searchPosts(limit = 5, page = 2)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    validateImage(post)

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "Konachan":
  var client = initBooruClient(Konachan)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 1)
    let page1 = client.searchPosts(limit = 5, page = 2)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    validateImage(post)

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "E621":
  var client = initBooruClient(E621)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 1)
    let page1 = client.searchPosts(limit = 5, page = 2)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "searchPosts with tags":
    let posts = client.searchPosts(limit = 5, tags = some @["canine"])
    check posts.len > 0

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    check post.id == posts[0].id
    check post.tags.len > 0

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "Sankaku":
  var client = initBooruClient(Sankaku)

  test "searchPosts returns posts":
    let posts = client.searchPosts(limit = 10)
    check posts.len == 10

  test "searchPosts with pagination":
    let page0 = client.searchPosts(limit = 5, page = 1)
    let page1 = client.searchPosts(limit = 5, page = 2)
    check page0.len == 5
    check page1.len == 5
    check page0[0].id != page1[0].id

  test "getPost returns valid image":
    let posts = client.searchPosts(limit = 1)
    let post = client.getPost(posts[0].id)
    check post.id == posts[0].id
    check post.tags.len > 0

  test "asyncSearchPosts returns posts":
    let posts = waitFor client.asyncSearchPosts(limit = 10)
    check posts.len == 10

suite "Error handling":
  test "missing site raises error":
    var client: BooruClient
    expect BooruError:
      discard client.searchPosts()

  test "invalid post ID raises BooruNotFoundError":
    let client = initBooruClient(Safebooru)
    expect BooruNotFoundError:
      discard client.getPost("999999999999")
