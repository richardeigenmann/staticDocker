# Multistage Docker file that builds a C++ 17 compiler and then
# uses it to create a statically linked binary that it adds to a 
# SCRATCH container


# To create the container (and not remove the intermediate containers)
# docker build --rm=false -t richardeigenmann/hello .

# To run the container:
# docker run richardeigenmann/hello


FROM opensuse/tumbleweed

# Adds the repos with latest clang, gcc and stdlibc++
RUN  zypper addrepo -f --no-gpgcheck http://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Factory/devel:tools:compiler.repo  \
  && zypper addrepo -f --no-gpgcheck http://download.opensuse.org/repositories/devel:/libraries:/c_c++/openSUSE_Factory/devel:libraries:c_c++.repo \
  && zypper install --no-confirm \
    git\
    clang19\
    gcc-c++ \
    cmake \
    vim \
    which \
    glibc-devel-static

RUN mkdir /src
COPY CMakeLists.txt /src
COPY main.cpp /src

RUN mkdir -p /src/build \
  && cd /src/build \
#  && cmake -DCMAKE_CXX_COMPILER=/usr/bin/clang++ ..\
  && cmake -DCMAKE_CXX_COMPILER=/usr/bin/g++ ..\
  && cmake --build . -- -j$(($(nproc) + 1)) \
  && ls -lh hello

FROM scratch

# Copy the executable from the compiling container into the run container
COPY --from=0 /src/build/hello .

ENTRYPOINT ["/hello"]
CMD []