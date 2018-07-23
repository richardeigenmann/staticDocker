CMAKE_MINIMUM_REQUIRED( VERSION 3.2 )

PROJECT( hello )
ADD_EXECUTABLE (hello main.cpp)
target_compile_features(hello PUBLIC cxx_std_17)
TARGET_LINK_LIBRARIES( hello -static )