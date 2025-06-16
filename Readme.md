# A Docker container with nothing but a statically linked C++ executable

## An experiment by Richard Eigenmann

Inspired by a talk from Miroszlav Magyarevity at the 17th Docker Switzerland Meetup hosted by Oracle in the Prime Tower in Z&uuml;rich on 30 May 2018.

## Try it

```bash
cd <yourWorkDirectory>
git clone git@github.com:richardeigenmann/staticDocker.git
cd staticDocker
docker build --rm=false -t richardeigenmann/hello .
docker run richardeigenmann/hello
```

## How big is it?

```bash
# query the built image:
docker images richardeigenmann/hello
```

```bash
REPOSITORY               TAG       IMAGE ID       CREATED             SIZE
richardeigenmann/hello   latest    94d0d669a22e   About a minute ago  13.2MB
richardeigenmann/hello   latest    af77bf038e7a   3 seconds ago       3.23MB
```

The first result was from statically linking `<iostream>` and calling std::cout on a "Hello World" string. 13MB does seem rather a lot but a Google search reveals that this drags a lot of code in. If we switch to `<cstdio>` and use printf instead, size drops to 3MB. This actually corresponds to the size of the executable as evidenced by the `ls -lh` command I planted in the compile step.

## Explanation

Setting up a development environment for C++ involves intalling a lot of tools and libraries which can lead to problems. A great feature of containers is that you can push this set-up into a container and use different containers for different requirements.

In this project (see the `Dockerfile`) I have chosen to build a heavyweight 829MB compiling container out of OpenSuse's Tumbleweed distro. This drags in the latest clang and gcc compilers and a number of utilities. If required I would also install libraries here.

The build step then proceeds to copy the `CMakeLists.txt` and `main.cpp` files into the compiling conatiner and uses cmake to compile and link the executable.

Using the multi-stage build feature the Dockerfile then specifies that a new container is to be build based on the `SCRATCH` image which literally is just an empty container. The `COPY --from=0 /src/build/hello .` statement then copies the executable into the new container and the `ENTRYPOINT` instruction ensures that it will be called when the container is run.

The `TARGET_LINK_LIBRARIES( hello -static )` entry in the `CMakeLists.txt` (or more specifically the `-static` keyword) instructs the linker to create a statically linked executable (meaning that there are no external dependencies and the binary has everythzing is needs built in).
