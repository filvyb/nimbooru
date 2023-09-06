import std/asyncdispatch
import src/Nimbooru
import std/options

var b = initBooruClient(Gelbooru)
echo waitFor b.asyncGetPost("8967426")
echo waitFor b.asyncGetPosts(limit = 2, tags = some @["open mouth"], exclude_tags = some @["yellow_eyes"])
