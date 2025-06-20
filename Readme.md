# How small can we make a container?

## An experiment by Richard Eigenmann

Inspired by a talk from Miroszlav Magyarevity at the 17th Docker Switzerland Meetup hosted by Oracle in the Prime Tower in Z&uuml;rich on 30 May 2018.

## Introduction

Often containers are huge, several hundred MB of stuff. Makes sense. After all there is perhaps and entire Operating System worth of code in there.

I have found that to build C++ programs I might require a container that consumes a whopping 1.32GB of storage. The one built by the accompanying `Dockerfile` certainly does. It is based on the OpenSuSE Tumbleweed container and adds the Clang and Gcc compiler to it.

In this project I have used the 1.32GB heavyweight container to compile a C++ hello world program into a static binary. After the compile step I build a second container using the `FROM scratch` container which is a special Docker base container with nothing in it and add the staticlly linked binary.

If I stay with C++ the hello world program compiles down to 13MB and the scratch container with this program remains at the same size. If I swap out C++'s `cout` to C's `printf` I can get the size down to 3MB.

## What this is good for

If we want to deploy a program in a Docker container with nothing but a statically linked executable we can use this multibuild `FROM scratch` approach. Go programs typically compile down to single staticly linked executables as you can with many other languages.

## What this is not good for

The container has no `ldd` or `libc` libraries. So the program has no way to load other modules. So if your project is not entirely static you will probably have to look for a different container.

## Check it out

Run these steps on your Linux machine. They will clone this repo and ask Docker to follow the steps in the `Dockerfile`.

The Dockerfile tells Docker to download the latest OpenSuSE Tumbleweed container and add the Clang and Gcc compilers to it. It then asks CMake to compile the main.cpp program to a static executable. The executable is then added to a new `FROM scratch` container. The last command executes the output container to prove that it prints 'Hello World'

```bash
cd <yourWorkDirectory>
git clone git@github.com:richardeigenmann/staticDocker.git
cd staticDocker
docker build --rm=false -t richardeigenmann/hello .
docker run richardeigenmann/hello
```

## How big is the container?

Use this command to check the size of the resulting container:

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

In this project (see the `Dockerfile`) I have chosen to build a heavyweight 1.32GB compiling container out of OpenSuSE's Tumbleweed distro. This drags in the latest clang and gcc compilers and a number of utilities. If required I would also install libraries here.

The build step then proceeds to copy the `CMakeLists.txt` and `main.cpp` files into the compiling conatiner and uses cmake to compile and link the executable.

Using the multi-stage build feature the Dockerfile then specifies that a new container is to be build based on the `SCRATCH` image which literally is just an empty container. The `COPY --from=0 /src/build/hello .` statement then copies the executable into the new container and the `ENTRYPOINT` instruction ensures that it will be called when the container is run.

The `TARGET_LINK_LIBRARIES( hello -static )` entry in the `CMakeLists.txt` (or more specifically the `-static` keyword) instructs the linker to create a statically linked executable (meaning that there are no external dependencies and the binary has everythzing is needs built in).
