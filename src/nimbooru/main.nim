import std/options
import std/asyncdispatch
import std/json

import utils
import funcs
import containers

proc initBooruClient*(site: Boorus, apiKey = none string, userId = none string): BooruClient =
  ## Initialize BooruClient to use one of the supported boorus
  result.apiKey = apiKey
  result.userId = userId
  result.site = some site

proc initBooruClient*(site_url: string, site: Boorus, apiKey = none string, userId = none string): BooruClient =
  ## Initialize BooruClient to use a custom endpoint, use site argument to pick an API version
  result.apiKey = apiKey
  result.userId = userId
  result.site = some site
  result.customApi = some site_url

proc getPost*(client: BooruClient, id: string): BooruImage = 
  ## Get a single post from a post id
  var base_url = prepareEndpoint(client)
  base_url = prepareGetPost(client, id, base_url)
  var cont = client.syncGetUrl(base_url)
  result = initBooruImage(client, client.processPost(cont))

proc searchPosts*(client: BooruClient, limit = 100, page = 0, tags = none seq[string], exclude_tags = none seq[string]): seq[BooruImage] =
  ## Get a sequence of posts optionally filtered by tags
  var base_url = prepareEndpoint(client)
  base_url = prepareSearchPosts(client, limit, page, tags, exclude_tags, base_url)
  var cont = client.syncGetUrl(base_url)
  result = client.processSearchPosts(cont)

proc asyncGetPost*(client: BooruClient, id: string): Future[BooruImage] {.async.} = 
  ## Get a single post from a post id
  var base_url = prepareEndpoint(client)
  base_url = prepareGetPost(client, id, base_url)
  var cont = await client.asyncGetUrl(base_url)
  result = initBooruImage(client, client.processPost(cont))

proc asyncSearchPosts*(client: BooruClient, limit = 100, page = 0, tags = none seq[string], exclude_tags = none seq[string]): Future[seq[BooruImage]] {.async.} =
  ## Get a sequence of posts optionally filtered by tags
  var base_url = prepareEndpoint(client)
  base_url = prepareSearchPosts(client, limit, page, tags, exclude_tags, base_url)
  var cont = await client.asyncGetUrl(base_url)
  result = client.processSearchPosts(cont)
