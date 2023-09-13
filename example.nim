import std/asyncdispatch
import src/nimbooru
import std/options

var b = initBooruClient(E621)
#echo waitFor b.asyncGetPost("8967426")
#echo waitFor b.asyncGetPost("4508744")
#echo waitFor b.asyncGetPost("6666259")
#echo waitFor b.asyncGetPost("1119641")
#echo waitFor b.asyncGetPost("362603")
echo waitFor b.asyncGetPost("4290112")
echo waitFor b.asyncSearchPosts(limit = 2, tags = some @["open mouth"])
#echo waitFor b.asyncSearchPosts()
#echo waitFor b.asyncSearchPosts(limit = 2, tags = some @["open mouth"], exclude_tags = some @["yellow_eyes"])
