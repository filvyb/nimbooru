import std/asyncdispatch
import src/nimbooru
import std/options

var b = initBooruClient(Danbooru)
#echo waitFor b.asyncGetPost("8967426")
#echo waitFor b.asyncGetPost("4508744")
echo waitFor b.asyncGetPost("6666259")
echo waitFor b.asyncSearchPosts(limit = 2, tags = some @["open mouth"], exclude_tags = some @["yellow_eyes"])
