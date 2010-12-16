require './tweet'

tweet = TweetSave.new
CreateCmds.migrate(:down)
CreateCmds.migrate(:up)
tweet.cmd_new_add
