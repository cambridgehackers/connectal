#
# don't let tasks run for > 3 min
# (but it means _all_ executions will take 3 min!)
$* &
sleep 180
kill $! 
