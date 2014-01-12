# mediadb2
mediadb2
view videos

# configure
at `globmodel.rb`,configure directory which contain video file

# install
    bundle install

# start / restart / or passenger

start

    ./start.sh

restart

    ./restart.sh

# cron
    0 */2 *  *   *   nice -n 19 ionice -c 3 /home/path/to/mediadb2/glob_server.sh >> /home/path/to/mediadb2/tmp/log/glob_server.log 2>&1
