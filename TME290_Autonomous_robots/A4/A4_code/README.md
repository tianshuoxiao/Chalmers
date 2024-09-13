# A lawn mower control software

Use together with the grass simulator to cut grass.

First start the grass simulator in one terminal, and then start the lawn mower
in anohter. The two programs will start communicating, where the lawn mower
sends a control action, and the grass simulator responds with sensor values.

Combile this software according to:

    docker build -f tme290-lawnmower .

And run with :

    docker run -ti --rm --net=host tme290-lawnmower tme290-lawnmower --cid=111 --verbose

## Native build

To speed up development, you may consider to build natively (without Docker):

    mkdir b
    cd b
    cmake ..
    make

And then run with:

    ./tme290-lawnmower --cid=111 --verbose
