cmake_minimum_required(VERSION 3.13)

# import the pico-sdk
set(PICO_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/pico-sdk/)
include(pico_sdk_import.cmake)

# configure the pico-sdk project
project(pico_cram C CXX ASM)
pico_sdk_init()

# add the pico-ice-sdk
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/pico-ice-sdk)

# add the local files
add_executable(${CMAKE_PROJECT_NAME}
    main.c
    )
target_link_libraries(${CMAKE_PROJECT_NAME}
    pico_ice_sdk
    )
target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    )
pico_add_extra_outputs(${CMAKE_PROJECT_NAME})
pico_enable_stdio_usb(${CMAKE_PROJECT_NAME} 0)
pico_enable_stdio_uart(${CMAKE_PROJECT_NAME} 0)


set (FPGA_PROJECT_NAME rgb_blink)
#set (SPEEDGRADE "--speed 6")
set (FOOTPRINT "sg48")
set (PIN_DEF --pcf ${CMAKE_SOURCE_DIR}/pico_ice.pcf)
set (DEVICE "--up5k")
set (FREQ "48")
set (ABCOPTS -abc9)
set (NEXTPNR nextpnr-ice40)
set (PACKBIT icepack)
#set (FPGA_PROJECT_SOURCES blinky.v)
set (FPGA_PROJECT_TOP_SOURCE ${FPGA_PROJECT_NAME}.v)
set (YOSYS_SYNTH synth_ice40)

set (BIN2C bin2c)

add_custom_target(${FPGA_PROJECT_NAME}.json
    DEPENDS ${FPGA_PROJECT_TOP_SOURCE} ${PROJECT_SOURCES}
    COMMAND yosys -p '${YOSYS_SYNTH} ${ABCOPTS} -json ${CMAKE_BINARY_DIR}/${FPGA_PROJECT_NAME}.json -top ${FPGA_PROJECT_NAME}' ${FPGA_PROJECT_TOP_SOURCE}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

target_sources(${FPGA_PROJECT_NAME}.json PRIVATE ${PROJECT_TOP_SOURCE} ${PROJECT_SOURCES} )

add_custom_target(${FPGA_PROJECT_NAME}.asc
    DEPENDS ${FPGA_PROJECT_NAME}.json
    COMMAND ${NEXTPNR} --timing-allow-fail ${SPEEDGRADE} --package ${FOOTPRINT} --json ${FPGA_PROJECT_NAME}.json ${PIN_DEF} ${DEVICE} --asc ${FPGA_PROJECT_NAME}.asc --freq ${FREQ}
)
add_custom_target(${FPGA_PROJECT_NAME}.bin
    DEPENDS ${FPGA_PROJECT_NAME}.asc
    COMMAND ${PACKBIT} ${FPGA_PROJECT_NAME}.asc ${FPGA_PROJECT_NAME}.bin
)

add_custom_target(${FPGA_PROJECT_NAME}.h
    DEPENDS ${FPGA_PROJECT_NAME}.bin
    COMMAND ${BIN2C} -H ${FPGA_PROJECT_NAME}.H ${FPGA_PROJECT_NAME}.bin
    COMMAND cat ${FPGA_PROJECT_NAME}.H |sed "s/bin2c_${FPGA_PROJECT_NAME}_bin/${FPGA_PROJECT_NAME}/g" > ${FPGA_PROJECT_NAME}.h
    )

add_dependencies(${CMAKE_PROJECT_NAME} ${FPGA_PROJECT_NAME}.h)
