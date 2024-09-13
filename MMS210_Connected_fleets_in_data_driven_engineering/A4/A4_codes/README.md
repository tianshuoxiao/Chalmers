# MMS210: Template for the data replay assignment

This template folder contains everything you need to compile and run a C++ software component that connects to a data replay stream to collect video data and speed data of a car, and then use OpenCV for image processing. You don't need to worry too much about what OpenCV is. For the purpose of this assignment we only use it for simple image processing operations. The main purpose here is to get a feeling for how data replay can be used in data-driven engineering.

We are using Docker for two things in this example. First, we will start a special Docker image that mimics a REST interface towards the server and replays it into the local machine. Technically, it uncompresses h264 video and makes it available in shared memory, and sends out other data (speed in this example) on the local network interface. Secondly, we build and run a separate Docker image that contains our own algorithm utilizing the data. Algorithms that should use the data needs to connect to the shared memory to access video frames, and listen to network traffic (UDP multicast in this case) to read the other data. To get the data like this is a good thing, as we know that data is (in this example) distributed exactly the same way in the actual real car. This means that if we later would like to have our own software to run in the car we can simply move it there and not worry about the data interfaces.

## Starting the data replay

* Step 1: Enable Docker to show GUI windows. The GUI is not really needed here (in the replay step), but we have included it to make it easier to see what is going on. This is only needed once per login.
```bash
xhost +
```

* Step 2: Start the data replay. You first needs to login to the docker registry using `docker login registry.git.chalmers.se`. A GUI window should appear. Note: In OpenDLV Desktop this window is rendered as black, but that does not matter, simply continue.
```bash
docker run -ti --rm --init --net=host --ipc=host -v /tmp:/tmp -e DISPLAY=$DISPLAY registry.git.chalmers.se/ola.benderius/mms210-assignment-datareplay:rest_handler
```

Note that the replay will end after a while, and any connected algorithm will stop. Simply rerun step 2 to get the data to play again. In the real car, the data would of course continue as long as the car is turned on.

## Using the data in a test program

* Step 1: Open another terminal. Then, assuming that you are located in the same folder as this README.md file, you can build the software module as follows:
```bash
docker build -t myapp .
```

* Step 2: Now, you can run your software component:
```bash
docker run --rm -ti --init --net=host --ipc=host -v /tmp:/tmp -e DISPLAY=$DISPLAY myapp
```

The application should start and wait for images to come in. Furthermore, the code also display the speed of the car. The code example show how these messages can be parsed.

You can stop your software component by pressing `Ctrl-C`. When you are modifying the software component, repeat step 1 and step 2 after any change to your software.

## Tips and tricks

After a while, you might have collected a lot of unused Docker images on your machine. You can remove them by running:
```bash
docker rmi -f $(docker images -q)
```
This will remove all docker images on your machine, but usually they can simply be rebuilt or re-downloaded.
